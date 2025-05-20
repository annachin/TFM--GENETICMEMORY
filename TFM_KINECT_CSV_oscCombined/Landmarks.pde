class Landmark {
  float xLeft, xRight, yLeft, yRight, zLeft, zRight;
  float diameter = 5;
  float life = 255;

  Landmark(float xLandmarkLeft, float yLandmarkLeft, float zLandmarkLeft, float xLandmarkRight, float yLandmarkRight, float zLandmarkRight) {
    xLeft = xLandmarkLeft;
    xRight = xLandmarkRight;
    yLeft = yLandmarkLeft;
    yRight = yLandmarkRight;
    zLeft = zLandmarkLeft;
    zRight = zLandmarkRight;
  }
  
  void updateLife(){
    if(life > 0){
      life -= 5; //decrease stroke opacity over time
    }
    //life = 255;
  }
  
  void restartLife(){
    life = 255;
  }
  


  void displayLandmarks() {
    
    if (life <= 0) return; 
    
    noFill();
    stroke(255, 255, 255, life);
    strokeWeight(5);
    pushMatrix();
    translate(xLeft, yLeft, zLeft);
    circle(0, 0, diameter);
    popMatrix();
    strokeWeight(15);
    pushMatrix();
    translate(xRight, yRight, zRight);
    circle(0, 0, diameter);
    popMatrix();
  }
}//end Landmark class
