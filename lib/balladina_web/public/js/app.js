var CLIENT_ID_PARTS = 10;

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

var clientId      = generateClientId();
var controlSocket = new WebSocket("ws://localhost:7331");
var dataSocket    = new WebSocket("ws://localhost:7331");

controlSocket.onopen = function() {
  var message = { command: "promote_to_control", data: clientId };
  controlSocket.send(JSON.stringify(message));
};

dataSocket.onopen = function() {
  var message = { command: "promote_to_data", data: clientId };
  dataSocket.send(JSON.stringify(message));
};

controlSocket.onmessage = function(event) {
  actOn(JSON.parse(event.data));
};
