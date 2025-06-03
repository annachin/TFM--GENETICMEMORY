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
int pointInterval = 30;
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
  //frameRate(30);

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
  fill(255, 0, 0);
  textSize(50);
  text(frameCount, 100, 100);
  text("CSV row: " + numVisible, 100, 160);

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
  noFill();
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
  
   // Hand Detection Status
  boolean handDetected = (leftHandJoint != null || rightHandJoint != null);
  sendFloatOSC("/KinectHandDetected", handDetected ? 1.0 : 0.0);

  println("...................");
  println("sending:");
  println("CSV L: " + current.xLeft + ", " + current.yLeft + ", " + current.zLeft);
  println("CSV R: " + current.xRight + ", " + current.yRight + ", " + current.zRight);
  println("Kinect L: " + leftX + ", " + leftY + ", " + leftZ);
  println("Kinect R: " + rightX + ", " + rightY + ", " + rightZ);
  println("Detection: " + handDetected);
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
  leftHand = loadTable("dancers-edit-june-2-left_XYZ.csv", "header");
  rightHand = loadTable("dancers-edit-june-2-right_XYZ.csv", "header");

  int rowCount = leftHand.getRowCount();
  landmarks = new Landmark[rowCount];

  float[] xLArr = new float[rowCount];
  float[] yLArr = new float[rowCount];
  float[] zLArr = new float[rowCount];
  float[] xRArr = new float[rowCount];
  float[] yRArr = new float[rowCount];
  float[] zRArr = new float[rowCount];

  // Load raw data
  for (int i = 0; i < rowCount; i++) {
    TableRow rowL = leftHand.getRow(i);
    TableRow rowR = rightHand.getRow(i);

    xLArr[i] = rowL.getFloat("x");
    yLArr[i] = rowL.getFloat("y");
    zLArr[i] = rowL.getFloat("z");

    xRArr[i] = rowR.getFloat("x");
    yRArr[i] = rowR.getFloat("y");
    zRArr[i] = rowR.getFloat("z");
  }

  // Interpolate over 2 to 4 consecutive zeros
  for (int i = 1; i < rowCount - 1; i++) {
    for (int gap = 2; gap <= 4; gap++) {
      if (i + gap < rowCount) {
        boolean canInterpL = checkZeroBlock(xLArr, yLArr, zLArr, i, gap);
        boolean canInterpR = checkZeroBlock(xRArr, yRArr, zRArr, i, gap);

        if (canInterpL && !isZero(xLArr[i - 1], yLArr[i - 1], zLArr[i - 1]) &&
            !isZero(xLArr[i + gap], yLArr[i + gap], zLArr[i + gap])) {
          for (int j = 0; j < gap; j++) {
            float t = (j + 1.0) / (gap + 1);
            xLArr[i + j] = lerp(xLArr[i - 1], xLArr[i + gap], t);
            yLArr[i + j] = lerp(yLArr[i - 1], yLArr[i + gap], t);
            zLArr[i + j] = lerp(zLArr[i - 1], zLArr[i + gap], t);
          }
        }

        if (canInterpR && !isZero(xRArr[i - 1], yRArr[i - 1], zRArr[i - 1]) &&
            !isZero(xRArr[i + gap], yRArr[i + gap], zRArr[i + gap])) {
          for (int j = 0; j < gap; j++) {
            float t = (j + 1.0) / (gap + 1);
            xRArr[i + j] = lerp(xRArr[i - 1], xRArr[i + gap], t);
            yRArr[i + j] = lerp(yRArr[i - 1], yRArr[i + gap], t);
            zRArr[i + j] = lerp(zRArr[i - 1], zRArr[i + gap], t);
          }
        }
      }
    }
  }

  // Store final data into Landmark objects
  for (int i = 0; i < rowCount; i++) {
    float xL = xLArr[i], yL = yLArr[i], zL = zLArr[i];
    if (isZero(xL, yL, zL)) zL = 5000;

    float xR = xRArr[i], yR = yRArr[i], zR = zRArr[i];
    if (isZero(xR, yR, zR)) zR = 5000;

    landmarks[i] = new Landmark(xL, yL, zL, xR, yR, zR);
  }
}

// --- Helper Functions ---
boolean isZero(float x, float y, float z) {
  return x == 0 && y == 0 && z == 0;
}

boolean checkZeroBlock(float[] x, float[] y, float[] z, int start, int count) {
  for (int i = 0; i < count; i++) {
    if (!isZero(x[start + i], y[start + i], z[start + i])) return false;
  }
  return true;
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
