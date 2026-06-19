#define PI 3.141596


vec3 a = vec3(0.5, 0.5, 0.5);
vec3 b = vec3(0.5, 0.5, 0.5);
vec3 c = vec3(1.0, 1.0, 1.0);
vec3 d = vec3(0.00, 0.33, 0.67);

// iq color mapper
vec3 colorMap(float t) {
	return (a + b * cos(2. * PI * (c * t + d)));
}

void mainImage(out vec4 o, in vec2 i)
{
    vec2 uv = i / iResolution.xy;
    uv -= 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    
    float ring = 1.5 + 0.8 * sin(PI * 0.25 * iTime);
    
    float kr = 0.5 - 0.5 * cos(7. * PI * r); 
    vec3 kq = 0.5 - 0.5 * sin(ring*vec3(30., 29.3, 28.6) * r - 6.0 * iTime + PI * vec3(-0.05, 0.5, 1.0));
    vec3 c = kr * (0.1 + kq * (1. - 0.5* colorMap(a / PI))) * (0.5 + 0.5 * sin(11.*a + 22.5*r));

    // Output to screen
    o.rgb = mix(vec3(0.0, 0.0, 0.2), c, 0.85);
}