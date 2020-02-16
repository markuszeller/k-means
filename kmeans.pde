import java.util.Date; //<>//

// ==== Begin Config ====

// How many groups to create
final int groupSize = 64;

// How many data points to create
final int dataPointSize = 100 * 100;

// Padding to border
final int paddingSize = 20;

// Blur strength
final int blurStrength = 2;
final int finalBlurStrength = 1;

// Rotate color palette after each pass
final boolean rotateColors = true;

// Save image
final boolean saveImage = true;

// How many loops / images to create
final int loopSize = 10;

// ==== End Config ====

PVector[] groups = new PVector[groupSize];
PVector[] means = new PVector[groupSize];
int[] clusters = new int[groupSize];
color[] colors = new color[groupSize]; 
PVector[] dataPoints = new PVector[dataPointSize];
int dataRow = 0;
int meansChanged = groupSize;
int pass = 1;
int loopsToDo = loopSize;
long timerStart;

void setup() {

  // Picture size to render
  size(800, 800);
  
  reset();  

}

void reset() {

  timerStart = new Date().getTime();
  clear();

  float n1 = random(1) / groupSize;
  float n2 = random(1) / groupSize;
  float n3 = random(1) / groupSize;
  
  for(int i = 0; i < groupSize; i++) {
    groups[i] = new PVector(getRandomWidth(), getRandomHeight());
    colors[i] = color(noise(i * n1) * 255, noise(i * n2) * 255, noise(i * n3) * 255);
    means[i] = new PVector(0, 0);
    clusters[i] = 0;
  }
  
  for(int i = 0; i < dataPointSize; i++) {
    dataPoints[i] = new PVector(getRandomWidth(), getRandomHeight());
  }

  meansChanged = groupSize;
  pass = 1;

  drawDataPoints();

}

float getRandomWidth() {

  return abs(random(width - paddingSize - paddingSize) + paddingSize); 

}

float getRandomHeight() {

  return abs(random(height - paddingSize - paddingSize) + paddingSize); 

}

void drawGroups() {
  
  noStroke();

  for(int i = 0; i < groupSize; i++) {
    fill(colors[i]);
    circle(groups[i].x, groups[i].y, 4);
  }

}

void drawDataPoints() {

  noStroke();

  fill(0, 0, 255);
  for(int i = 0; i < dataPointSize; i++) {
    circle(dataPoints[i].x, dataPoints[i].y, 2);
  }

}

int calculateMeans() {

  int changes = 0; //<>//
  
  for(int i = 0; i < groupSize; i++) {
    PVector mean = new PVector((int) (means[i].x / clusters[i]), (int) (means[i].y / clusters[i]));
    means[i] = new PVector(0, 0);
    clusters[i] = 0;
    if(mean.x == (int) groups[i].x && mean.y == (int) groups[i].y) break;
    groups[i] = mean;
    changes++;
  }
  
  return changes;

}

void rotateColors() {
  
  if(!rotateColors) return;
  
  color first = colors[0];
  for(int i = 0, s = colors.length - 1; i < s; i++) {
    colors[i] = colors[i + 1];
  }
  
  colors[colors.length - 1] = first;
  
}

void drawConnections() {
  
  for(int steps = 0, stepMax = (int) sqrt(width * height); steps < stepMax; steps++) {
  
    if(dataRow >= dataPointSize) {
      long timerEnd = new Date().getTime();
      long timeDiff = timerEnd - timerStart;
      timerStart = timerEnd;
      println(String.format("Loop %d/%d; Pass %d; Means %d; Took %.02fs",
        loopSize - loopsToDo + 1, loopSize, pass++, (meansChanged = calculateMeans()), (float) timeDiff / 1000
      ));
      dataRow = 0;
      rotateColors();
      if(meansChanged > 0 && blurStrength > 0) filter(BLUR, 2);

      return;
    }
    
      int smallestIndex = 0;
      float shortest = max(width, height);
      
      for(int j = 0; j < groupSize; j++) {
        float distance = dist(dataPoints[dataRow].x, dataPoints[dataRow].y, groups[j].x, groups[j].y);
        if(distance < shortest) {
          shortest = distance;
          smallestIndex = j;
        } 
      }
      
      clusters[smallestIndex]++;
      means[smallestIndex] = new PVector(means[smallestIndex].x + dataPoints[dataRow].x, means[smallestIndex].y + dataPoints[dataRow].y);
      stroke(colors[smallestIndex]);
      line(dataPoints[dataRow].x, dataPoints[dataRow].y, groups[smallestIndex].x, groups[smallestIndex].y);
      
      dataRow++;
  }
  
}

void draw() {
  
  drawGroups();
  drawConnections();
  
  if(meansChanged == 0) {
    if(finalBlurStrength > 0) filter(BLUR, 1);
    
    if(saveImage) {
      Date date = new Date();
      save(String.format("data/%d_gs%d_dp%d.png",
        date.getTime(), groupSize, dataPointSize
      ));
    }
    
    loopsToDo--;
    println(String.format("Done; Loop %d/%d",
      loopSize - loopsToDo, loopSize
    ));
    
    if(loopsToDo <= 0) {
      noLoop();
      return;
    }
    
    reset();

  }

}
