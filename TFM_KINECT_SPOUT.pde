import oscP5.*;
import netP5.*;
import spout.*; // Spout library

OscP5 oscP5;
NetAddress myRemoteLocation;

Spout spout; // Spout sender

// Kinect coordinates only (6 floats total)
float leftHandKinectX, leftHandKinectY, leftHandKinectZ;
float rightHandKinectX, rightHandKinectY, rightHandKinectZ;

void setup() {
  size(1280, 720, P3D);
  background(0);

  // OSC Setup
  oscP5 = new OscP5(this, 11112); // Receiving port

  // Spout Setup
  spout = new Spout(this);
  spout.createSender("Processing_Kinect_Hands"); // This will show in Resolume as a Spout source

  println("Setup complete. Waiting for OSC Kinect data...");
}

void draw() {
  background(0);
  lights();

  // Translate and draw landmarks
  pushMatrix();
  translate(width/2, height/2, -500); // Center and move back for better 3D view
  drawHand(leftHandKinectX, leftHandKinectY, leftHandKinectZ, color(0, 255, 0));   // Green = Left
  drawHand(rightHandKinectX, rightHandKinectY, rightHandKinectZ, color(255, 0, 0)); // Red = Right
  popMatrix();

  // Send this frame to Spout
  spout.sendTexture();
}

void drawHand(float x, float y, float z, int c) {
  pushMatrix();
  translate(x, y, z);
  fill(c);
  noStroke();
  sphere(20);
  popMatrix();
}

// Receiving OSC from Kinect sketch
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/kinect/hands")) {
    if (msg.typetag().equals("ffffff")) {
      leftHandKinectX = msg.get(0).floatValue();
      leftHandKinectY = msg.get(1).floatValue();
      leftHandKinectZ = msg.get(2).floatValue();
      rightHandKinectX = msg.get(3).floatValue();
      rightHandKinectY = msg.get(4).floatValue();
      rightHandKinectZ = msg.get(5).floatValue();
    } else {
      println("Unexpected typetag: " + msg.typetag());
    }
  }
}
