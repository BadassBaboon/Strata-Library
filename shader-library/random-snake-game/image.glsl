// Assisted by GPT-5.5
const ivec2 BOARD = ivec2(40, 22);
const int MAX_LENGTH = 32;

const ivec2 META_HEAD = ivec2(0, 0);
const ivec2 META_FOOD = ivec2(1, 0);

bool sameCell(ivec2 a, ivec2 b)
{
  return all(equal(a, b));
}

ivec2 stateTexel(ivec2 cell)
{
  return cell + ivec2(0, 1);
}

ivec2 decodePosition(vec2 encoded)
{
  return clamp(
      ivec2(floor(encoded * vec2(BOARD))),
      ivec2(0),
      BOARD - 1
  );
}

int lifeAt(ivec2 cell)
{
  if (any(lessThan(cell, ivec2(0))) ||
      any(greaterThanEqual(cell, BOARD)))
  {
      return 0;
  }

  float encoded = texelFetch(
      iChannel0,
      stateTexel(cell),
      0
  ).r;

  return int(floor(
      encoded * float(MAX_LENGTH) + 0.5
  ));
}

float boxMask(vec2 p, vec2 halfSize)
{
  vec2 d = abs(p) - halfSize;
  return 1.0 - step(0.0, max(d.x, d.y));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  float cellSize = floor(min(
      (iResolution.x - 36.0) / float(BOARD.x),
      (iResolution.y - 36.0) / float(BOARD.y)
  ));

  cellSize = max(cellSize, 2.0);

  vec2 boardPixels = vec2(BOARD) * cellSize;
  vec2 origin = floor(
      (iResolution.xy - boardPixels) * 0.5
  );

  vec2 local = fragCoord - origin;

  bool inside =
      local.x >= 0.0 &&
      local.y >= 0.0 &&
      local.x < boardPixels.x &&
      local.y < boardPixels.y;

  vec3 outsideA   = vec3(0.020, 0.027, 0.025);
  vec3 outsideB   = vec3(0.027, 0.037, 0.032);

  vec3 frameBlack = vec3(0.008, 0.014, 0.012);
  vec3 frameDark  = vec3(0.075, 0.120, 0.092);
  vec3 frameLight = vec3(0.335, 0.505, 0.265);

  vec3 boardDark  = vec3(0.035, 0.065, 0.047);
  vec3 boardLight = vec3(0.043, 0.079, 0.055);
  vec3 gridColor  = vec3(0.018, 0.032, 0.027);

  vec3 snakeEdge  = vec3(0.045, 0.135, 0.060);
  vec3 snakeBody  = vec3(0.310, 0.720, 0.180);
  vec3 snakeTop   = vec3(0.635, 0.940, 0.285);
  vec3 snakeHead  = vec3(0.720, 1.000, 0.320);

  vec3 appleDark  = vec3(0.490, 0.055, 0.045);
  vec3 appleRed   = vec3(0.950, 0.160, 0.090);
  vec3 appleLight = vec3(1.000, 0.510, 0.220);
  vec3 leafGreen  = vec3(0.300, 0.720, 0.190);

  ivec2 backgroundCell =
      ivec2(floor(fragCoord / 6.0));

  float backgroundPattern = mod(
      float(backgroundCell.x + backgroundCell.y),
      2.0
  );

  vec3 color = mix(
      outsideA,
      outsideB,
      backgroundPattern
  );

  if (inside)
  {
      vec2 gridPosition = local / cellSize;
      ivec2 cell = ivec2(floor(gridPosition));
      vec2 cellUV = fract(gridPosition);
      vec2 p = cellUV - 0.5;

      vec4 headState = texelFetch(
          iChannel0,
          META_HEAD,
          0
      );

      vec4 foodState = texelFetch(
          iChannel0,
          META_FOOD,
          0
      );

      ivec2 head = decodePosition(headState.xy);
      ivec2 food = decodePosition(foodState.xy);

      int direction = int(floor(
          headState.z * 3.0 + 0.5
      ));

      int life = lifeAt(cell);

      float checker = mod(
          float(cell.x + cell.y),
          2.0
      );

      color = mix(
          boardDark,
          boardLight,
          checker
      );

      // One-pixel grid gaps.
      float gap = min(
          1.0 / cellSize,
          0.12
      );

      float boardTile = boxMask(
          p,
          vec2(0.5 - gap)
      );

      color = mix(
          gridColor,
          color,
          boardTile
      );

      if (life > 0)
      {
          // Every segment is an independent square.
          float shadow = boxMask(
              p + vec2(0.055, -0.065),
              vec2(0.355)
          );

          color = mix(
              color,
              frameBlack,
              shadow * 0.75
          );

          float outline = boxMask(
              p,
              vec2(0.385)
          );

          color = mix(
              color,
              snakeEdge,
              outline
          );

          float body = boxMask(
              p,
              vec2(0.315)
          );

          float tailRatio = clamp(
              float(life) /
              max(headState.a * float(MAX_LENGTH), 1.0),
              0.0,
              1.0
          );

          vec3 bodyColor = mix(
              vec3(0.180, 0.500, 0.135),
              snakeBody,
              tailRatio
          );

          color = mix(
              color,
              bodyColor,
              body
          );

          // Simple top-left pixel highlight.
          float highlight = boxMask(
              p - vec2(-0.10, 0.175),
              vec2(0.135, 0.045)
          );

          color = mix(
              color,
              snakeTop,
              highlight * body
          );
      }

      if (sameCell(cell, head))
      {
          float headOutline = boxMask(
              p,
              vec2(0.445)
          );

          color = mix(
              color,
              snakeEdge,
              headOutline
          );

          float headFill = boxMask(
              p,
              vec2(0.375)
          );

          color = mix(
              color,
              snakeHead,
              headFill
          );

          float forehead = boxMask(
              p - vec2(-0.10, 0.255),
              vec2(0.155, 0.045)
          );

          color = mix(
              color,
              vec3(0.875, 1.000, 0.480),
              forehead * headFill
          );

          vec2 forward;

          if (direction == 0)
              forward = vec2(1.0, 0.0);
          else if (direction == 1)
              forward = vec2(0.0, 1.0);
          else if (direction == 2)
              forward = vec2(-1.0, 0.0);
          else
              forward = vec2(0.0, -1.0);

          vec2 side = vec2(
              -forward.y,
              forward.x
          );

          vec2 eyeBase = forward * 0.175;

          vec2 eyeA =
              eyeBase + side * 0.175;

          vec2 eyeB =
              eyeBase - side * 0.175;

          float eyes = max(
              boxMask(p - eyeA, vec2(0.065)),
              boxMask(p - eyeB, vec2(0.065))
          );

          color = mix(
              color,
              frameBlack,
              eyes * headFill
          );

          // Tiny white eye reflections.
          vec2 reflectionOffset =
              vec2(-0.018, 0.020);

          float reflections = max(
              boxMask(
                  p - eyeA - reflectionOffset,
                  vec2(0.017)
              ),
              boxMask(
                  p - eyeB - reflectionOffset,
                  vec2(0.017)
              )
          );

          color = mix(
              color,
              vec3(0.920, 1.000, 0.765),
              reflections * eyes
          );
      }

      if (sameCell(cell, food))
      {
          vec2 appleP = p;

          float fruitShadow = boxMask(
              appleP + vec2(0.0, 0.285),
              vec2(0.255, 0.050)
          );

          color = mix(
              color,
              frameBlack,
              fruitShadow * 0.75
          );

          float leftHalf = boxMask(
              appleP + vec2(0.105, 0.025),
              vec2(0.205, 0.235)
          );

          float rightHalf = boxMask(
              appleP - vec2(0.105, -0.025),
              vec2(0.205, 0.235)
          );

          float apple = min(
              leftHalf + rightHalf,
              1.0
          );

          color = mix(
              color,
              appleRed,
              apple
          );

          float bottomShade = boxMask(
              appleP + vec2(0.0, 0.190),
              vec2(0.220, 0.060)
          );

          color = mix(
              color,
              appleDark,
              bottomShade * apple
          );

          float fruitHighlight = boxMask(
              appleP - vec2(-0.145, 0.095),
              vec2(0.050, 0.080)
          );

          color = mix(
              color,
              appleLight,
              fruitHighlight * apple
          );

          float stem = boxMask(
              appleP - vec2(0.025, 0.310),
              vec2(0.035, 0.105)
          );

          float leaf = boxMask(
              appleP - vec2(0.145, 0.335),
              vec2(0.120, 0.050)
          );

          color = mix(
              color,
              vec3(0.250, 0.380, 0.100),
              stem
          );

          color = mix(
              color,
              leafGreen,
              leaf
          );
      }
  }
  else
  {
      vec2 boardEnd = origin + boardPixels;

      vec2 outsideVector = max(
          origin - fragCoord,
          fragCoord - boardEnd
      );

      float distanceToBoard = max(
          outsideVector.x,
          outsideVector.y
      );

      if (distanceToBoard < 2.0)
          color = frameBlack;
      else if (distanceToBoard < 6.0)
          color = frameLight;
      else if (distanceToBoard < 11.0)
          color = frameDark;
      else if (distanceToBoard < 14.0)
          color = frameBlack;
  }

  // Subtle, stable scanlines.
  float scanline = mix(
      0.970,
      1.0,
      step(0.5, fract(fragCoord.y * 0.5))
  );

  color *= scanline;

  // Small palette quantization reinforces pixel-art shading.
  color = floor(color * 48.0 + 0.5) / 48.0;

  fragColor = vec4(
      max(color, 0.0),
      1.0
  );
}