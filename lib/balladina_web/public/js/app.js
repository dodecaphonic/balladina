var CLIENT_ID_PARTS = 6;
var clientId, controlSocket, dataSocket;
var isRecording = false, recorder, recordingTimer;

function generateClientId() {
  var randomNumbers   = new Uint8Array(CLIENT_ID_PARTS);
  var n, randomString = "";

  window.crypto.getRandomValues(randomNumbers);

  for (n = 0; n < randomNumbers.length; n++) {
    randomString += randomNumbers[n];
  }

  return randomString;
}

function actOn(message) {
  switch (message.command) {
    case "peers_online":
      renderPeers(message.data);
      break;
    case "start_recording":
      startRecording();
      break;
    case "stop_recording":
      stopRecording();
      break;
  }
}

function renderPeers(peers) {
  React.renderComponent(
    TrackList({ peers: peers }),
    document.getElementById("peers")
  );
}

function prepareRecorder(stream) {
  var context = new webkitAudioContext();
  var mediaStreamSource = context.createMediaStreamSource(stream);
  recorder = new Recorder(mediaStreamSource, {
    workerPath: "/js/recorderjs/recorderWorker.js"
  });
}

function startRecording() {
  if (isRecording) stopRecording();

  recorder.record();
  recordingTimer = setInterval(function() {
    recorder.exportWAV(function(blob) {
      recorder.clear();
      dataSocket.send(blob);
    });
  }, 1000);

  isRecording = true;
}

function stopRecording() {
  recorder.stop();
  clearTimeout(recordingTimer);
  isRecording = false;
}

function startRTC() {
  var webrtc = new SimpleWebRTC({
    localVideoEl: "local-view",
    remoteVideosEl: "remote-view",
    autoRequestMedia: true
  });

  webrtc.on("readyToCall", function() {
    webrtc.joinRoom("foodafafa");
    prepareRecorder(webrtc.webrtc.localStream);
  });
}

clientId      = generateClientId();
controlSocket = new WebSocket("ws://localhost:7331");
dataSocket    = new WebSocket("ws://localhost:7331");

controlSocket.onopen = function() {
  var message = { command: "promote_to_control", data: clientId };
  controlSocket.send(JSON.stringify(message));
  startRTC();
};

dataSocket.onopen = function() {
  var message = { command: "promote_to_data", data: clientId };
  dataSocket.send(JSON.stringify(message));
};

controlSocket.onmessage = function(event) {
  actOn(JSON.parse(event.data));
};

$(document).ready(function() {
  $("#start-recording").on("click", function() {
    console.log("START");
    controlSocket.send(JSON.stringify({
      command: "start_recording"
    }));
  });

  $("#stop-recording").on("click", function() {
    console.log("STOP");
    controlSocket.send(JSON.stringify({
      command: "stop_recording"
    }));
  });
});
