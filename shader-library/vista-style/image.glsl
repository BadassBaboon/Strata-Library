#define TIME (iTime * 0.125f * 0.5f)

struct Ring
{
    vec2 center;
    vec2 radius;
    vec3 color1;
    vec3 color2;
    float time;
};

vec3 glowingRing(vec2 p, Ring ring)
{      
    float T = ring.time;
    vec2 rad = ring.radius + cos(T*0.5 + vec2(0.3,1.0));

    float d = sdEllipse( p + ring.center, rad );   
    vec3 col = ring.color1;

    col *= exp(-2.5*abs(d));
    col = mix( col, ring.color2, 1.0-smoothstep(0.0,0.005,abs(d)) );
    
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.xy;
       
    vec3 c1 = vec3(189.0f, 151.0f, 100.0f) / 255.0f;
    vec3 c3 = vec3( 75.0f, 123.9f, 163.0f) / 255.0f;

    vec3 c2 = c1 + vec3(0.3f, 0.3f, 0.3f);
    vec3 c4 = c3 + vec3(0.3f, 0.3f, 0.3f);
    
    vec3 color1 = vec3(0.0f);
    vec3 color2 = vec3(0.0f);
    
    Ring ring;
    
    for (float i = 0.0f; i < 3.0f; i++)
    {
        float o = i * 0.1f;
        ring.center = vec2(-2.0f, cos(TIME*1.123)* -2.0f);
        ring.radius = vec2( 2.5f, 2.5f + cos(TIME));
        ring.color1 = c1;
        ring.color2 = c2;
        ring.time = o + TIME * 1.0f;
        color1 = max(color1, glowingRing(p, ring));
    }

    for (float i = 0.0f; i < 2.0f; i++)
    {
        float o = i * 0.1f;
        ring.center = vec2( sin(TIME)*2.0f, 2.0f);
        ring.radius = vec2( 2.5f+cos(TIME), 2.5f);
        ring.color1 = c3;
        ring.color2 = c4;
        ring.time = o + TIME * 1.131f + 17.0;
        color2 = max(color2, glowingRing(p, ring));
    }
    
    //Blend additively or with screen blending
    // fragColor = vec4(color1+color2 - color1*color2, 1.0);
    fragColor = vec4(mix(max(color1, color2), color1+color2, 0.75f), 1.0);
    
    float noise = (hash13(vec3(fragCoord.x, fragCoord.y, iTime)) - 0.5f) * 4.0f / 255.0f;
    fragColor += noise;
}