//kinect hand detection range. tbd in final space
//x: 100, 2000
//y: 100, 1100

import KinectPV2.KJoint;
import KinectPV2.*;

import oscP5.*;
import netP5.*;

//kinect variables
KinectPV2 kinect;
KJoint rightHandJoint;
KJoint leftHandJoint;

//osc variables
OscP5 oscP5;
OscMessage myMessage;
NetAddress myRemoteLocation;

String IPcomp = "localhost";

float radius, rightPosY, leftPosY;


void setup() {
  size(1920, 1080, P3D);
  background(0);

  //initializing kinect
  kinect = new KinectPV2(this);
  kinect.enableSkeletonColorMap(true);
  kinect.enableColorImg(true);
  kinect.init();

  radius = 10;

  oscP5 = new OscP5(this, 11111);
  myRemoteLocation = new NetAddress(IPcomp, 8007);
  
  rightPosY = 0;
  leftPosY = 0;
}

void draw() {
  //background(0);
  frameRate(30);
  noStroke();
  fill(0, 0, 0, 10);
  rect(0, 0, 1920, 1080);

  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();

  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
    if (skeleton.isTracked()) {
      KJoint[] joints = skeleton.getJoints();

      // Get hand joints
      rightHandJoint = joints[KinectPV2.JointType_HandRight];
      leftHandJoint  = joints[KinectPV2.JointType_HandLeft];

      break;  // Only use first tracked skeleton
    }
  }

  // LEFT HAND
  if (leftHandJoint != null) {
    pushMatrix();
    translate(leftHandJoint.getX(), leftHandJoint.getY(), leftHandJoint.getZ());
    fill(255);
    noStroke();
    ellipse(0, 0, radius, radius);
    popMatrix();
    
    leftPosY = map(leftHandJoint.getY(), 0, 1080, 0, 1);
  }

  // RIGHT HAND
  if (rightHandJoint != null) {
    pushMatrix();
    translate(rightHandJoint.getX(), rightHandJoint.getY(), rightHandJoint.getZ());
    fill(255);
    noStroke();
    ellipse(0, 0, radius, radius);
    popMatrix();
    
    rightPosY = map(rightHandJoint.getY(), 0, 1080, 0, 1);
  }
  
  fill(255, 0, 0);
  textSize(50); 
  //text(frameRate, 50, 50); 
  if (leftHandJoint != null) {
    text("left X: " + leftHandJoint.getX(), 50, 300);
    text("left Y: " + leftHandJoint.getY(), 50, 400);
  }
  if (rightHandJoint != null) {
    text("right X: " + rightHandJoint.getX(), 50, 500);
    text("right Y: " + rightHandJoint.getY(), 50, 600);
  }
  myMessage = new OscMessage("/handsControl");
  myMessage.add(rightPosY);
  myMessage.add(leftPosY);
  oscP5.send(myMessage, myRemoteLocation);
  println("message: " + myMessage);
}//end draw
