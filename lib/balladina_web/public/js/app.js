var WEBSOCKET_URI   = "ws://" + location.hostname + ":7331";
var CLIENT_ID_PARTS = 6;

function generateClientId() {
  var randomNumbers   = new Uint8Array(CLIENT_ID_PARTS);
  var n, randomString = "";

  window.crypto.getRandomValues(randomNumbers);

  for (n = 0; n < randomNumbers.length; n++) {
    randomString += randomNumbers[n];
  }

  return randomString;
}

var Balladina = {
  models: {},
  views: {},
  collections: {},
  messages: {
    PROMOTE_DATA: { command: "promote_to_data", data: -1 },
    PROMOTE_CONTROL: { command: "promote_to_control", data: -1 },
    START_RECORDING: { command: "start_recording" },
    STOP_RECORDING: { command: "stop_recording" }
  }
};

Balladina.models.Control        = Backbone.Model.extend({});
Balladina.models.Track          = Backbone.Model.extend({});
Balladina.collections.TrackList = Backbone.Collection.extend({
});

Balladina.models.DataChannel = Backbone.Model.extend({
  initialize: function() {
    this.socket = new WebSocket(WEBSOCKET_URI);
    var that    = this;

    this.socket.onopen = function() {
      var message  = _.clone(Balladina.messages.PROMOTE_DATA);
      message.data = that.attributes.clientId;
      that.socket.send(JSON.stringify(message));
      that.set("ready", true);
    };
  },

  send: function(blob) {
    this.socket.send(blob);
  }
});

Balladina.models.Recorder = Backbone.Model.extend({
  initialize: function() {
    this.recorder = this._prepareRecorder();
    this.attributes.control.on("change:recording", this._toggleRecording, this);
  },

  _prepareRecorder: function() {
    var context = new webkitAudioContext();
    var mediaStreamSource = context.createMediaStreamSource(this.attributes.stream);
    return new Recorder(mediaStreamSource, {
      workerPath: "/js/recorderjs/recorderWorker.js"
    });
  },

  _toggleRecording: function(controls, isRecording) {
    if (isRecording) {
      this.start();
    } else {
      this.stop();
    }
  },

  start: function() {
    var recorder = this.recorder,
        socket   = this.attributes.dataChannel;

    recorder.record();
    this.recordingTimer = setInterval(function() {
      recorder.exportWAV(function(blob) {
        recorder.clear();
        socket.send(blob);
      });
    }, 1000);
  },

  stop: function() {
    this.recorder.stop();
    clearTimeout(this.recordingTimer);
  }
});

Balladina.models.SignalingChannel = Backbone.Model.extend({
  initialize: function() {
    this.socket = new WebSocket(WEBSOCKET_URI);
    var that    = this;

    this.socket.onopen = function(event) {
      var message  = _.clone(Balladina.messages.PROMOTE_CONTROL);
      message.data = that.attributes.clientId;
      that.socket.send(JSON.stringify(message));
      that.set("ready", true);
    };

    this.socket.onmessage = function(event) {
      that.actOn(JSON.parse(event.data));
    };

    this.attributes.control.on("change:signalRecording", this._signalRecording, this);
  },

  _updateTracks: function(clientIds) {
    this._removeDisconnectedTracks(clientIds);
    this._addNewTracks(clientIds);
  },

  _removeDisconnectedTracks: function(clientIds) {
    var tracks    = this.attributes.tracks;
    var leftBoard = tracks.filter(function(t) {
      return clientIds.indexOf(t.get("id")) == -1;
    });

    tracks.remove(leftBoard);
  },

  _addNewTracks: function(clientIds) {
    var tracks = this.attributes.tracks;
    var newIds = _.filter(clientIds, function(id) {
      return tracks.findWhere({ id: id }) === undefined;
    });

    var newTracks = _.map(newIds, function(id) {
      return new Balladina.models.Track({ id: id });
    });

    tracks.add(newTracks);
  },

  _signalRecording: function(control, isRecording) {
    var message;
    if (isRecording) {
      message = Balladina.messages.START_RECORDING;
    } else {
      message = Balladina.messages.STOP_RECORDING;
    }

    this.socket.send(JSON.stringify(message));
  },

  _startRecording: function() {
    this.attributes.control.set("recording", true);
    this.attributes.control.set({ signalRecording: true },
                                { silent: true});
  },

  _stopRecording: function() {
    this.attributes.control.set("recording", false);
    this.attributes.control.set({ signalRecording: false },
                                { silent: true});
  },

  actOn: function(message) {
    switch (message.command) {
    case "peers_online":
      this._updateTracks(message.data);
      break;
    case "start_recording":
      this._startRecording();
      break;
    case "stop_recording":
      this._stopRecording();
      break;
    }
  }
});

