import oscP5.*;
import netP5.*;


OscP5 oscP5;                 //Objeto osc para control de mensajes
NetAddress myRemoteLocation; //Variable para almacenar datos de adonde vamos a mandar los mensajes
OscMessage myMessage;        //Variable para introducir los mensajes OSC

//coordinates received from TFM KINECT CSV
float leftHandCoordX, leftHandCoordY, leftHandCoordZ, rightHandCoordX, rightHandCoordY, rightHandCoordZ;
float leftHandKinectX, leftHandKinectY, leftHandKinectZ, rightHandKinectX, rightHandKinectY, rightHandKinectZ;


String IPcompi= "192.168.0.2";

///////////////
// SETUP
void setup() {
  size(1920, 1080, P3D);
  background(0);

  //osc
  oscP5 = new OscP5(this, 11112); //Por donde recibiremos mensajes
  myRemoteLocation = new NetAddress(IPcompi, 8000); //Por donde mandaremos mensajes

  background(0);
}//end setup


void draw() {

  /*osc message visualize*/
  visualizeLandmarks(leftHandCoordX, leftHandCoordY, leftHandCoordZ);
  visualizeLandmarks(rightHandCoordX, rightHandCoordY, rightHandCoordZ);
  visualizeLandmarks(leftHandKinectX, leftHandKinectY, leftHandKinectZ);
  visualizeLandmarks(rightHandKinectX, rightHandKinectY, rightHandKinectZ);

  //osc message send
  myMessage = new OscMessage("/hands");
  myMessage.add(leftHandCoordX);
  myMessage.add(leftHandCoordY);
  myMessage.add(leftHandCoordZ);
  myMessage.add(rightHandCoordX);
  myMessage.add(rightHandCoordY);
  myMessage.add(rightHandCoordZ);
  oscP5.send(myMessage, myRemoteLocation);
}//end draw


//receive messages
/* Los mensajes entrantes de osc se reciben en ésta función de la librería  */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());

  if (theOscMessage.checkAddrPattern("/combinedOSC")==true) {

    /*Extraemos los valores de los argumentos del mensaje y los asignamos a las variables designadas  */
    leftHandCoordX = theOscMessage.get(0).floatValue();
    leftHandCoordY = theOscMessage.get(1).floatValue();
    leftHandCoordZ = theOscMessage.get(2).floatValue();
    rightHandCoordX = theOscMessage.get(3).floatValue();
    rightHandCoordY = theOscMessage.get(4).floatValue();
    rightHandCoordZ = theOscMessage.get(5).floatValue();
    leftHandKinectX = theOscMessage.get(6).floatValue();
    leftHandKinectY = theOscMessage.get(7).floatValue();
    leftHandKinectZ = theOscMessage.get(8).floatValue();
    rightHandKinectX = theOscMessage.get(9).floatValue();
    rightHandKinectY = theOscMessage.get(10).floatValue();
    rightHandKinectZ = theOscMessage.get(11).floatValue();
    //print("### received an osc message /dibujoRemoto with values > x:"+ xRecibido +" y:"+ xRecibido);
  }
}//end receive message

void visualizeLandmarks(float x, float y, float z) {
  noFill();
  stroke(0, 0, 255);
  strokeWeight(4);
  pushMatrix();
  translate(x, y, z);
  circle(0, 0, 10);
  popMatrix();
}
