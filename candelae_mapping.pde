// Candelæ visual sketch 003
// upward canopy: point -> branches -> bloom -> petals toward viewer -> fade

int W = 1280;
int H = 720;

float t = 0;
float cycle = 18.0;

ArrayList<Branch> branches = new ArrayList<Branch>();
ArrayList<Flower> flowers = new ArrayList<Flower>();
ArrayList<Petal> petals = new ArrayList<Petal>();

boolean structureCreated = false;
boolean petalsReleased = false;

int MAX_BRANCHES = 520;
int MAX_FLOWERS = 780;
int MAX_PETALS = 900;

void setup() {
  size(1280, 720, P2D);
  frameRate(60);
  smooth(4);
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

  float growStart  = 0.05;
  float bloomStart = 0.40;
  float fallStart  = 0.70;
  float decayStart = 0.88;

  float alpha = 255;
  if (phase > decayStart) {
    alpha = map(phase, decayStart, 1.0, 255, 0);
  }

  if (!structureCreated && phase > growStart) {
    createTreeFromCenter();
    structureCreated = true;
  }

  float growProgress = constrain(map(phase, growStart, bloomStart, 0, 1), 0, 1);
  float bloomProgress = constrain(map(phase, bloomStart, fallStart, 0, 1), 0, 1);
  boolean falling = phase > fallStart;

  if (structureCreated) {
    for (Branch b : branches) {
      b.display(growProgress, alpha);
    }

    for (Flower f : flowers) {
      f.display(bloomProgress, alpha);
    }
  }

  if (falling && !petalsReleased) {
    releasePetals();
    petalsReleased = true;
  }

  if (petalsReleased) {
    for (Petal p : petals) {
      p.update();
      p.display(alpha);
    }
  }

  drawVignette();
}

void resetScene() {
  t = 0;
  branches.clear();
  flowers.clear();
  petals.clear();
  structureCreated = false;
  petalsReleased = false;
}

void createTreeFromCenter() {
  PVector root = new PVector(width / 2, height * 0.58);

  int mainBranches = 12;

  for (int i = 0; i < mainBranches; i++) {
    float ratio = i / float(mainBranches - 1);

    // 180度：左上〜右上
    float angle = map(ratio, 0, 1, PI * 1.05, PI * 1.95);

    // 真上寄りを少し長くする
    float centerBias = 1.0 - abs(ratio - 0.5) * 1.2;
    float len = random(170, 260) + centerBias * 90;

    angle += random(-0.08, 0.08);

    PVector end = new PVector(
      root.x + cos(angle) * len,
      root.y + sin(angle) * len
    );

    growBranch(root, end, 0, 6);
  }
}

void growBranch(PVector a, PVector b, int depth, int maxDepth) {
  if (branches.size() >= MAX_BRANCHES) return;

  branches.add(new Branch(a.copy(), b.copy(), depth));

  if (depth >= maxDepth) {
    if (flowers.size() < MAX_FLOWERS && random(1) < 0.92) {
      flowers.add(new Flower(b.x, b.y));
    }
    return;
  }

  int count;

  if (depth == 0) {
    count = int(random(2, 4));
  } else if (depth < 3) {
    count = int(random(1, 3));
  } else {
    count = random(1) < 0.72 ? 1 : 2;
  }

  PVector baseDir = PVector.sub(b, a);
  float baseAngle = atan2(baseDir.y, baseDir.x);

  for (int i = 0; i < count; i++) {
    float nextAngle = baseAngle + random(-0.65, 0.65);

    // 枝は少しずつ短く
    float len = baseDir.mag() * random(0.48, 0.74);

    PVector c = new PVector(
      b.x + cos(nextAngle) * len,
      b.y + sin(nextAngle) * len
    );

    // 画面端で無理に止めない。
    // 多少はみ出してOK。プロジェクションっぽく自然になる。
    growBranch(b, c, depth + 1, maxDepth);
  }
}

void drawVignette() {
  noFill();
  for (int i = 0; i < 100; i++) {
    float a = map(i, 0, 100, 0, 115);
    stroke(0, a);
    rect(i, i, width - i * 2, height - i * 2);
  }
}

float easeOut(float x) {
  return 1.0 - pow(1.0 - x, 3.0);
}

