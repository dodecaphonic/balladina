function drawBlackWhiteFrame(context) {

  var apx = context.getImageData(0, 0, w, h);

  var data = apx.data;

  for (var y = 0; y < h; y ++) {
    for (var x = 0; x < w; x ++) {

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

}
