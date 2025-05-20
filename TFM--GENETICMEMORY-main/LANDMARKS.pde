class Landmark {

  float xLeft, xRight, yLeft, yRight, zLeft, zRight;
  float diameter = 5;
  float life = 255;

  Landmark(float xL, float yL, float zL, float xR, float yR, float zR) {
    xLeft = xL;
    yLeft = yL;
    zLeft = zL;
    xRight = xR;
    yRight = yR;
    zRight = zR;
  }

  void updateLife() {
    if (life > 0) {
      life -= 5;
    }
  }

  void restartLife() {
    life = 255;
  }

  void displayLandmarks() {
    if (life <= 0) return;

    // Left hand
    stroke(255, 255, 255, life);
    strokeWeight(10);
    pushMatrix();
    translate(xLeft, yLeft, zLeft);
    point(0, 0, 0);
    popMatrix();

    // Right hand
    stroke(255, 255, 255, life);
    strokeWeight(15);
    pushMatrix();
    translate(xRight, yRight, zRight);
    point(0, 0, 0);
    popMatrix();
  }
}