Balladina.views.Controls = Backbone.View.extend({
  el: "#controls",

  events: {
    "click .toggle-recording": "_signalRecording"
  },

  initialize: function() {
    this.model.on("change:recording", this._toggleRecording, this);
  },

  render: function() {
    var template = _.template($("#controls-template").html());
    this.$el.append(template({}));
    return this;
  },

  _toggleRecording: function(control, isRecording) {
    var uiToggle    = this.$el.find(".toggle-recording");

    if (isRecording) {
      uiToggle.addClass("recording").addClass("pulsate");
    } else {
      uiToggle.removeClass("recording").removeClass("pulsate");
    }
  },

  _signalRecording: function() {
    var isRecording = !this.model.get("signalRecording");
    this.model.set("signalRecording", isRecording);
  }
});

Balladina.views.Track = Backbone.View.extend({
  className: "track",
  template: _.template($("#track-template").html()),

  render: function() {
    this.$el.html(this.template(this.model.toJSON()));

    return this;
  }
});

Balladina.views.Board = Backbone.View.extend({
  el: "#panel",

  initialize: function() {
    this.collection.on("add", this._addTrack, this);
    this.collection.on("remove", this._removeTrack, this);
  },

  _addTrack: function(track) {
    var trackView = new Balladina.views.Track({ model: track });
    this.$el.find("#tracks").append(trackView.render().$el);
  },

  _removeTrack: function(track) {
    this.$el.find(".track[data-id=" + track.get("id") + "]").remove();
  },

  render: function() {
    var that = this;
    this.collection.each(function(track) {
      that._addTrack(track);
    });

    return this;
  }
});

Balladina.views.App = Backbone.View.extend({
  el: "body",

  initialize: function() {
    this.tracks  = new Balladina.collections.TrackList();
    this.control = new Balladina.models.Control();
    this._startChannels();
    this.tracks.add(this.model);
  },

  _startChannels: function() {
    this.signalingChannel = new Balladina.models.SignalingChannel({
      tracks: this.tracks,
      clientId: this.model.id,
      control: this.control
    });

    this.signalingChannel.on("change:ready", this._signalingReady, this);
    this.dataChannel = new Balladina.models.DataChannel({
      clientId: this.model.id
    });
  },

  _signalingReady: function(channel, isReady) {
    if (isReady) {
      this.startRTC();
    }
  },

  startRTC: function() {
    var webrtc = new SimpleWebRTC({
      localVideoEl: "local-view",
      remoteVideosEl: "remote-view",
      autoRequestMedia: true,
      detectSpeakingEvents: false,
      enableDataChannels: false
    });

    var that = this;
    webrtc.on("readyToCall", function() {
      webrtc.joinRoom("foodafafa");
      that.recorder = new Balladina.models.Recorder({
        stream: webrtc.webrtc.localStream,
        dataChannel: that.dataChannel,
        control: that.control
      });
    });
  },

  render: function() {
    var board    = new Balladina.views.Board({
      collection: this.tracks
    });

    var controls = new Balladina.views.Controls({
      model: this.control
    });

    board.render();
    controls.render();

    return this;
  }
});

var me  = new Balladina.models.Track({ id: generateClientId() });
var app = new Balladina.views.App({ model: me });
app.render();
