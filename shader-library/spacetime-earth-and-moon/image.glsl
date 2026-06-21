// Sine-free hash (Dave Hoskins, "Hash without Sine"). The original fract(sin(dot()))
// hash loses fp32 precision on the DX12/HLSL backend, producing seams and a "sliced /
// pixelated" look. This integer-style hash is stable across GPUs.
float hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(i + vec2(0.0, 0.0)), hash2(i + vec2(1.0, 0.0)), u.x),
               mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm2D(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise2(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

mat2 rot(float a){
    float s=sin(a),c=cos(a);
    return mat2(c,-s,s,c);
}

// iq https://www.shadertoy.com/view/llj3Rz
const vec4 sph1 = vec4( 0.0, 0.0, 0.0, 1.0 );
float map( in vec3 p )
{
    vec2 r = p.xz - sph1.xz;
    float h = 1.0-2.0/(1.0+0.3*dot(r,r));
    return p.y - h;
}

float Getdist(vec3 p, vec2 m, out float mat){
    vec3 sharpos = vec3(0.0, 0.3, 0.0);
    vec3 sharpos1 = vec3(0.0, 0.55, 0.0);
    sharpos1.xz += vec2(sin(iTime * 0.1), cos(iTime * 0.1)) * 4.0;
    
    float radius = 0.9;
    float radius1 = 0.25;
    
    float s = length(p - sharpos) - radius;   
    float s2 = length(p - sharpos1) - radius1; 
     
    float i = s;
    mat = 1.0;
    
    if(s2 < i){
        i = s2;
        mat = 3.0;
    }
    return i;
}


float raymarch(vec3 ro,vec3 rd,vec2 m,out float mat,out float glow){
    float d = 0.0;  

    for(int i = 0;i<100;i++){
        vec3 p = ro+rd*d;
        float ds = Getdist(p,m,mat);
        float a = map(p);
        d += ds*0.85;
        if(mat == 1.0){
           glow += 1.0 / (max(0.0, ds*0.01) + 0.05); 
        }
        if(d > 100.0 || ds < 0.001) break;
    }
    return d;
}

vec3 GetNormal(vec3 p, vec2 m) {
    float dummyMat; 
    float d = Getdist(p, m, dummyMat);
    vec2 e = vec2(.01, 0.0);
    
    vec3 n = d - vec3(
         Getdist(p - e.xyy, m, dummyMat),
         Getdist(p - e.yxy, m, dummyMat),
         Getdist(p - e.yyx, m, dummyMat)
    );
         
    return normalize(n);
}

float GetLight(vec3 p, vec2 m) {
    vec3 lightPos = vec3(0.0, 2.0, 6.0);
    float glow = 0.0;
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p, m);
    
    float dif = clamp(dot(n, l), 0.0, 1.0);
    
    float shadowMat;
    float d = raymarch(p + n * 0.02, l, m, shadowMat,glow);
    
    if(d < length(lightPos - p)) dif *= 0.01;
    
    return dif;
}


vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

float getTriplanarNoise(vec3 p, float scale, vec2 offset) {
    vec3 n = abs(normalize(p)); 
    
    float xPlanar = fbm2D(p.yz * scale + offset);
    float yPlanar = fbm2D(p.xz * scale + offset);
    float zPlanar = fbm2D(p.xy * scale + offset);
    
    return (xPlanar * n.x + yPlanar * n.y + zPlanar * n.z) / (n.x + n.y + n.z);
}

vec3 earth(vec3 p) {
    float landTime = iTime * 0.05;
    vec3 landP = p;
    landP.xz *= rot(landTime);
    
    float h = getTriplanarNoise(landP, 2.5, vec2(0.0)) - 0.45; 
    
    vec3 deepWater = vec3(0.03, 0.1, 0.4); 
    vec3 shallow   = vec3(0.005, 0.2, 0.35);   
    vec3 beach     = vec3(0.82, 0.72, 0.52); 
    vec3 grass     = vec3(0.12, 0.45, 0.12); 
    vec3 mountain  = vec3(0.35, 0.3, 0.25);  
    vec3 snow      = vec3(0.95, 0.95, 0.95); 
    
    vec3 terrainCol = vec3(0.0);
    
    if (h < -0.1) {
        terrainCol = mix(deepWater, shallow, smoothstep(-0.5, -0.1, h));
    } else if (h < -0.05) {
        terrainCol = mix(shallow, beach, smoothstep(-0.1, -0.5, h));
    } else if (h < 0.15) {
        terrainCol = mix(beach, grass, smoothstep(-0.3, 0.15, h));
    } else if (h < 0.45) {
        terrainCol = mix(grass, mountain, smoothstep(0.15, 0.45, h));
    } else {
        terrainCol = mix(mountain, snow, smoothstep(0.45, 0.6, h));
    }
    
    terrainCol *= 0.85 + 0.15 * getTriplanarNoise(landP, 30.0, vec2(0.0));
    
    float cloudTime = iTime * 0.08;
    vec3 cloudP = p;
    cloudP.xz *= rot(cloudTime);
    
    vec2 wrap = vec2(
        getTriplanarNoise(cloudP, 4.0, vec2(1.0, 2.0)),
        getTriplanarNoise(cloudP.zyx, 4.0, vec2(3.0, 4.0))
    ) * 1.3;
    
    float cloudNoise = getTriplanarNoise(cloudP + vec3(wrap.x, 0.0, wrap.y), 10.0, vec2(0.0));
    
    float clouds = smoothstep(0.35, 0.65, cloudNoise);
    
    vec3 cloudColor = vec3(0.95, 0.95, 1.0);
    
    vec3 finalCol = mix(terrainCol, cloudColor, clouds * 1.0); 
    
    return finalCol;
}
vec3 moon(vec3 p){
    vec3 moonPos = vec3(0.0, 0.5, 0.0);
    moonPos.xz += vec2(sin(iTime * 0.1), cos(iTime * 0.1)) * 4.0;
    
    vec3 localP = p - moonPos;
    localP.xz *= rot(iTime * 0.05); 
    
    vec3 mariaCol   = vec3(0.12, 0.13, 0.15); 
    vec3 highland   = vec3(0.55, 0.53, 0.50); 
    vec3 craterRims = vec3(0.80, 0.80, 0.82); 
    
    float h = getTriplanarNoise(localP, 4.0, vec2(0.0));
    
    vec3 mooncol = mix(mariaCol, highland, smoothstep(0.1, 0.6, h));
    
    float craters = getTriplanarNoise(localP, 18.0, vec2(5.2, 1.3));
    float craterMask = smoothstep(0.2, 0.72, craters);
    
    mooncol = mix(mooncol, craterRims, craterMask * 0.6);
    
    float detailNoise = getTriplanarNoise(localP, 60.0, vec2(0.0));
    mooncol *= 0.7 + 0.4 * detailNoise;
    
    return mooncol;
}


float get3dCubeStars(vec3 rd) {
    vec3 absRd = abs(rd);
    float maxAxis = max(absRd.x, max(absRd.y, absRd.z));
    
    vec2 uv = vec2(0.0);
    vec3 sectorId = vec3(0.0);
    
    if (maxAxis == absRd.x) {
        uv = rd.yz / rd.x;
        sectorId = vec3(sign(rd.x), 0.0, 0.0);
    } else if (maxAxis == absRd.y) {
        uv = rd.xz / rd.y;
        sectorId = vec3(0.0, sign(rd.y), 0.0);
    } else {
        uv = rd.xy / rd.z;
        sectorId = vec3(0.0, 0.0, sign(rd.z));
    }
    
    vec2 p = uv * 35.0; 
    vec2 cellId = floor(p);
    vec2 gv = fract(p) - 0.5;
    
    vec2 finalId = cellId + sectorId.xy + sectorId.zz * 15.1;
    float h = hash2(finalId);
    
    float star = 0.0;
    
    if(h > 0.88) {
        vec2 offset = vec2(hash2(finalId + 0.35), hash2(finalId + 0.72)) - 0.5;
        offset *= 0.6;
        
        float d = length(gv - offset);
        float size = 0.25 + hash2(finalId * 1.5) * 0.08;
        star = exp(-35.0 * d / size);
        
        float twinkleSpeed = 0.3 + h * 0.8; 
        
        float twinkle = sin(iTime * twinkleSpeed + h * 6.28) * 0.5 + 0.5;
        star *= mix(0.6, 1.0, twinkle);
    }
    return star;
}

vec3 fastCubeStars(vec3 rd) {
    float totalStars = get3dCubeStars(rd);
    return vec3(0.7, 0.85, 1.0) * totalStars * 100.5;
}

vec3 tyman(vec3 rd){
    vec3 stars = fastCubeStars(rd);
    
    vec3 warpedRd = rd + sin(rd.zxy * 3.0 ) * 0.2;
    
    float nebulaNoise = getTriplanarNoise(warpedRd, 6.5, vec2(0.0));
    float gasMask = smoothstep(0.38, 0.7, nebulaNoise);
    
    vec3 color1 = vec3(0.35, 0.08, 0.55); 
    vec3 color2 = vec3(0.08, 0.45, 0.65); 
    
    vec3 nebula = mix(color1, color2, nebulaNoise);
    nebula *= gasMask * 0.9; 
    
    return nebula + stars;
}

float GridHeight(vec2 xz)
{
    vec3 earthPos = vec3(0.0,0.3,0.0);
    vec3 moonPos = vec3(0.0,0.55,0.0);
    moonPos.xz += vec2(sin(iTime * 0.1), cos(iTime * 0.1)) * 4.0;
    
    float d1 = length(xz - earthPos.xz);
    float d2 = length(xz - moonPos.xz);

    float h1 = 0.79 - 2.0/(1.0+0.2*d1*d1);
    float h2 = 0.15 - 0.6/(1.0+0.6*d2*d2);

    return 0.45+h1+h2;
}

vec3 renderScene(vec2 uv, vec3 ro, vec3 target, vec2 m) {
    vec3 rd = normalize(R(uv, ro, target, 1.2)); 

    vec3 col = tyman(rd);
    vec3 sunPos = vec3(0.0, 2.0, 6.0);
    float mat;
    float glow = 0.0;
    float d_planets = raymarch(ro, rd, m, mat,glow);
    col += vec3(0.2,0.35,0.5)*glow*0.001;
    float tmax = 20.0; 
    
    if(d_planets < 20.0){
        vec3 p = ro + rd * d_planets;
        float dif = GetLight(p, m);
        tmax = d_planets; 
        
        if(mat == 1.0){
            vec3 earthColor = earth(p);
            vec3 spherepos = vec3(0.0, 0.3, 0.0);
            vec3 nor = normalize(p - spherepos); 
            
            float lightIntensity = clamp(dif, 0.0, 1.0) + 0.03; 
            vec3 finalEarth = earthColor * lightIntensity;
            
            float fresnel = clamp(1.0 + dot(nor, rd), 0.0, 1.0);
            fresnel = pow(fresnel, 4.0);
            vec3 atmosphereColor = vec3(0.3, 0.65, 0.95);
 
            col = mix(finalEarth, atmosphereColor, fresnel * 1.7);
            col += atmosphereColor * fresnel * 1.5 * clamp(dif, 0.0, 1.0);
        }

        if(mat == 3.0){
            float lightIntensity = clamp(dif, 0.0, 1.0) + 0.02;
            col = moon(p) * 2.1 * lightIntensity;
        }
    }
    
    float t_grid = 0.0;

    for(int i=0;i<64;i++)
    {
        vec3 p = ro + rd*t_grid;

        float h = GridHeight(p.xz);

        float d = p.y - h;

        if(abs(d) < 0.001)
            break;

        t_grid += d*0.5;
    }
    
    if(t_grid > 0.0 && t_grid < tmax) {
        vec3 p_grid = ro + rd * t_grid;
        
        vec3 Lgrid = normalize(sunPos - p_grid);

        float shadowMat;
        float shadowDist = raymarch(
            p_grid + vec3(0.0,0.05,0.0),
            Lgrid,
            m,
            shadowMat,glow
        );

        float shadowFactor = 1.0;

        if(shadowDist < length(sunPos - p_grid))
        {
            shadowFactor = .2;
        }
        
        vec3 sharpos = vec3(0.0, 0.3, 0.0);
        vec3 sharpos1 = vec3(0.0, 0.2, 0.0);
        sharpos1.xz += vec2(sin(iTime * 0.1), cos(iTime * 0.1)) * 4.0;
        
        float distToEarth = length(p_grid.xz - sharpos.xz);
        float distToMoon  = length(p_grid.xz - sharpos1.xz);
        
        vec2 distortion = vec2(0.0);
        
        float earthWarp = min(0.25, 0.6 / (distToEarth + 0.15));
        float moonWarp  = min(0.12, 0.3 / (distToMoon  + 0.1));

        distortion += normalize(p_grid.xz - sharpos.xz)  * earthWarp;
        distortion += normalize(p_grid.xz - sharpos1.xz) * moonWarp;
        
        vec2 warpedXZ = p_grid.xz - distortion;
        // iq https://www.shadertoy.com/view/llj3Rz
        vec2 scp = sin(2.0 * 3.1415 * warpedXZ * 1.6); 
        
        vec3 wir = vec3(0.0, 0.5, 0.5);
        
        float lines = 0.0;
        lines += 1.0 * exp(-12.0 * abs(scp.x));
        lines += 1.0 * exp(-12.0 * abs(scp.y));
        lines += 0.5 * exp(-4.0 * abs(scp.x));
        lines += 0.5 * exp(-4.0 * abs(scp.y));
        
        float gridFog = exp(-0.01 * t_grid * t_grid);
        
        float gravityGlow = (1.0 / (distToEarth + 0.4)) + (0.5 / (distToMoon + 0.3));
        wir += vec3(0.5, 0.8, 1.0) * gravityGlow * 0.3;
        
        col += wir * lines * shadowFactor * gridFog;
    }
    
    float fogFactor = 1.0 - exp(-0.0003 * d_planets * d_planets * d_planets);
    if(d_planets > 20.0) fogFactor = 0.0; 
    col = mix(col, vec3(0.0), fogFactor);
    
    vec3 sunDir = normalize(vec3(0.0,3.0,10.0));
    // iq https://www.shadertoy.com/view/llj3Rz
    float sun = clamp( dot(rd,sunDir), 0.0, 1.0 );
    col += 0.4*pow(sun,12.0)*vec3(1.0,0.7,0.6)*2.0;
    col += 0.4*pow(sun,64.0)*vec3(1.0,0.9,0.8)*2.0;
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 m = iMouse.xy/iResolution.y;
    vec3 target = vec3(0,0.8,0);
    vec3 ro = vec3(0,0.5,4.3);
    
    float autoRotation = 2.2+iTime * 0.07; 
    
    ro.xz *= rot(autoRotation - m.x*6.2831);
    ro.y += 1.0; 
    
    vec3 finalCol = vec3(0.0);

    for(int mSub = 0; mSub < 2; mSub++) {
        for(int nSub = 0; nSub < 2; nSub++) {
            vec2 offset = vec2(float(mSub), float(nSub)) / 2.0 - 0.25;
            vec2 uv = (fragCoord + offset - 0.5 * iResolution.xy) / iResolution.y;
            
            finalCol += renderScene(uv, ro, target, m);
        }
    }
   
    finalCol /= 4.0;

    fragColor = vec4(finalCol, 1.0);
}