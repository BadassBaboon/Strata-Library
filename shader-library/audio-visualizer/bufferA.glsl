//settings

#define volLo 0.0
#define volHi 0.6
#define bassMalus 0.3
#define bassWiggleStart 0.7
#define bassWiggleStrength 0.03

#define samples 12

#define baseSize 0.4
#define ringSize 0.03
#define outerGrowth 0.1
#define innerGrowth 0.3

#define colorDistortion 0.025
#define colorDistortionSmooth 0.02

#define downSampleSteps 220


const float pi = 3.14159265359;
float volMin = 0.3;
float volMax = 0.0;
struct Spectrum
{
    float s[samples];
};

vec3 map(float v, float edge, vec3 c1, vec3 c2, float t)
{
    float m = t / iResolution.x;
    float d = v-edge;
    float a = abs(d);
    if(a <= m)
    {
        float b = ((d + m) * 0.5) / m;
        return mix(c1, c2, smoothstep(0.0, 1.0, b));
    }
    else if ( d < 0.0)
        return c1;
    else
        return c2;
}
void downSampled(out Spectrum res)
{
    
    const int steps = downSampleSteps;
    const int sps = steps / samples;
    res;
    float s = 1.0 / float(steps);
    for(int j = 0; j < samples; j++)
    {
        for(int i = 0; i < sps; i++)
        {
            res.s[j] += texture(iChannel0, vec2(float(j * sps + i) * s, 0.25)).x;
            
        }
        float n = sqrt(float(j) / float(samples));
        float k = (1.0 - bassMalus) + n * bassMalus;
        res.s[j] = (res.s[j] / float(sps)) * k;
        if(res.s[j] < volMin)
            volMin = res.s[j];
        if(res.s[j] > volMax)
            volMax = res.s[j];
    }
    volMin = max(volLo, volMin);
    volMax = max(volHi, volMax);
    for(int j = 0; j < samples; j++)
    {
        res.s[j] = pow(smoothstep(volMin, volMax, res.s[j]), 2.0);
    }
}
float getSample(Spectrum s, float v)
{
    float at = max(0.0, v * float(samples));
    int k = int(at);
    float f = fract(at);
    float a = 0.0;
    for(int i = 0; i < samples + 1; i++)
    {
        if(i == k)
        {
            a = s.s[i];
        }
        else if(i == k + 1)
        {
            return mix(a, s.s[i], smoothstep(0.0, 1.0, f));
        }
    }
    return s.s[samples-1];
}
float avgFrq(float from, float to)
{
    float st = (to - from) / 3.0;
    float s = texture(iChannel0, vec2(from, 0.25)).x +
                  texture(iChannel0, vec2(from + st, 0.25)).x +
                  texture(iChannel0, vec2(from + st * 2.0, 0.25)).x +
                  texture(iChannel0, vec2(from + st * 3.0, 0.25)).x;
    return s * 0.25;
}
float normalizeAngle(float a)
{
    if(a > pi * 0.5)
        a = pi - a;
    if(a < -pi * 0.5)
        a = - pi - a;
    return 1.0 - ((a / (pi * 0.5)) + 1.0) * 0.5;
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float bass = avgFrq(0.0, 0.1);
    float s1 = min(pow((avgFrq(volLo, volHi) + bass) * 0.5, 8.0) * 10.0, 1.0);
    
    float wiggle =  max(0.0, bass - bassWiggleStart) * bassWiggleStrength;
    vec2 uv = (fragCoord.xy / iResolution.xy) + vec2(sin(iTime * 180.0), cos(iTime * 173.0)) * wiggle;
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 p = uv * ar;
    p = p * 2.0 - ar;
    float angle = atan(p.y, p.x);
    float angle2 = angle - pi * 0.25;
    angle = normalizeAngle(angle);
    angle2 = normalizeAngle(angle2);
    float d = length(p);
    vec3 bg = vec3(0.0, 0.0, 0.0);
    
    Spectrum ds;
    downSampled(ds);
    
    
    float so = getSample(ds, angle);
    float shadowIntens = 6.0;
   	float minCol = 0.02;
    float maxCol = 0.2;
    float innerBorder = s1 * innerGrowth * 0.7 * 0.3 + baseSize * 0.3;
    float outerBorder = s1 * innerGrowth * 0.7 + baseSize;
    vec3 sub = vec3(s1*0.2 * sqrt(d));
    vec3 grad1 = vec3(0.01) + vec3(minCol + max(0.0, (0.5 - angle2)) * maxCol) * 2.0 * (pow(d / innerBorder, 2.0)) - sub;
    vec3 grad2 = vec3(0.01) + vec3(minCol + max(0.0, (angle2 - 0.5)) * maxCol) * 2.0 * (d / outerBorder) - sub;
    
    float cds = colorDistortionSmooth * iResolution.x;
    vec3 col1 = grad1;
    float ring = ringSize + ringSize * sqrt(s1);
    col1 = map(d, innerBorder, col1, grad2, 0.004 * iResolution.x); 
    col1 = map(d, outerBorder, col1, vec3(1.0), 0.003 * iResolution.x); 
    col1 = map(d, s1 * innerGrowth + baseSize + ring + so * (outerGrowth), col1 , vec3(1.0, 1.0, 0.0), 2.0 + so * cds);
    col1 = map(d, s1 * innerGrowth + baseSize + ring + so * (outerGrowth + colorDistortion), col1 , vec3(1.0, 0.0, 0.0), 2.0 + so * cds);
    col1 = map(d, s1 * innerGrowth + baseSize + ring + so * (outerGrowth + colorDistortion * 2.0), col1 , vec3(0.0, 0.0, 1.0), 2.0 + so * cds);
    col1 = map(d, s1 * innerGrowth + baseSize + ring + so * (outerGrowth + colorDistortion * 3.0), col1 , vec3(0.0, 1.0, 0.0), 2.0 + so * cds);
    col1 = map(d, s1 * innerGrowth + baseSize + ring - 0.002 + so * (outerGrowth + colorDistortion * 4.0), col1 , bg, 2.0 + so * cds);
    
    float m = 1.0;
    for(int i = 0; i < 3; i++)
    {
        if(m < col1[i])
            m = col1[i];
    }
    if(m > 0.0)
    {
        m = 1.0 / m;
        col1.x *= m;
        col1.y *= m;
        col1.z *= m;
    }
    if(wiggle <= 0.0)
		fragColor = vec4(col1, 1.0);
    else
        fragColor = mix(texture(iChannel1, (fragCoord.xy / iResolution.xy)), vec4(col1, 1.0), 0.8);
}