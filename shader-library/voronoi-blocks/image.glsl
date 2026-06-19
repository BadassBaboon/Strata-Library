vec2 r2D(vec2 p)
{
    return vec2(fract(sin(dot(p, vec2(92.51, 65.19)))*4981.32),
                fract(sin(dot(p, vec2(23.34, 15.28)))*6981.32));
}

#define PI 3.141592

float polygon(vec2 p, float s)
{
    float a = ceil(s*(atan(-p.y, -p.x)/PI+1.)*.5);
    float n = 2.*PI/s;
    float t = n*a-n*.5;
    return mix(dot(p, vec2(cos(t), sin(t))), length(p), .3);
}

float voronoi(vec2 p, float s)
{
    vec2 i = floor(p*s);
    vec2 current = i + fract(p*s);
    float min_dist = 1.;
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            vec2 neighbor = i + vec2(x, y);
            vec2 point = r2D(neighbor);
            point = 0.5 + 0.5*sin(iTime*.5 + 6.*point);
            float dist = polygon(neighbor+point - current, 3.);
            min_dist = min(min_dist, dist);
        }
    }
    return min_dist;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y*2.-1.;
    vec2 e = vec2(.01, .0);
    
    float s = 2.;
    float vor = 1.-voronoi(uv, s);
    float dx = 1.-voronoi(uv-e.xy, s);
    float dy = 1.-voronoi(uv-e.yx, s);
    dx = (dx-vor)/e.x;
    dy = (dy-vor)/e.x;
    
    float t = iTime;
    vec3 n = normalize(vec3(dx, dy, 1.));
    vec3 lp = vec3(cos(t), sin(t), .5)*2.;
    vec3 ld = normalize(lp-vec3(uv, 0.));
    vec3 ed = normalize(vec3(0., .0, 1.)-vec3(uv, 0.));
    vec3 hd = normalize(ld + ed);
    float sl = pow(max(dot(hd,n), 0.),4.);
    float oc = clamp(pow((vor), 2.), 0., 1.);
    float amb = (1.-vor)*.5;
    float diff = max(dot(n, ld), 0.)*.75;
    float l = oc*diff+amb+sl;
    
    vec3 col = vec3(0.);
    col += l*texture(iChannel0, normalize(reflect(vec3(0., .0, 1.), n))).rgb;

    fragColor = vec4(col,1.0);
}