// based on Examples/Libraries/video/Capture/FrameDifferencing

import processing.video.*;
Movie myMovie;

int numPixels;
int[] previousFrame;
Capture video;
PImage alphaMask, videoFlip, mascara, videoCont;
float contrast = 1;
int bright = -128;

void setup() {
  size(640, 480);
  frameRate(200);
  String[] cameras = Capture.list();
  //video = new Capture(this, 640, 480, "USB2.0 Camera", 30);
  video = new Capture(this, 640, 480);

  video.start();

  numPixels = video.width * video.height;
  previousFrame = new int[numPixels];
  loadPixels();

  alphaMask = createImage(640, 480, RGB);
  myMovie = new Movie(this, "closes.mov");
  myMovie.loop();
  videoFlip = new PImage(video.width, video.height);
  videoCont = new PImage(video.width, video.height);
  mascara = loadImage("mascara.png");
  image(mascara, 0, 0);
}

void movieEvent(Movie myMovie) {
  myMovie.read();
}

void draw() {
  if (video.available()) {
    video.read();
    video.loadPixels(); // Make its pixels[] array available
    int movementSum = 0; // Amount of movement in the frame
    for (int x = 0; x < video.width; x++) {
      for (int y = 0; y < video.height; y++) {
        videoFlip.pixels[y*video.width+x] = video.pixels[y*video.width+(video.width-(x+1))];
//  to flip back the webcam image, comment the line above and uncomment below:
        //videoFlip.pixels[y*video.width+x] = video.pixels[y*video.width+x];
      }
    }

    for (int loc = 0; loc < width*height; loc++) {
      color currColor = videoFlip.pixels[loc];
      color prevColor = previousFrame[loc];

      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;

      int prevR = (prevColor >> 16) & 0xFF;
      int prevG = (prevColor >> 8) & 0xFF;
      int prevB = prevColor & 0xFF;
// Compute the difference of the red, green, and blue values
// summes and divide the colors to result black and white
// look at the FrameDifferencing example if you want it in colors
      int diffR = abs((currR+currG+currB) - (prevR+prevG+prevB));
      int diffG = abs((currR+currG+currB) - (prevR+prevG+prevB));
      int diffB = abs((currR+currG+currB) - (prevR+prevG+prevB));
      // mantain the values of the colors between 0 and 255
      diffR = diffR < 0 ? 0 : diffR > 255 ? 255 : diffR;
      diffG = diffG < 0 ? 0 : diffG > 255 ? 255 : diffG;
      diffB = diffB < 0 ? 0 : diffB > 255 ? 255 : diffB;

// Compute the brightness of difference to use as alpha mask
      color diff = color(diffR, diffG, diffB);//color of the difference
      int difBri = int(brightness(diff));//brightnes of the different color
      videoFlip.pixels[loc] = difBri; // makes the brightness usefull for the mask
// Add these differences to the running tally
      movementSum += diffR + diffG + diffB;
// Render the difference image to the screen
      pixels[loc] = 0xff000000 | (diffR << 16) | (diffG << 8) | diffB;

      previousFrame[loc] = lerpColor (previousFrame[loc], currColor, 0.1);
    }

//  only works with the funcion 'blend' which gives me strange results
    //ContrastAndBrightness(videoFlip, videoFlip, contrast, bright);

// this number must be adjusted according to 
// your specific light condition and webcam
// if you don't want the fadeout, just make it smaller taking of a zero
    if (movementSum > 15000000) {
      contrast = movementSum/20000000;
      bright = (movementSum/1000000)*10-256;
// below the strange but interesting line I'm intrigued about
      //myMovie.blend(videoFlip, 0, 0, width-1, height-1, 0, 0, width-1, height-1, ADD);

// C:/Program%20Files/processing-2.2.1/modes/java/reference/blendMode_.html
// for others kinds of blending that you can try here:
      blendMode(MULTIPLY);

      updatePixels();
      videoFlip.updatePixels();
// smaller numbers you will see here may suit well in the 'if...' above
      println(movementSum);
      //println(int(frameRate));
      //println(bright);
      //println(contrast);

//  comment the line above to take off the black mask at the borders
      image(mascara, 0, 0);
      myMovie.mask(videoFlip);
    }

// if you want to see only the webcam image, comment the line above
    image(myMovie, 0, 0);
  }
}

void ContrastAndBrightness(PImage input, PImage output, float cont, float bright)
{
  int w = input.width;
  int h = input.height;
  for (int i = 0; i < w*h; i++)
  {
    color inColor = input.pixels[i];
    int r = (inColor >> 16) & 0xFF;
    int g = (inColor >> 8) & 0xFF;
    int b = inColor & 0xFF;
    r = (int)(r * cont + bright);
    g = (int)(g * cont + bright);
    b = (int)(b * cont + bright);
    r = r < 0 ? 0 : r > 255 ? 255 : r;
    g = g < 0 ? 0 : g > 255 ? 255 : g;
    b = b < 0 ? 0 : b > 255 ? 255 : b;
    output.pixels[i]= 0xff000000 | (r << 16) | (g << 8) | b;
  }
}
