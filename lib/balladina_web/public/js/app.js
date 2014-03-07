var CLIENT_ID_PARTS = 10;

function generateClientId() {
  var randomNumbers = new Uint8Array(CLIENT_ID_PARTS);
  var n, randomString = "";

  window.crypto.getRandomValues(randomNumbers);

  for (n = 0; n < randomNumbers.length; n++) {
    randomString += randomNumbers[n];
  }

  return randomString;
}

var clientId      = generateClientId();
var controlSocket = new WebSocket("ws://localhost:7331");
var dataSocket    = new WebSocket("ws://localhost:7331");

controlSocket.onopen = function() {
  var message = { command: "promote_to_control", clientId: clientId };
  controlSocket.send(JSON.stringify(message));
};

dataSocket.onopen = function() {
  var message = { command: "promote_to_data", clientId: clientId };
  dataSocket.send(JSON.stringify(message));
};

controlSocket.onmessage = function() {
  console.debug("=== RECEIVED", arguments);
};
