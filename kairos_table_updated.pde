import oscP5.*;
import netP5.*;
 
OscP5 oscP5;
OscMessage myMessage;
NetAddress myRemoteLocation;

String IPcomp = "192.168.0.1"; // update this if needed
 
Table leftHand;
Table rightHand;

Landmark[] landmarks;
 
int numVisible = 0;
int pointInterval = 300;
int lastPointTime = 0;
float lastXL = 0, lastYL = 0, lastZL = 0;
float lastXR = 0, lastYR = 0, lastZR = 0;
 
void setup() {

  size(1000, 1000, P3D);
  loadData();
  oscP5 = new OscP5(this, 8007);
  myRemoteLocation = new NetAddress(IPcomp, 11112);

}
 
void draw() {

  background(0);
  camera(0, -700, 1500, 960, 540, 0, 0, 1, 0);
 
  for (int i = 0; i < numVisible && i < landmarks.length; i++) {

    landmarks[i].updateLife();
    landmarks[i].displayLandmarks();

  }
 
  int now = millis();

  if (now - lastPointTime > pointInterval) {
    if (numVisible < landmarks.length) {
      
      numVisible++;

    } else {

      numVisible = 0;
      for (Landmark l : landmarks) {
        l.restartLife();
      }
    }

    lastPointTime = now;
 
    if (numVisible > 0) {

      Landmark current = landmarks[numVisible - 1];
      sendOSC(current);

    }
  }
 
  // Optional: 3D bounding box

  pushMatrix();
  translate(960, 540, 0);
  stroke(255);
  strokeWeight(1);
  box(1000);
  popMatrix();

}
 
void sendOSC(Landmark current) {

  myMessage = new OscMessage("/hands");

  myMessage.add(current.xLeft);
  myMessage.add(current.yLeft);
  myMessage.add(current.zLeft);

  myMessage.add(current.xRight);
  myMessage.add(current.yRight);
  myMessage.add(current.zRight);
  oscP5.send(myMessage, myRemoteLocation);
 
  println("OSC Sent:");
  println("L: " + current.xLeft + ", " + current.yLeft + ", " + current.zLeft);
  println("R: " + current.xRight + ", " + current.yRight + ", " + current.zRight);

}
 
void loadData() {

  leftHand = loadTable("video-left_XYZ.csv", "header");
  rightHand = loadTable("video-right_XYZ.csv", "header");
 
  int rowCount = leftHand.getRowCount();
  landmarks = new Landmark[rowCount];
 
  for (int i = 0; i < rowCount; i++) {

    TableRow rowL = leftHand.getRow(i);
    TableRow rowR = rightHand.getRow(i);
 
    float xL = rowL.getFloat("x");
    float yL = rowL.getFloat("y");
    float zL = map(rowL.getFloat("z"), -1, 1, -200000, 200000);
    float xR = rowR.getFloat("x");
    float yR = rowR.getFloat("y");
    float zR = map(rowR.getFloat("z"), -1, 1, -200000, 200000);
 
    // Fix missing hand data

    if (xL == 0 && yL == 0 && zL == 0) {

      xL = lastXL;
      yL = lastYL;
      zL = lastZL;

    } else {

      lastXL = xL;
      lastYL = yL;
      lastZL = zL;

    }
 
    if (xR == 0 && yR == 0 && zR == 0) {

      xR = lastXR;
      yR = lastYR;
      zR = lastZR;

    } else {

      lastXR = xR;
      lastYR = yR;
      lastZR = zR;
    }
 
    landmarks[i] = new Landmark(xL, yL, zL, xR, yR, zR);
  }
}

 
