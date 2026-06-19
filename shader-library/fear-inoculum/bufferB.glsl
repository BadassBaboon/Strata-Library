#define FEAR_DIST
// https://nullprogram.com/blog/2018/07/31/
uint hash(uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}
// lens distortion with wavelength bias
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv  = fragCoord / iResolution.xy;
#ifdef FEAR_DIST
    
    // direct distortion radially 
    float ratio = iResolution.y / iResolution.x;
    vec2 of  = (uv - vec2(0.5, 0.5) - vec2(0.0, -0.2)) * vec2(1.0, ratio) / iResolution.xy;
    float rad = length(of*iResolution.xy);
    of *= -iResolution.x/190.0 * smoothstep(0.0, 0.3, rad);
    
    // apply more distortion towards the highlighted areas
    of *= 1.0 - smoothstep(0.5, 1.5, uv.x); // slight left-bias
    of *= 1.0 - smoothstep(0.5, 1.5, uv.y); // slight down-bias
    
    // apply some grain
    uint u = uint(fragCoord.x * iResolution.y);
    uint v = uint(fragCoord.y);
    uint h = hash(u + v);
    float hf = float(h);
    float hx = mod(hf, 1000.0) / 1000.0;
    float hy = mod(hf / 1000.0, 1000.0) / 1000.0;
    vec2 gof = iResolution.x * 0.001 * vec2(hx, hy) / iResolution.xy;
    
    // sample texture with increasing offset
    vec4 t1  = texture(iChannel0, uv + 5.0 * of + gof);
    vec4 t4  = texture(iChannel0, uv + 10.0 * of + gof);
    vec4 t16 = texture(iChannel0, uv + 15.0 * of + gof);
    
    float red = t1.r;
    float green = t4.g;
    float blue = t16.b;
    
    fragColor = vec4(red, green, 1.1*blue, 1.0);
#else
    fragColor = texture(iChannel0, uv);
#endif
}