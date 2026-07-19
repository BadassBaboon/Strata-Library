const ivec2 BOARD = ivec2(40, 22);

const int INITIAL_LENGTH = 7;
const int MAX_LENGTH = 32;
const int STEP_FRAMES = 6;

const ivec2 META_HEAD = ivec2(0, 0);
const ivec2 META_FOOD = ivec2(1, 0);
const float STATE_MARKER = 1.0;

uint hashUint(uint n)
{
  n ^= n >> 16U;
  n *= 0x7feb352dU;
  n ^= n >> 15U;
  n *= 0x846ca68bU;
  n ^= n >> 16U;
  return n;
}

float random01(uint seed)
{
  return float(hashUint(seed) & 0x00ffffffU) /
         16777216.0;
}

bool sameCell(ivec2 a, ivec2 b)
{
  return all(equal(a, b));
}

bool insideBoard(ivec2 p)
{
  return all(greaterThanEqual(p, ivec2(0))) &&
         all(lessThan(p, BOARD));
}

ivec2 stateTexel(ivec2 boardCell)
{
  // Texture row 0 is metadata.
  return boardCell + ivec2(0, 1);
}

vec2 encodePosition(ivec2 p)
{
  return (vec2(p) + 0.5) / vec2(BOARD);
}

ivec2 decodePosition(vec2 encoded)
{
  return clamp(
      ivec2(floor(encoded * vec2(BOARD))),
      ivec2(0),
      BOARD - 1
  );
}

int readLife(ivec2 p)
{
  if (!insideBoard(p))
      return 0;

  float encoded = texelFetch(
      iChannel0,
      stateTexel(p),
      0
  ).r;

  return int(floor(
      encoded * float(MAX_LENGTH) + 0.5
  ));
}

ivec2 directionVector(int direction)
{
  if (direction == 0) return ivec2( 1,  0);
  if (direction == 1) return ivec2( 0,  1);
  if (direction == 2) return ivec2(-1,  0);
  return ivec2(0, -1);
}

ivec2 initialHead()
{
  return ivec2(BOARD.x / 2, BOARD.y / 2);
}

bool isInitialSnakeCell(ivec2 p)
{
  ivec2 head = initialHead();
  int tailX = head.x - INITIAL_LENGTH + 1;

  return p.y == head.y &&
         p.x >= tailX &&
         p.x <= head.x;
}

int initialLife(ivec2 p)
{
  if (!isInitialSnakeCell(p))
      return 0;

  ivec2 head = initialHead();
  int tailX = head.x - INITIAL_LENGTH + 1;

  return p.x - tailX + 1;
}

ivec2 randomInitialFood()
{
  for (int attempt = 0; attempt < 32; ++attempt)
  {
      uint seed = 71317U + uint(attempt) * 7919U;

      int x = min(
          int(random01(seed) * float(BOARD.x)),
          BOARD.x - 1
      );

      int y = min(
          int(random01(seed + 12979U) * float(BOARD.y)),
          BOARD.y - 1
      );

      ivec2 candidate = ivec2(x, y);

      if (!isInitialSnakeCell(candidate))
          return candidate;
  }

  return ivec2(31, 6);
}

ivec2 randomEmptyFood(uint baseSeed, ivec2 newHead)
{
  for (int attempt = 0; attempt < 64; ++attempt)
  {
      uint seed =
          baseSeed +
          uint(attempt) * 747796405U;

      int x = min(
          int(random01(seed) * float(BOARD.x)),
          BOARD.x - 1
      );

      int y = min(
          int(random01(seed + 2891336453U) *
              float(BOARD.y)),
          BOARD.y - 1
      );

      ivec2 candidate = ivec2(x, y);

      if (!sameCell(candidate, newHead) &&
          readLife(candidate) == 0)
      {
          return candidate;
      }
  }

  // Guaranteed fallback search, beginning at a random index.
  int start = int(baseSeed % uint(BOARD.x * BOARD.y));

  for (int offset = 0; offset < 880; ++offset)
  {
      int index =
          (start + offset) %
          (BOARD.x * BOARD.y);

      ivec2 candidate = ivec2(
          index % BOARD.x,
          index / BOARD.x
      );

      if (!sameCell(candidate, newHead) &&
          readLife(candidate) == 0)
      {
          return candidate;
      }
  }

  return ivec2(0, 0);
}

