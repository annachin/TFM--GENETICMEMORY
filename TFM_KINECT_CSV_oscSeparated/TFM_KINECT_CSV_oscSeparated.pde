//draws points in a 3d space according to coordinates
//landmarks are from the hand detection of dance videos
//real time interaction is with kinect hand detection
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
NetAddress myRemoteLocation;
String IPcomp = "192.168.0.2";  // target IP

void setup() {
  size(1920, 1080, P3D);
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

  // CSV Landmark Playback
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

  //3D box
  pushMatrix();
  translate(960, 540, 0);
  stroke(255);
  strokeWeight(1);
  box(1000);
  popMatrix();
  
  //reset hanf joints
  leftHandJoint = null;
  rightHandJoint = null;

  // Kinect Hand Tracking
  ArrayList<KSkeleton> skeletonArray = kinect.getSkeletonColorMap();
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
    if (skeleton.isTracked()) {
      KJoint[] joints = skeleton.getJoints();
      rightHandJoint = joints[KinectPV2.JointType_HandRight];
      leftHandJoint = joints[KinectPV2.JointType_HandLeft];
      break;
    }
  }

  if (leftHandJoint != null) drawHandSphere(leftHandJoint);
  if (rightHandJoint != null) drawHandSphere(rightHandJoint);
}

void sendCombinedOSC(Landmark current) {
  // Send CSV hand data (already mapped)
  sendFloatOSC("/CSVHandLeftX", current.xLeft);
  sendFloatOSC("/CSVHandLeftY", current.yLeft);
  sendFloatOSC("/CSVHandLeftZ", current.zLeft);

  sendFloatOSC("/CSVHandRightX", current.xRight);
  sendFloatOSC("/CSVHandRightY", current.yRight);
  sendFloatOSC("/CSVHandRightZ", current.zRight);

  // Left Hand Kinect
  float leftX = 0;
  float leftY = 0;
  float leftZ = 5000;

  if (leftHandJoint != null) {
    leftX = leftHandJoint.getX();
    leftY = leftHandJoint.getY();
    leftZ = map(leftHandJoint.getZ(), 0, 500, 0, 20);
  }

  sendFloatOSC("/KinectHandLeftX", leftX);
  sendFloatOSC("/KinectHandLeftY", leftY);
  sendFloatOSC("/KinectHandLeftZ", leftZ);

  // Right Hand Kinect
  float rightX = 0;
  float rightY = 0;
  float rightZ = 5000;

  if (rightHandJoint != null) {
    rightX = rightHandJoint.getX();
    rightY = rightHandJoint.getY();
    rightZ = map(rightHandJoint.getZ(), 0, 500, 0, 20);
  }

  sendFloatOSC("/KinectHandRightX", rightX);
  sendFloatOSC("/KinectHandRightY", rightY);
  sendFloatOSC("/KinectHandRightZ", rightZ);

  println("...................");
  println("sending:");
  println("CSV L: " + current.xLeft + ", " + current.yLeft + ", " + current.zLeft);
  println("CSV R: " + current.xRight + ", " + current.yRight + ", " + current.zRight);
  println("Kinect L: " + leftX + ", " + leftY + ", " + leftZ);
  println("Kinect R: " + rightX + ", " + rightY + ", " + rightZ);
}


void sendFloatOSC(String address, float val) {
  // Prevent sending NaN or undefined values
  if (Float.isNaN(val) || Float.isInfinite(val)) val = 0;

  // Format to 3 decimal places
  val = Float.parseFloat(nf(val, 1, 3));  

  OscMessage msg = new OscMessage(address);
  msg.add(val);
  oscP5.send(msg, myRemoteLocation);
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
    float zL = map(rowL.getFloat("z"), -1, 1, 0, 20);
    float xR = rowR.getFloat("x");
    float yR = rowR.getFloat("y");
    float zR = map(rowR.getFloat("z"), -1, 1, 0, 20);

    // Smooth missing data
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
