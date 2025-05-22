//Sends OSC combined to work with Unreal reading 12 indexes
//We have CSV Landmarks and Kinect Landmarks disappearing

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
String IPcomp = "192.168.0.100";  // target IP

void setup() {
  size(1920, 1080, P3D);
  background(0);

  // Init OSC
  oscP5 = new OscP5(this, 8007);
  myRemoteLocation = new NetAddress(IPcomp, 8005);

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
  //camera(0, -700, 1500, 960, 540, 0, 0, 1, 0);

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
      sendCombinedOSC(current);
    }
  }

  // Optional: 3D bounding box
  pushMatrix();
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

}//end draw

// --- Send one OSC message combining CSV and Kinect data ---
void sendCombinedOSC(Landmark current) {
  OscMessage combinedMessage = new OscMessage("/combinedOSC");

  // Add CSV left hand x, y, z
  combinedMessage.add(current.xLeft);
  combinedMessage.add(current.yLeft);
  combinedMessage.add(current.zLeft);

  // Add CSV right hand x, y, z
  combinedMessage.add(current.xRight);
  combinedMessage.add(current.yRight);
  combinedMessage.add(current.zRight);

  // Add Kinect left hand x, y, z (or placeholder if null)
  if (leftHandJoint != null) {
    combinedMessage.add(leftHandJoint.getX());
    combinedMessage.add(leftHandJoint.getY());
    combinedMessage.add(leftHandJoint.getZ());
  } else {
    combinedMessage.add(0); combinedMessage.add(0); combinedMessage.add(0);
  }

  // Add Kinect right hand x, y, z (or placeholder if null)
  if (rightHandJoint != null) {
    combinedMessage.add(rightHandJoint.getX());
    combinedMessage.add(rightHandJoint.getY());
    combinedMessage.add(rightHandJoint.getZ());
  } else {
    combinedMessage.add(0); combinedMessage.add(0); combinedMessage.add(0);
  }

  // Send message
  oscP5.send(combinedMessage, myRemoteLocation);

  // Print for debugging
  println("Combined OSC Sent:");
  println("CSV L: " + current.xLeft + ", " + current.yLeft + ", " + current.zLeft);
  println("CSV R: " + current.xRight + ", " + current.yRight + ", " + current.zRight);
  if (leftHandJoint != null && rightHandJoint != null) {
    println("Kinect L: " + leftHandJoint.getX() + ", " + leftHandJoint.getY() + ", " + leftHandJoint.getZ());
    println("Kinect R: " + rightHandJoint.getX() + ", " + rightHandJoint.getY() + ", " + rightHandJoint.getZ());
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
  stroke(255, 0, 0);
  strokeWeight(10);
  circle(0, 0, 10);
  popMatrix();
}
