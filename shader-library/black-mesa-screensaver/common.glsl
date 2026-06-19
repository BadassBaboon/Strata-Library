// Adapted from IQ's sdf functions.
float cylinderDistance(vec3 point, vec3 a, vec3 b, float radius) {
  vec3  ba = b - a;
  vec3  pa = point - a;
  float baba = dot(ba, ba);
  float paba = dot(pa, ba);
  float x = length(pa * baba - ba * paba) - radius * baba;
  float y = abs(paba - baba * 0.5) - baba * 0.5;
  float x2 = x * x;
  float y2 = y * y * baba;
  float d = (max(x, y) < 0.0)
      ? -min(x2, y2)
      : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
  return sign(d) * sqrt(abs(d)) / baba;
}

float boxDistance(vec3 point, vec3 extents) {
  vec3 q = abs(point) - extents;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

mat4 rotateY(float angle) {
	float x = cos(angle);
    float y = sin(angle);
    return mat4(
        x, 0, y, 0,
        0, 1, 0, 0,
       -y, 0, x, 0,
        0, 0, 0, 1
	);
}

mat4 rotateZ(float angle) {
	float x = cos(angle);
    float y = sin(angle);
    return mat4(
        x, -y, 0, 0,
        y,  x, 0, 0,
        0,  0, 1, 0,
        0,  0, 0, 1
	);
}