var localVideo = document.getElementById("local-view");

var superCanvas = document.getElementById("super-canvas-fx");

w = localVideo.width;
h = localVideo.height;

superCanvas.width = w;
superCanvas.height = h;

var context = superCanvas.getContext("2d");

var fxBlackWhiteButton = document.getElementById("fx-black-white-button");

var fxRemoveButton = document.getElementById("fx-remove-button");

var lastFx = 0;

var FILTER_DELAY = 10;//Milliseconds

fxRemoveButton.onclick = function() {
  stopFX();
  window.clearInterval(lastFx);
};

fxBlackWhiteButton.onclick = function() {
  startFX();

  lastFx = window.setInterval(function() {

    if (localVideo.paused || localVideo.ended) {
      return;
    }

    context.drawImage(localVideo, 0, 0, w, h);

    drawBlackWhiteFrame(context); 

  }, FILTER_DELAY);

};

function startFX() {
  localVideo.style.visibility = "hidden";
  superCanvas.style.visibility = "visible";
}

function stopFX() {
  localVideo.style.visibility = "visible";
  superCanvas.style.visibility = "hidden";
}
