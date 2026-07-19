// Recursive Parallax Corridor
// Use AI for assistence
#ifdef GL_ES
precision highp float;
#endif

#define PI 3.14159265359
#define TAU 6.28318530718
#define BIG 100000.0
#define MAX_LEVELS 8
#define AA_SAMPLES 2

struct Hit {
    float t;          // Intersection distance
    vec3 p;           // Intersection point
    vec2 uv;          // Surface UV coordinates
    int face;         // Hit face index (0-5)
};

// 2D rotation matrix
mat2 rotate2D(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

// Hash functions for pseudo-randomness
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    return vec2(hash12(p), hash12(p + 37.19));
}

// 2D box signed distance function
float sdBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Render a line from an SDF value
float lineFromSdf(float d, float width, float feather) {
    return 1.0 - smoothstep(width, width + feather, abs(d));
}

// Render a line from a distance value (for frames/corners)
float lineFromDistance(float d, float width, float feather) {
    return 1.0 - smoothstep(width, width + feather, d);
}

// Dynamic color palette based on hue
vec3 palette(float h) {
    h = fract(h);
    vec3 cyan = vec3(0.10, 0.88, 1.00);
    vec3 rose = vec3(1.00, 0.20, 0.62);
    vec3 amber = vec3(1.00, 0.74, 0.18);
    vec3 mint = vec3(0.25, 1.00, 0.62);
    vec3 a = mix(cyan, rose, smoothstep(0.08, 0.56, h));
    vec3 b = mix(amber, mint, smoothstep(0.42, 0.96, h));
    return mix(a, b, 0.34 + 0.18 * sin(h * TAU + iTime * 0.24));
}

// Build local basis vectors for a given cube face
void faceBasis(int face, out vec3 u, out vec3 v, out vec3 n) {
    if (face == 0) { n = vec3(1.0, 0.0, 0.0); u = vec3(0.0, 0.0, -1.0); v = vec3(0.0, 1.0, 0.0); } 
    else if (face == 1) { n = vec3(-1.0, 0.0, 0.0); u = vec3(0.0, 0.0, 1.0); v = vec3(0.0, 1.0, 0.0); } 
    else if (face == 2) { n = vec3(0.0, 1.0, 0.0); u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 0.0, -1.0); } 
    else if (face == 3) { n = vec3(0.0, -1.0, 0.0); u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 0.0, 1.0); } 
    else if (face == 4) { n = vec3(0.0, 0.0, 1.0); u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 1.0, 0.0); } 
    else { n = vec3(0.0, 0.0, -1.0); u = vec3(-1.0, 0.0, 0.0); v = vec3(0.0, 1.0, 0.0); }
}

// Update hit record if a closer intersection is found
void updateHit(vec3 ro, vec3 rd, float t, int face, inout Hit hit) {
    if (t > 0.0008 && t < hit.t) {
        vec3 p = ro + rd * t;
        vec3 u, v, n;
        faceBasis(face, u, v, n);
        hit.t = t; hit.p = p;
        hit.uv = vec2(dot(p, u), dot(p, v));
        hit.face = face;
    }
}

// Ray-AABB intersection for the unit cube [-1,1]^3
Hit traceRoom(vec3 ro, vec3 rd) {
    Hit hit;
    hit.t = BIG; hit.p = vec3(0.0); hit.uv = vec2(0.0); hit.face = -1;
    if (abs(rd.x) > 0.0001) { updateHit(ro, rd, (1.0 - ro.x) / rd.x, 0, hit); updateHit(ro, rd, (-1.0 - ro.x) / rd.x, 1, hit); }
    if (abs(rd.y) > 0.0001) { updateHit(ro, rd, (1.0 - ro.y) / rd.y, 2, hit); updateHit(ro, rd, (-1.0 - ro.y) / rd.y, 3, hit); }
    if (abs(rd.z) > 0.0001) { updateHit(ro, rd, (1.0 - ro.z) / rd.z, 4, hit); updateHit(ro, rd, (-1.0 - ro.z) / rd.z, 5, hit); }
    return hit;
}

