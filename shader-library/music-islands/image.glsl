// Music Islands
// By Noztol

// Color Palette based on the original painting
#define C_TEAL      vec3(0.00, 0.65, 0.85)
#define C_LBLUE     vec3(0.50, 0.75, 0.85)
#define C_MAGENTA   vec3(0.90, 0.50, 0.80)
#define C_PINK      vec3(0.95, 0.70, 0.85)
#define C_DBLUE     vec3(0.35, 0.60, 0.70)
#define C_DARK      vec3(0.05, 0.08, 0.12) // Silhouettes
#define C_WHITE     vec3(0.95, 0.95, 0.95)

// --- Noise Functions ---
float hash(float n) { return fract(sin(n) * 43758.5453123); }

float noise1(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u);
}

float noise2(float x) {
    return textureLod(iChannel0, vec2(x * 0.35), 0.0).x;
}

// 1D fBM for Mountains & Trees
float fbm(float x) {
    float v = 0.0;
    float a = 0.5;
    float shift = 100.0;
    for (int i = 0; i < 5; ++i) {
        v += a * noise1(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float fbm2(float x) {
    float v = 0.0;
    float a = 0.75;
    float shift = 100.0;
    for (int i = 0; i < 5; ++i) {
        v += a * noise2(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec3 renderSky(vec2 uv, float time) {
    float wave1 = sin(uv.x * 4.0 - time * 0.6) * 0.12;
    float wave2 = sin(uv.x * 7.0 - uv.y * 5.0 + time * 0.8) * 0.05;
    float wave3 = cos(uv.x * 2.0 - time * 0.3) * 0.10;
    
    float h_raw = uv.y - wave1 - wave2 - wave3;
    float numBands = 20.0; 
    float bandIndex = floor(h_raw * numBands); 
    
    float h = clamp(bandIndex / numBands, 0.0, 1.0); 
    float local_h = fract(h_raw * numBands); 

    float fluid = sin(uv.x * 3.0 + uv.y * 2.0 + time) * 0.5 + 
                  cos(uv.x * 2.0 - uv.y * 4.0 - time * 0.7) * 0.5;
                  
    float r = hash(bandIndex * 12.9898);
    float colorVal = (1.0 - h) * 0.7 + r * 0.15 + fluid * 0.15;

    vec3 baseColor = C_TEAL;
    baseColor = mix(baseColor, C_LBLUE,   smoothstep(0.20, 0.45, colorVal));
    baseColor = mix(baseColor, C_MAGENTA, smoothstep(0.40, 0.70, colorVal));
    baseColor = mix(baseColor, C_PINK,    smoothstep(0.65, 0.90, colorVal));
    baseColor = mix(baseColor, C_WHITE,   smoothstep(0.85, 1.10, colorVal));
    
    return mix(baseColor, C_WHITE, local_h * 0.5); 
}

vec3 renderScene(vec2 uv, vec2 st, float time, float waterLine) {
    vec3 col = renderSky(uv, time); 
    
    // mountains (Light Blue)
    float mBack = waterLine + 0.08 + fbm(st.x * 3.0) * 0.12;
    if (uv.y > waterLine && uv.y < mBack) {
        col = mix(C_LBLUE, C_MAGENTA, 0.3); 
    }
    
    // mountains (Deeper Blue)
    float mMid = waterLine + 0.04 + fbm(st.x * 5.0 + 10.0) * 0.09;
    if (uv.y > waterLine && uv.y < mMid) {
        col = mix(C_DBLUE, C_MAGENTA, 0.15); 
    }
    
    // Foreground islands (Match Reference Photo)
    float leftIsland = smoothstep(0.35, 0.15, uv.x) * 0.25 + smoothstep(0.15, 0.0, uv.x) * 0.15;
    float rightIsland = smoothstep(0.65, 0.85, uv.x) * 0.12;
    float landBase = leftIsland + rightIsland;
    
    // Add music trees
    float treeNoise = (fbm2(uv.x * 40.0) * 0.06 + sin(uv.x * 150.0) * 0.01) * smoothstep(0.01, 0.1, landBase);
    float mFront = waterLine + landBase + treeNoise;
    
    if (uv.y > waterLine && uv.y < mFront && landBase > 0.001) {
        col = C_DARK; 
    }
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    vec2 st = uv;
    st.x *= aspect;
    
    float t = iTime * 0.5;
    vec3 finalColor = vec3(0.0);
    float waterLine = 0.35; 
    
    //  1. Draw the Upper Scene
    if (uv.y > waterLine) {
        finalColor = renderScene(uv, st, t, waterLine);
    }

    //  2. Draw the Lower Scene (Reflective Rippling Water) 
    if (uv.y <= waterLine) {
        float depth = waterLine - uv.y; 
        float perspective = 1.0 + depth * 4.0; 
        
        float rippleX = sin(uv.x * 15.0 + depth * 40.0 - iTime * 2.0) * 0.015 * perspective;
        float rippleY = cos(uv.x * 10.0 + depth * 30.0 - iTime * 1.5) * 0.005 * perspective;
        
        vec2 reflectUv = vec2(uv.x + rippleX, waterLine + depth + rippleY);
        reflectUv.y = max(reflectUv.y, waterLine + 0.001); 
        
        vec2 reflectSt = reflectUv;
        reflectSt.x *= aspect;
        
        vec3 reflectColor = renderScene(reflectUv, reflectSt, t, waterLine);
        
        float wavePhase = pow(depth, 0.7) * 70.0 - iTime * 3.0; 
        wavePhase += sin(uv.x * 12.0) * 0.6; 
        
        float waveCrests = smoothstep(0.6, 0.9, sin(wavePhase));
        float waveTroughs = smoothstep(0.6, 0.9, sin(wavePhase + 3.14)); 
        
        float reflectionStrength = 0.4 + depth * 1.5;
        vec3 waterBaseColor = mix(C_DARK, C_MAGENTA, 0.15); 
        finalColor = mix(waterBaseColor, reflectColor, clamp(reflectionStrength, 0.0, 1.0));
        
        finalColor = mix(finalColor, reflectColor * 1.2, waveCrests * 0.3); 
        finalColor = mix(finalColor, C_DARK, waveTroughs * 0.4);            
        
        if (uv.y > waterLine - 0.005) {
            finalColor = C_DARK; 
        }
    }

    finalColor *= 1.0 - 0.3 * length(uv - 0.5);
    fragColor = vec4(finalColor, 1.0);
}