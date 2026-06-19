/*
An attempt to remake Tool's Fear Inoculum album cover.

Defines FEAR_DIST in buffer b and FEAR_BLUR can be commented out to remove lens distortion and blur respectively.

Any and all feedback is appreciated!

Reference: https://en.wikipedia.org/wiki/Fear_Inoculum

*/

float lerp( in float x, in float a, in float b )
{
    return (clamp(x, a, b) - a)/(b-a);
}

#define FEAR_BLUR
#define GAUSS_SIZE 8
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float ratio = iResolution.y / iResolution.x;
    vec2 uv = (fragCoord / iResolution.xy - vec2(0.5, 0.5)) * vec2(1.0, ratio);
    vec2 screen = fragCoord/iResolution.xy;
    
    #ifdef FEAR_BLUR
    
    vec3 tex = vec3(0.0);    
    // apply more blur radially, with the center around the "blue lightsource"
    float sigma_factor = smoothstep(0.0, 0.250, length(uv-vec2(0.0, -0.1)));
    
    // adapt sigma wrt screen resolution
    float sigma = sigma_factor * iResolution.x/350.0 + 0.1*(1.0 - sigma_factor);
    float G = 0.0;
    
    // Gaussian blur https://en.wikipedia.org/wiki/Gaussian_blur
    for (int i = -GAUSS_SIZE; i <= GAUSS_SIZE; i++)
    {
        for (int j = -GAUSS_SIZE; j <= GAUSS_SIZE; j++)
        {
            float x = float(i);
            float y = float(j);
            vec2 v = vec2(x, y) / iResolution.xy;
            
            float g = exp(- (x*x + y*y)/(2.0*sigma*sigma));
            
            G += g;
            
            tex += g * texture(iChannel0, screen + v).rgb;
            
        }
    }
    
    vec3 color = tex / G;
    #else
    vec3 color = texture(iChannel0, screen).rgb;
    #endif
    
    // slight tint around adges
    float radial_shadow = 1.0 - length(uv);
    radial_shadow *= radial_shadow;
    color *= lerp(radial_shadow, -0.5, 1.0);
    
    fragColor = vec4(color, 1.0);
}