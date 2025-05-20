import KinectPV2.*;
import KinectPV2.KJoint;

import oscP5.*;
import netP5.*;

Table leftHand, rightHand;
Landmark[] landmarks;

// CSV playback variables
int numVisible = 0;
int pointInterval = 300;
int lastPointTime = 0;
float lastXL = 0, lastYL = 0, lastZL = 0;
float lastXR = 0, lastYR = 0, lastZR = 0;

// Kinect variables
KinectPV2 kinect;
KJoint rightHandJoint, leftHandJoint;

// OSC variables
OscP5 oscP5;
OscMessage myMessage;
NetAddress myRemoteLocation;
String IPcomp = "192.168.0.1";  // Change to your target IP if needed

void setup() {
  size(1000, 1000, P3D);
  background(0);

  // Init OSC
  oscP5 = new OscP5(this, 8007);
  myRemoteLocation = new NetAddress(IPcomp, 11112);

  // Load CSV data
  loadData();

  // Init Kinect
  kinect = new KinectPV2(this);
  kinect.enableSkeletonColorMap(true);
  kinect.enableColorImg(true);
  kinect.init();
}

void draw() {
  background(0);
  camera(0, -700, 1500, 960, 540, 0, 0, 1, 0);

  // --- CSV Landmark Playback ---
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
      sendOSCFromCSV(current);
    }
  }

  // Optional: 3D bounding box
  pushMatrix();
  noFill();
  translate(960, 540, 0);
  stroke(255);
  strokeWeight(1);
  box(1000);
  popMatrix();

  // --- Kinect Realtime Hand Tracking ---
  ArrayList<KSkeleton> skeletonArray = kinect.getSkeletonColorMap();
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
    if (skeleton.isTracked()) {
      KJoint[] joints = skeleton.getJoints();
      rightHandJoint = joints[KinectPV2.JointType_HandRight];
      leftHandJoint = joints[KinectPV2.JointType_HandLeft];
      break; // Only use first tracked skeleton
    }
  }
  if (leftHandJoint != null) {
    drawHandSphere(leftHandJoint);
  }
  
  if (rightHandJoint != null) {
    drawHandSphere(rightHandJoint);
  }
  
  sendOSCFromKinect();  // This now sends full x, y, z for both hands
 
}

// --- Send OSC messages from CSV landmark data ---
void sendOSCFromCSV(Landmark current) {
  myMessage = new OscMessage("/hands");
  myMessage.add(current.xLeft);
  myMessage.add(current.yLeft);
  myMessage.add(current.zLeft);
  myMessage.add(current.xRight);
  myMessage.add(current.yRight);
  myMessage.add(current.zRight);
  oscP5.send(myMessage, myRemoteLocation);

  println("CSV OSC Sent:");
  println("L: " + current.xLeft + ", " + current.yLeft + ", " + current.zLeft);
  println("R: " + current.xRight + ", " + current.yRight + ", " + current.zRight);
}

// --- Send OSC messages from Kinect real-time data ---
void sendOSCFromKinect() {
  if (rightHandJoint != null && leftHandJoint != null) {
    OscMessage kinectMsg = new OscMessage("/handsControl");

    // Add left hand x, y, z
    kinectMsg.add(leftHandJoint.getX());
    kinectMsg.add(leftHandJoint.getY());
    kinectMsg.add(leftHandJoint.getZ());

    // Add right hand x, y, z
    kinectMsg.add(rightHandJoint.getX());
    kinectMsg.add(rightHandJoint.getY());
    kinectMsg.add(rightHandJoint.getZ());

    oscP5.send(kinectMsg, myRemoteLocation);

    println("Kinect OSC Sent:");
    println("L: " + leftHandJoint.getX() + ", " + leftHandJoint.getY() + ", " + leftHandJoint.getZ());
    println("R: " + rightHandJoint.getX() + ", " + rightHandJoint.getY() + ", " + rightHandJoint.getZ());
  }
}


// --- Load CSV hand data ---
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

// --- Draw hand spheres from Kinect data ---
void drawHandSphere(KJoint joint) {
  pushMatrix();
  translate(joint.getX(), joint.getY(), joint.getZ());
  fill(255);
  noStroke();
  ellipse(0, 0, 10, 10);
  popMatrix();
}
