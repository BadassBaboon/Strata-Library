/**

 This buffer uses the result from the prev fluid solver buffers and draws
 nicely colored circles on it to visualize the fluid sim velocity field.

*/

// iq's integer hash function
float hash1( uint n ) 
{
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

// Today's hsv to rgb conversion brought to you by The Book of Shaders.
// https://thebookofshaders.com/06/
vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0., 4., 2.),
                             6.) - 3.) - 1., 0., 1.);
    rgb = rgb * rgb * (3. - 2. * rgb);
    return c.z * mix(vec3(1.), rgb, c.y);
}

// Distance from point p to the segment a-b. Used to paint ink along the cursor's
// inter-frame path so a fast cursor leaves a continuous trail instead of gaps.
float distToSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-9), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 stepSize = 1./iResolution.xy;
    vec4 vel = textureLod(iChannel0, uv, 0.);
    vec4 col = textureLod(iChannel1, uv - dt * vel.xy * stepSize * 3., 0.);
    vec2 mo = iMouse.xy / iResolution.xy;
    vec4 prevMouse = texelFetch(iChannel1, ivec2(0, 0), 0).xyzw;
    
    // Draw ink splat. Strata feeds the cursor with the button always "down", so unlike
    // Shadertoy (click-drag only) this runs every frame. We therefore inject only in
    // proportion to actual movement (so a still cursor never piles up dense halos) and
    // spread it along the whole path between frames (so a fast cursor stays attached
    // instead of leaving chopped-off blobs). The epsilon in the falloff removes the
    // 1/0 spike at the exact cursor that used to blow out to white.
    if (iMouse.z > 1. && prevMouse.z > 1.)
    {
        vec2 m0 = prevMouse.xy / iResolution.xy;
        vec2 m1 = mo;
        float amt = smoothstep(0.0, 0.02, length(m1 - m0));
        float d = distToSegment(uv, m0, m1);
        float hue = hash1(uint(iMouse.z + iResolution.x*abs(iMouse.w) + iTime));
        vec4 rgb = vec4(hsv2rgb(vec3(hue, 1., 1.)), 1.);
        col += amt * 4e-4 / pow(d + 3.*stepSize.x, 1.6) * rgb;
    }
    
    // color decay
    col = clamp(col, 0., 5.);
    col = max(col - (col * 8e-3), 0.);
    
    if (fragCoord.y < 1. && fragCoord.x < 1.)
    {
		col = iMouse;   
    }
    
    fragColor = col;
}