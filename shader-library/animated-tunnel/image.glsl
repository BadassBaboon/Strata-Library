#define TAU 6.283185
#define STEPS 50u

float linstep(float a, float b, float x)
{
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord = (fragCoord * 2.0 - iResolution.xy) / iResolution.x;
    vec3 col = vec3(0.0);
    
    for(uint j = 0u; j < 3u; j++)
    {
        for(uint i = 0u; i < STEPS; i++)
        {
            float di = float(i) / float(STEPS - 1u);
            float dj = float(j) / 2.0;
            float t = iTime - pow(2.0, di + 2.0) + dj / 10.0;
            float a = pow((1.0 - cos(fract(t / 2.0) * TAU / 2.0)) / 2.0, 6.0) * TAU / 4.0;
            vec2 tc = mat2(cos(a), sin(a), -sin(a), cos(a)) * coord;
            float d = max(abs(tc.x), abs(tc.y));
            float th = 0.05 + sin(t * TAU / 2.0) * 0.01;
            float p = pow(1.0 - th * 2.0, float(i));
            float b = 2.0 / iResolution.x + 0.01 * di;
            float v = linstep(-b, b, d - (1.0 - th) * p) - linstep(-b, b, d - p);
            col[j] = max(col[j], v * d * 2.0);
        }
    }
    
    
    fragColor = vec4(col, 1.0);
}