void chooseGreedyMove(
  ivec2 head,
  ivec2 food,
  uint seed,
  out ivec2 nextHead,
  out int nextDirection
)
{
  ivec2 delta = food - head;

  int distanceX = abs(delta.x);
  int distanceY = abs(delta.y);

  if (distanceX == 0 && distanceY == 0)
  {
      nextDirection = 0;
      nextHead = head;
      return;
  }

  if (distanceX == 0)
  {
      nextDirection = delta.y > 0 ? 1 : 3;
  }
  else if (distanceY == 0)
  {
      nextDirection = delta.x > 0 ? 0 : 2;
  }
  else if (distanceX > distanceY)
  {
      nextDirection = delta.x > 0 ? 0 : 2;
  }
  else if (distanceY > distanceX)
  {
      nextDirection = delta.y > 0 ? 1 : 3;
  }
  else
  {
      // Both choices reduce Manhattan distance by one.
      if (random01(seed) < 0.5)
          nextDirection = delta.x > 0 ? 0 : 2;
      else
          nextDirection = delta.y > 0 ? 1 : 3;
  }

  nextHead = head + directionVector(nextDirection);
  nextHead = clamp(nextHead, ivec2(0), BOARD - 1);
}

void writeInitialState(ivec2 texel, out vec4 result)
{
  ivec2 head = initialHead();
  ivec2 food = randomInitialFood();

  if (sameCell(texel, META_HEAD))
  {
      // RG: head position
      // B: direction
      // A: snake length
      result = vec4(
          encodePosition(head),
          0.0,
          float(INITIAL_LENGTH) / float(MAX_LENGTH)
      );

      return;
  }

  if (sameCell(texel, META_FOOD))
  {
      // RG: food position
      // A: feedback-valid marker
      result = vec4(
          encodePosition(food),
          0.0,
          STATE_MARKER
      );

      return;
  }

  if (texel.y >= 1 && texel.y <= BOARD.y)
  {
      ivec2 boardCell = texel - ivec2(0, 1);
      int life = initialLife(boardCell);

      result = vec4(
          float(life) / float(MAX_LENGTH),
          0.0,
          0.0,
          1.0
      );

      return;
  }

  result = vec4(0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  ivec2 texel = ivec2(floor(fragCoord));

  bool stateArea =
      texel.x >= 0 &&
      texel.x < BOARD.x &&
      texel.y >= 0 &&
      texel.y <= BOARD.y;

  if (!stateArea)
  {
      fragColor = vec4(0.0);
      return;
  }

  vec4 previousFoodState = texelFetch(
      iChannel0,
      META_FOOD,
      0
  );

  bool feedbackIsValid =
      previousFoodState.a > 0.75;

  // This also handles recompilation at a nonzero iFrame.
  if (iFrame == 0 || !feedbackIsValid)
  {
      writeInitialState(texel, fragColor);
      return;
  }

  if ((iFrame % STEP_FRAMES) != 0)
  {
      fragColor = texelFetch(
          iChannel0,
          texel,
          0
      );

      return;
  }

  vec4 previousHeadState = texelFetch(
      iChannel0,
      META_HEAD,
      0
  );

  ivec2 head = decodePosition(
      previousHeadState.xy
  );

  ivec2 food = decodePosition(
      previousFoodState.xy
  );

  int length = int(floor(
      previousHeadState.a *
      float(MAX_LENGTH) + 0.5
  ));

  ivec2 nextHead;
  int nextDirection;

  chooseGreedyMove(
      head,
      food,
      uint(iFrame) * 1664525U + 1013904223U,
      nextHead,
      nextDirection
  );

  bool ateFood = sameCell(nextHead, food);
  bool growing =
      ateFood && length < MAX_LENGTH;

  int nextLength =
      growing ? length + 1 : length;

  ivec2 nextFood = food;

  if (ateFood)
  {
      nextFood = randomEmptyFood(
          uint(iFrame) * 277803737U + 1171808521U,
          nextHead
      );
  }

  if (sameCell(texel, META_HEAD))
  {
      fragColor = vec4(
          encodePosition(nextHead),
          float(nextDirection) / 3.0,
          float(nextLength) / float(MAX_LENGTH)
      );

      return;
  }

  if (sameCell(texel, META_FOOD))
  {
      fragColor = vec4(
          encodePosition(nextFood),
          0.0,
          STATE_MARKER
      );

      return;
  }

  ivec2 boardCell = texel - ivec2(0, 1);
  int life = readLife(boardCell);

  if (!growing)
      life = max(life - 1, 0);

  // Self-collision is intentionally ignored.
  if (sameCell(boardCell, nextHead))
      life = nextLength;

  fragColor = vec4(
      float(life) / float(MAX_LENGTH),
      0.0,
      0.0,
      1.0
  );
}