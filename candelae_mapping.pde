// Candelæ visual sketch 001
// black -> sprout -> tree -> bloom -> petals -> decay -> loop

int W = 1280;
int H = 720;

float t = 0;
float cycle = 18.0; // seconds per loop

ArrayList<Branch> branches = new ArrayList<Branch>();
ArrayList<Petal> petals = new ArrayList<Petal>();

boolean branchesCreated = false;
boolean petalsCreated = false;

void settings() {
  size(W, H, P2D);
}

void setup() {
  frameRate(60);
  resetScene();
}

void draw() {
  float dt = 1.0 / frameRate;
  t += dt;

  float phase = t / cycle;

  if (phase >= 1.0) {
    resetScene();
    return;
  }

  background(0);

  // phases
  float sproutStart = 0.05;
  float treeStart   = 0.18;
  float bloomStart  = 0.45;
  float fallStart   = 0.60;
  float decayStart  = 0.78;

  float alpha = 255;

  if (phase > decayStart) {
    alpha = map(phase, decayStart, 1.0, 255, 0);
  }

  // create branches once
  if (!branchesCreated && phase > treeStart) {
    createTree();
    branchesCreated = true;
  }

  // create petals once
  if (!petalsCreated && phase > bloomStart) {
    createPetals();
    petalsCreated = true;
  }

  // sprout
  float sproutProgress = constrain(map(phase, sproutStart, treeStart, 0, 1), 0, 1);
  drawSprout(sproutProgress, alpha);

  // branches
  if (branchesCreated) {
    float branchProgress = constrain(map(phase, treeStart, bloomStart, 0, 1), 0, 1);
    for (Branch b : branches) {
      b.display(branchProgress, alpha);
    }
  }

  // bloom petals
  if (petalsCreated) {
    boolean falling = phase > fallStart;

    for (Petal p : petals) {
      if (falling) {
        p.update();
      }
      p.display(alpha);
    }
  }

  // slight vignette
  drawVignette();
}

void resetScene() {
  t = 0;
  branches.clear();
  petals.clear();
  branchesCreated = false;
  petalsCreated = false;
}

void drawSprout(float progress, float alpha) {
  float baseX = width / 2;
  float baseY = height * 0.88;
  float topY = lerp(baseY, height * 0.48, easeOut(progress));

  stroke(220, alpha);
  strokeWeight(2);
  noFill();

  beginShape();
  for (int i = 0; i < 60; i++) {
    float u = i / 59.0;
    float y = lerp(baseY, topY, u);
    float sway = sin(u * PI * 2.0 + t * 0.7) * 5.0 * u;
    float x = baseX + sway;
    vertex(x, y);
  }
  endShape();
}

void createTree() {
  PVector root = new PVector(width / 2, height * 0.88);
  PVector trunkTop = new PVector(width / 2, height * 0.42);

  generateBranch(root, trunkTop, 0, 5);
}

void generateBranch(PVector a, PVector b, int depth, int maxDepth) {
  branches.add(new Branch(a.copy(), b.copy(), depth));

  if (depth >= maxDepth) return;

  int count = depth < 2 ? 2 : int(random(1, 3));

  for (int i = 0; i < count; i++) {
    float angle = random(-PI * 0.65, PI * 0.65) - PI / 2.0;
    float len = PVector.dist(a, b) * random(0.42, 0.70);

    PVector dir = PVector.sub(b, a);
    dir.normalize();
    dir.rotate(random(-0.85, 0.85));
    dir.mult(len);

    PVector c = PVector.add(b, dir);

    c.x = constrain(c.x, width * 0.12, width * 0.88);
    c.y = constrain(c.y, height * 0.12, height * 0.88);

    generateBranch(b, c, depth + 1, maxDepth);
  }
}

void createPetals() {
  for (Branch b : branches) {
    if (b.depth >= 3) {
      int count = int(random(3, 8));
      for (int i = 0; i < count; i++) {
        float u = random(0.45, 1.0);
        PVector pos = PVector.lerp(b.a, b.b, u);

        petals.add(new Petal(pos.x, pos.y));
      }
    }
  }
}

void drawVignette() {
  noFill();
  for (int i = 0; i < 120; i++) {
    float a = map(i, 0, 120, 0, 120);
    stroke(0, a);
    rect(i, i, width - i * 2, height - i * 2);
  }
}

float easeOut(float x) {
  return 1.0 - pow(1.0 - x, 3.0);
}

class Branch {
  PVector a;
  PVector b;
  int depth;

  Branch(PVector a_, PVector b_, int depth_) {
    a = a_;
    b = b_;
    depth = depth_;
  }

  void display(float progress, float alpha) {
    float localDelay = depth * 0.08;
    float p = constrain(map(progress, localDelay, 1.0, 0, 1), 0, 1);
    p = easeOut(p);

    PVector end = PVector.lerp(a, b, p);

    float w = map(depth, 0, 5, 3.2, 0.8);

    stroke(210, alpha * 0.85);
    strokeWeight(w);
    noFill();

    line(a.x, a.y, end.x, end.y);
  }
}

class Petal {
  PVector pos;
  PVector vel;
  color col;
  float size;
  float driftSeed;

  Petal(float x, float y) {
    pos = new PVector(x, y);
    vel = new PVector(random(-0.25, 0.25), random(0.25, 0.8));

    color[] palette = {
      color(255, 180, 210),
      color(210, 230, 255),
      color(255, 230, 160),
      color(210, 255, 220),
      color(230, 190, 255)
    };

    col = palette[int(random(palette.length))];
    size = random(2.0, 5.5);
    driftSeed = random(1000);
  }

  void update() {
    float drift = noise(driftSeed, frameCount * 0.01) - 0.5;
    pos.x += vel.x + drift * 1.4;
    pos.y += vel.y;

    if (pos.y > height + 20) {
      pos.y = random(-40, -10);
      pos.x = random(width * 0.2, width * 0.8);
    }
  }

  void display(float alpha) {
    noStroke();
    fill(red(col), green(col), blue(col), alpha * 0.9);
    ellipse(pos.x, pos.y, size, size * 0.65);
  }
}