float easeInOut(float x) {
  return x < 0.5
    ? 4.0 * x * x * x
    : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0;
}

class Branch {
  PVector a;
  PVector b;
  int depth;
  float seed;

  Branch(PVector a_, PVector b_, int depth_) {
    a = a_;
    b = b_;
    depth = depth_;
    seed = random(1000);
  }

  void display(float progress, float alpha) {
    float localDelay = depth * 0.05;
    float p = constrain(map(progress, localDelay, 1.0, 0, 1), 0, 1);
    p = easeOut(p);

    PVector end = PVector.lerp(a, b, p);

    drawWoodLine(a, end, depth, alpha, seed);
  }
}

void drawWoodLine(PVector start, PVector end, int depth, float alpha, float seed) {
  float w = map(depth, 0, 6, 7.5, 0.45);

  stroke(220, alpha * map(depth, 0, 6, 0.88, 0.38));
  strokeWeight(w);
  noFill();

  beginShape();

  for (int i = 0; i < 18; i++) {
    float u = i / 17.0;

    float x = lerp(start.x, end.x, u);
    float y = lerp(start.y, end.y, u);

    float n = noise(seed, u * 2.5, frameCount * 0.004);
    float wobble = map(n, 0, 1, -1, 1);

    float strength = map(depth, 0, 6, 0.4, 4.2) * u;

    x += wobble * strength;
    y += wobble * strength * 0.35;

    vertex(x, y);
  }

  endShape();
}

class Flower {
  PVector pos;
  color col;
  float size;
  float delay;
  float seed;

  Flower(float x, float y) {
    pos = new PVector(x, y);

    colorMode(HSB, 360, 100, 100);
    float h = random(0, 360);
    float s = random(55, 95);
    float b = random(86, 100);
    col = color(h, s, b);
    colorMode(RGB, 255);

    size = random(3.0, 8.8);
    delay = random(0.0, 0.78);
    seed = random(1000);
  }

  void display(float bloomProgress, float alpha) {
    float p = constrain(map(bloomProgress, delay, 1.0, 0, 1), 0, 1);
    p = easeInOut(p);

    float pulse = 1.0 + sin(t * 2.0 + seed) * 0.10;
    float s = size * p * pulse;

    noStroke();

    fill(red(col), green(col), blue(col), alpha * p * 0.95);
    ellipse(pos.x, pos.y, s, s);

    fill(255, alpha * p * 0.32);
    ellipse(pos.x, pos.y, s * 0.42, s * 0.42);
  }
}

class Petal {
  PVector pos;
  PVector vel;
  color col;
  float size;
  float seed;
  float depth;

  Petal(float x, float y, color c) {
    pos = new PVector(x, y);

    // 奥から手前へ来る感じ：
    // 最初は小さく、ゆっくり。だんだん大きく速くなる。
    vel = new PVector(random(-0.35, 0.35), random(0.25, 0.75));

    col = c;
    size = random(1.0, 3.2);
    seed = random(1000);
    depth = random(0.0, 1.0);
  }

  void update() {
    float drift = noise(seed, frameCount * 0.012) - 0.5;

    // depthが増えるほど手前に来ている扱い
    depth += 0.006;

    float speedScale = map(depth, 0, 1, 0.7, 2.6);
    float spreadScale = map(depth, 0, 1, 0.4, 2.2);

    pos.x += vel.x * spreadScale + drift * 1.8 * spreadScale;
    pos.y += vel.y * speedScale;

    // 手前に来るほど大きくなる
    size *= 1.006;

    if (pos.y > height + 60 || size > 18) {
      pos.y = random(height * 0.15, height * 0.55);
      pos.x = random(width * 0.18, width * 0.82);
      size = random(1.0, 3.2);
      depth = 0;
    }
  }

  void display(float alpha) {
    noStroke();

    float a = alpha * map(size, 1, 18, 0.45, 0.92);
    fill(red(col), green(col), blue(col), a);

    ellipse(pos.x, pos.y, size, size * 0.62);
  }
}

void releasePetals() {
  for (Flower f : flowers) {
    if (petals.size() >= MAX_PETALS) break;

    int count = int(random(2, 5));

    for (int i = 0; i < count; i++) {
      if (petals.size() >= MAX_PETALS) break;
      petals.add(new Petal(f.pos.x, f.pos.y, f.col));
    }
  }
}
