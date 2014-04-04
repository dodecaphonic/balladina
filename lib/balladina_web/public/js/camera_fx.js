var localVideo = document.getElementById("local-view");
var superCanvas = document.getElementById("super-canvas-fx");
w = localVideo.width;
h = localVideo.height;
superCanvas.width = w;
superCanvas.height = h;

var context = superCanvas.getContext("2d");

var fxBlackWhite = document.getElementById("fx-black-white-button");

var fxRemove = document.getElementById("fx-remove-button");

var lastFx = 0;

fxRemove.onclick = function() {
  stopFX();
  window.clearInterval(lastFx);
};

fxBlackWhite.onclick = function() {
  startFX();
  lastFx = window.setInterval(function() { drawBlackWhiteFrame(); }, 10);
};

function startFX() {
  localVideo.style.visibility = "hidden";
  superCanvas.style.visibility = "visible";
}

function stopFX() {
  localVideo.style.visibility = "visible";
  superCanvas.style.visibility = "hidden";
}

function drawBlackWhiteFrame() {
 
  context.drawImage(localVideo, 0, 0, w, h);

  var apx = context.getImageData(0, 0, w, h);

  var data = apx.data;

  for (var y = 0; y < h; y ++) {
    for (var x = 0; x < w; x ++) {
      // RGB
      var j = y*w;
      var i = x;
      var pixel = (i+j)*4;

      var r = data[pixel],
          g = data[pixel+1],
          b = data[pixel+2],
          gray = (r+g+b)/3;

      data[pixel] = gray;
      data[pixel+1] = gray;
      data[pixel+2] = gray;
    }
  }

  apx.data = data;

  context.putImageData(apx, 0, 0);
 
  if (localVideo.paused || localVideo.ended) {
    return;
  }

}