// Build camera look-at matrix
mat3 cameraBasis(vec3 ro, vec3 target) {
    vec3 ww = normalize(target - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    return mat3(uu, vv, ww);
}

// ==========================================
// CORE REPLACEMENT: Sci-Fi Octahedron (Diamond)
// ==========================================

// Octahedron SDF: |x| + |y| + |z| - radius, scaled by 1/sqrt(3)
float mapCore(vec3 p, vec3 center, float radius, float localTime) {
    vec3 q = p - center;
    // Compound rotation for tumbling effect
    q.xz *= rotate2D(localTime);
    q.xy *= rotate2D(localTime * 0.73);
    q = abs(q);
    return (q.x + q.y + q.z - radius) * 0.57735027; // 1/sqrt(3)
}

// Ray march the octahedron
float marchCore(vec3 ro, vec3 rd, float maxT, vec3 center, float radius, float localTime) {
    float t = 0.0;
    for(int i = 0; i < 40; i++) {
        float d = mapCore(ro + rd * t, center, radius, localTime);
        if(d < 0.001) return t;
        t += d;
        if(t > maxT) break;
    }
    return BIG;
}

// Compute normal via gradient of SDF
vec3 calcCoreNormal(vec3 p, vec3 center, float radius, float localTime) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapCore(p + e.xyy, center, radius, localTime) - mapCore(p - e.xyy, center, radius, localTime),
        mapCore(p + e.yxy, center, radius, localTime) - mapCore(p - e.yxy, center, radius, localTime),
        mapCore(p + e.yyx, center, radius, localTime) - mapCore(p - e.yyx, center, radius, localTime)
    ));
}

// Soft shadow from octahedron onto walls
float softShadowCore(vec3 ro, vec3 rd, float maxT, vec3 center, float radius, float localTime, float k) {
    float res = 1.0;
    float t = 0.01;
    for(int i = 0; i < 24; i++) {
        float d = mapCore(ro + rd * t, center, radius, localTime);
        if(d < 0.001) return 0.02; // Hard shadow
        res = min(res, k * d / t);
        t += max(0.01, d);
        if(t > maxT) break;
    }
    return clamp(res, 0.02, 1.0);
}
// ==========================================

// Recursive concentric rings on portal surface
float recursiveRings(vec2 uv, float depth, float localTime) {
    float rings = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float b = 0.53 - fi * 0.105 + 0.010 * sin(localTime * (0.042 + fi * 0.013) + depth * 1.9);
        vec2 offset = 0.020 * vec2(
            sin(localTime * 0.031 + depth + fi * 2.1),
            cos(localTime * 0.027 - depth * 1.4 + fi)
        );
        float d = sdBox2(uv + offset, vec2(b));
        float gate = 0.72 + 0.28 * smoothstep(-0.2, 0.8, sin((uv.x - uv.y) * 11.0 + localTime * 0.055 + fi * 1.7));
        rings = max(rings, lineFromSdf(d, 0.004, 0.018) * gate);
    }
    return rings;
}

// Procedural maze pattern on portal surface
float brokenMaze(vec2 uv, float depth, float localTime, float portalInside) {
    vec2 p = (uv + 0.72) * (2.35 + 0.24 * mod(depth, 3.0));
    p += 0.13 * vec2(sin(localTime * 0.036 + depth), cos(localTime * 0.029 - depth));

    vec2 cell = floor(p);
    vec2 f = fract(p) - 0.5;
    float selector = step(0.5, hash12(cell + depth * 17.0));
    float d = min(abs(f.x), abs(f.y));
    float gateA = smoothstep(0.10, 0.26, abs(f.y + 0.17 * sin(depth + cell.x)));
    float gateB = smoothstep(0.10, 0.26, abs(f.x + 0.17 * cos(depth + cell.y)));
    float gates = mix(gateA, gateB, selector);
    float line = 1.0 - smoothstep(0.012, 0.036, d);
    return line * gates * portalInside;
}

