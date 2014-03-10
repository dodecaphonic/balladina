var CLIENT_ID_PARTS = 10;
var pc, clientId, controlSocket, dataSocket;

var configuration = {
  "iceServers": [
    { "url": "stun:stun.l.google.com:19302" },
    { "url": "stun:stunserver.org"},
    { "url": "stun:stun.sipgate.net" }
  ]
};

function logError(error) {
  console.error("=== FUDGE", error);
}

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
  }
}

function renderPeers(peers) {
  React.renderComponent(
    TrackList({ peers: peers }),
    document.getElementById("controls")
  );
}

function startRTC() {
  pc = new webkitRTCPeerConnection(configuration);

  pc.onicecandidate = function(evt) {
    if (evt.candidate) {
      controlSocket.send(JSON.stringify({
        "candidate": evt.candidate
      }));
    }
  };

  pc.onnegotiationneeded = function() {
    pc.createOffer(localDescCreated, logError);
  };

  pc.onaddstream = function(evt) {
    var remoteView = document.getElementById("remote-view");
    console.log("=== WOOT", remoteView, evt);
    remoteView.src = URL.createObjectURL(evt.stream);
  };

  navigator.webkitGetUserMedia({
    "audio": true,
    "video": true
  }, function(stream) {
    var video = document.getElementById("local-view");
    video.src = URL.createObjectURL(stream);
    video.play();
    pc.addStream(stream);
  }, logError);
}

function processRTCSignal(message) {
  var remoteDescriptionSet = function() {
    console.log("=== HERE I AM");
    if (pc.remoteDescription.type == "offer") {
      pc.createAnswer(localDescCreated, logError);
    }
  };

  if (message.sdp) {
    pc.setRemoteDescription(new RTCSessionDescription(message.sdp),
                            remoteDescriptionSet,
                            logError);
  } else {
    pc.addIceCandidate(new RTCIceCandidate(message.candidate));
  }
}

function localDescCreated(desc) {
  pc.setLocalDescription(desc, function() {
    controlSocket.send(JSON.stringify({
      "sdp": pc.localDescription
    }));
  }, logError);
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
  var message = JSON.parse(event.data);
  console.log("=== PREPROCESSING", message);
  if (message.command) {
    actOn(JSON.parse(event.data));
  } else {
    processRTCSignal(message);
  }
};
