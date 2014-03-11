var CLIENT_ID_PARTS = 6;
var clientId, controlSocket, dataSocket;

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
  var webrtc = new SimpleWebRTC({
    localVideoEl: "local-view",
    remoteVideosEl: "remote-view",
    autoRequestMedia: true
  });

  webrtc.on("readyToCall", function() {
    webrtc.joinRoom("foodafafa");
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