// Background / skybox
vec3 background(vec2 uv, vec3 rd, vec2 mouseParallax) {
    float vignette = smoothstep(1.55, 0.12, length(uv));
    vec3 col = mix(vec3(0.002, 0.003, 0.004), vec3(0.020, 0.023, 0.027), vignette);
    col += vec3(0.010, 0.012, 0.014) * pow(max(0.0, rd.z), 1.8);

    vec2 drift = uv + mouseParallax * 0.10;
    float spectral = 0.5 + 0.5 * sin(4.8 * atan(drift.y, drift.x) + iTime * 0.28);
    col += palette(spectral * 0.22 + 0.56) * 0.015 * smoothstep(1.25, 0.1, length(uv));
    return col;
}

// Main rendering pass
vec3 render(vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    
    // Subtle fisheye distortion for depth
    float r2 = dot(uv, uv);
    uv *= 1.0 + r2 * 0.12; 

    // Mouse input with idle animation fallback
    vec2 rawMouse = iMouse.xy / max(iResolution.xy, vec2(1.0));
    vec2 idleMouse = vec2(0.50 + 0.23 * sin(iTime * 0.19), 0.50 + 0.18 * cos(iTime * 0.17));
    float hasMouse = step(0.25, iMouse.z);
    vec2 control = mix(idleMouse, clamp(rawMouse, 0.0, 1.0), hasMouse);
    vec2 mouseParallax = (control - 0.5) * 2.0;

    // Camera setup
    vec3 ro = vec3(mouseParallax.x * 0.30, mouseParallax.y * 0.22, -0.46 + 0.035 * sin(iTime * 0.31));
    vec3 target = vec3(mouseParallax.x * 0.09, mouseParallax.y * 0.07, 0.63);
    mat3 cam = cameraBasis(ro, target);
    vec3 rd = normalize(cam * vec3(uv, 1.58));

    vec3 col = background(uv, rd, mouseParallax);
    float throughput = 1.0;
    float accumulatedDistance = 0.0;

    // Recursive traversal through portal levels
    for (int level = 0; level < MAX_LEVELS; level++) {
        float depth = float(level);
        float localTime = iTime * exp2(depth);
        Hit hit = traceRoom(ro, rd);
        if (hit.face < 0) break;

        // --- Core geometry rendering ---
        bool coreEnabled = level > 0;
        vec3 coreCenter = vec3(
            0.18 * sin(localTime * 1.2 + depth * 2.0),
            0.12 * cos(localTime * 0.8 - depth * 1.5),
            0.15 * sin(localTime * 0.9 + depth)
        );
        float coreRadius = 0.14 + 0.02 * sin(depth * PI + iTime * 2.0);
        
        float coreT = coreEnabled ? marchCore(ro, rd, hit.t, coreCenter, coreRadius, localTime) : BIG;
        
        if (coreT < hit.t) {
            accumulatedDistance += coreT * (0.80 + depth * 0.09);
            vec3 corePoint = ro + rd * coreT;
            vec3 coreNormal = calcCoreNormal(corePoint, coreCenter, coreRadius, localTime);
            
            // Dramatic top-light with Half-Lambert shading
            vec3 lightDir = normalize(vec3(0.5, 0.8, -0.6));
            float diffuse = max(dot(coreNormal, lightDir), 0.0) * 0.5 + 0.5;
            
            vec3 viewDirection = -rd;
            vec3 halfDirection = normalize(lightDir + viewDirection);
            float specular = pow(max(dot(coreNormal, halfDirection), 0.0), 64.0);
            
            float fresnel = 0.05 + 0.95 * pow(1.0 - max(dot(coreNormal, viewDirection), 0.0), 5.0);
            
            // Extract octahedron edges in local space
            vec3 localP = corePoint - coreCenter;
            localP.xz *= rotate2D(localTime);
            localP.xy *= rotate2D(localTime * 0.73);
            localP = abs(localP);
            
            // The 12 edges are where min(|x|,|y|,|z|) approaches 0
            float distToEdge = min(min(localP.x, localP.y), localP.z);
            float edgeGlow = 1.0 - smoothstep(0.0, 0.015, distToEdge);
            
            vec3 baseTint = palette(depth * 0.16 + localTime * 0.2);
            vec3 envRef = background(coreNormal.xy, reflect(rd, coreNormal), mouseParallax) * 1.5;

            // Material assembly: dark base + edge glow + specular + environment
            vec3 coreColor = vec3(0.02) + baseTint * diffuse * 0.15;
            coreColor += envRef * (0.2 + 0.8 * fresnel);
            coreColor += vec3(1.0) * specular * 1.5;
            coreColor += baseTint * edgeGlow * 3.5; // Neon edge emission
            
            // Spatial ambient occlusion based on distance to room walls
            float normalAO = 0.5 + 0.5 * coreNormal.y;
            float distToWall = 1.0 - max(max(abs(corePoint.x), abs(corePoint.y)), abs(corePoint.z));
            float spatialAO = smoothstep(0.0, 0.5, distToWall);
            coreColor *= normalAO * (0.4 + 0.6 * spatialAO);

            float fog = exp(-0.035 * accumulatedDistance);
            col += throughput * fog * coreColor;
            break; // Terminate ray on core hit
        }

        vec3 u; vec3 v; vec3 n;
        faceBasis(hit.face, u, v, n);
        accumulatedDistance += hit.t * (0.80 + depth * 0.09);

        // --- Portal styling (reverted to original square design) ---
        float portalHalf = 0.735 - 0.012 * sin(localTime * 0.025 + depth);
        float portalSdf = sdBox2(hit.uv, vec2(portalHalf));
        float portalInside = 1.0 - smoothstep(-0.018, 0.010, portalSdf);
        float portalEdge = lineFromSdf(portalSdf, 0.006, 0.022);

        float roomCorner = min(1.0 - abs(hit.uv.x), 1.0 - abs(hit.uv.y));
        float cubeFrame = lineFromDistance(roomCorner, 0.010, 0.028);
        float rings = recursiveRings(hit.uv / portalHalf, depth, localTime) * portalInside;
        float maze = brokenMaze(hit.uv / portalHalf, depth, localTime, portalInside);

        // --- 2D wall lighting (Gaussian light spot) ---
        vec2 lightPos = 0.47 * vec2(
            sin(localTime * 0.052 + depth * 1.31),
            cos(localTime * 0.043 - depth * 1.17)
        ) + mouseParallax * (0.09 + depth * 0.008);
        
        float lamp = exp(-dot(hit.uv - lightPos, hit.uv - lightPos) * 5.2);
        
        // Octahedron casts shadow onto wall
        vec3 dirToCore = normalize(coreCenter - hit.p);
        float distToCore = length(coreCenter - hit.p);
        float shadow = coreEnabled ? softShadowCore(hit.p - n * 0.002, dirToCore, distToCore, coreCenter, coreRadius, localTime, 12.0) : 1.0;
        lamp *= (0.3 + 0.7 * shadow); 

        // --- Minimal neon shading (reverted original palette) ---
        vec3 layerTint = palette(0.09 * depth + 0.055 * sin(localTime * 0.034) + length(hit.uv) * 0.11);
        vec3 edgeTint = palette(0.17 * depth + 0.20 * hit.uv.x - 0.13 * hit.uv.y + localTime * 0.004);
        float facing = 0.42 + 0.58 * clamp(dot(rd, n), 0.0, 1.0);
        float fog = exp(-0.035 * accumulatedDistance);

        vec3 wall = vec3(0.020, 0.021, 0.023) * (0.70 + 0.30 * facing);
        float cornerAO = smoothstep(0.0, 0.25, roomCorner);
        wall *= 0.5 + 0.5 * cornerAO;

        wall += layerTint * lamp * 0.145;
        wall += edgeTint * exp(-abs(portalSdf) * 6.0) * 0.115;

        float whiteLines = max(max(cubeFrame, portalEdge), max(rings * 0.70, maze * 0.42));
        vec3 frameColor = mix(vec3(0.86, 0.91, 0.93), vec3(1.0), portalEdge);
        vec3 lineGlow = frameColor * whiteLines * (0.56 + 0.16 * depth);
        lineGlow += edgeTint * (portalEdge * 1.18 + cubeFrame * 0.20 + rings * 0.42 + maze * 0.26);
        lineGlow += layerTint * (portalEdge * 0.36 + rings * 0.24 + maze * 0.14 + lamp * 0.32);

        float solidWall = 1.0 - portalInside;
        float apertureGlow = portalInside * smoothstep(0.98, 0.04, length(hit.uv)) * (0.065 + 0.075 * lamp);
        col += throughput * fog * (wall * (0.18 + solidWall * 0.62) + lineGlow + edgeTint * apertureGlow);

        if (portalSdf >= -0.002 || level == MAX_LEVELS - 1) {
            vec3 terminal = palette(0.18 + depth * 0.11 + localTime * 0.006);
            float finalGlow = portalInside * smoothstep(1.15, 0.05, length(hit.uv));
            col += throughput * terminal * finalGlow * 0.18;
            break;
        }

        // --- Fold space: warp to next level ---
        vec2 portalUv = hit.uv / portalHalf;
        vec3 nextRd = vec3(dot(rd, u), dot(rd, v), max(0.035, dot(rd, n)));
        nextRd.xy += 0.045 * sin(portalUv.yx * 3.6 + localTime * vec2(0.043, 0.037) + depth);
        nextRd = normalize(nextRd);

        vec2 layerShift = rotate2D(depth * 0.78 + 0.15 * sin(localTime * 0.018)) * mouseParallax;
        vec3 nextRo = vec3(portalUv, -0.986);
        nextRo.xy += layerShift * (0.102 + 0.020 * depth);
        nextRo.xy += 0.026 * vec2(sin(localTime * 0.027 + depth * 1.7), cos(localTime * 0.023 - depth));

        float roll = 0.12 * sin(localTime * 0.020 + depth * 1.63) + 0.045 * mouseParallax.x;
        mat2 roomRoll = rotate2D(roll);
        nextRo.xy = roomRoll * nextRo.xy;
        nextRd.xy = roomRoll * nextRd.xy;

        ro = vec3(clamp(nextRo.xy, vec2(-0.94), vec2(0.94)), nextRo.z);
        rd = normalize(nextRd);
        throughput *= 0.69 + 0.035 * cos(depth + localTime * 0.014);
    }

    // Post-processing
    col *= 1.0 - 0.42 * smoothstep(0.48, 1.48, length(uv));
    col += palette(0.62 + 0.03 * sin(iTime)) * 0.018 * pow(max(0.0, 1.0 - length(uv) * 0.42), 2.0);
    col = col / (1.0 + col * 0.82);
    col = pow(max(col, 0.0), vec3(0.88));
    return col;
}

// Main entry point with multi-sample anti-aliasing
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.0);
    int sampleCount = iResolution.x < 600.0 ? 1 : AA_SAMPLES; 
    
    vec2 aaOffsets[3];
    aaOffsets[0] = vec2( 0.0,  0.0);
    aaOffsets[1] = vec2( 0.3, -0.3);
    aaOffsets[2] = vec2(-0.3,  0.3);

    vec2 p = -1.0 + 2.0 * (fragCoord / iResolution.xy);
    float r2 = dot(p, p);
    
    // Chromatic aberration at screen edges for sci-fi lens effect
    float chromShift = r2 * 0.4; 

    for (int i = 0; i < 3; i++) {
        if (i >= sampleCount) break;
        vec2 jitter = aaOffsets[i];
        
        float r = render(fragCoord + jitter + vec2(chromShift, 0.0)).r;
        float g = render(fragCoord + jitter).g;
        float b = render(fragCoord + jitter - vec2(chromShift, 0.0)).b;
        color += vec3(r, g, b);
    }
    color /= float(sampleCount);
    
    // Subtle film grain to prevent color banding
    color += (hash12(fragCoord + iTime * 19.0) - 0.5) / 128.0; 
    
    fragColor = vec4(color, 1.0);
}