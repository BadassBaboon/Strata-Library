// MUTE (not remove/disable) audio in iChannel1.
// DO IT NOW! Then hit ⏮️ and start from the beginning

// seriously, start it from beginning, otherwise it's not in sync with the audio



































































// merged 3 shaders into one
// 2 from diatribes https://www.shadertoy.com/user/diatribes
// and one, based on diatribes' ribbons
// https://www.shadertoy.com/view/NfcGWr (based on diatribes)
// https://www.shadertoy.com/view/scd3Rn (based on diatribes)
// the tunnel is a strip down of the two ribbons and then a tunnel added with those emojis 
// around in tiles (took from: https://www.shadertoy.com/view/7cfSWs)

// Since soundcloud integration doesn't work, I've got an example video 
// with a different (better fitting) song at YT: https://www.youtube.com/watch?v=1FPXVPWEmA4



// I don't know why I am doing this. I've got in contact with some1 from the scene and was asked why I'm doing this and ShaderAmp
// Currently I struggle with answering that email, however, I think the best explaination is, that I like how time passes by WHEN I'm doing it
// If I'm in the mood for ShaderAmp feature or bug fix, bam, it's somehow a great feeling when it's done.
// same, when you see a shader and think: DAMN! this in audio-reactive would be great, and you know you can make it happen...
// and then something like this comes out ¯\_(ツ)_/¯ 


#define TRANSITION_DURATION 4.0
#define SCENE_STAY_DURATION 8.0
#define RIBBON_CORE_BRIGHTNESS 85.0
#define RIBBON_BLOOM_BRIGHTNESS 0.035
#define SNARE_ROLL_INTENSITY 0.6
#define MIN_WALL_BRIGHTNESS 0.015
#define SCALE 1.0

#define COSMIC_RIBBON_CORE_BRIGHTNESS 1.35
#define COSMIC_RIBBON_BLOOM_BRIGHTNESS 0.4

#define T (iTime * 3.5)
#define R(a) _stm2(cos(a + vec4(0, 33, 11, 0)))
#define N normalize

int iEnableShake = 1;

float getPitch(float freq, float octave) { return 0.5; }

float hash13(vec3 p3) {
    p3 = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.8975, 397.2973, 491.1871));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec2((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y));
}

float sdLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float Wobble(float t, float seed) {
    return sin(t + seed) * cos(t * 0.5 + seed * 1.3);
}

float sdSmiley(vec2 p) {
    p *= 1.4; p.y += 0.1;
    float head = length(p) - 0.45;
    vec2 ep = vec2(abs(p.x) - 0.18, p.y - 0.1);
    float eyes = length(ep * vec2(1.0, 0.85)) - 0.06;
    vec2 mp = p; mp.y += 0.05;
    float mouth = max(abs(length(mp) - 0.25) - 0.02, p.y + 0.05);
    return max(max(head, -eyes), -mouth);
}

vec2 cInv(vec2 p, vec2 o, float r) {
    return (p - o) * r * r / dot(p - o, p - o) + o;
}

float sdArc(vec2 p, float w, vec2 o) {
    vec2 pW = cInv(p, vec2(0.0), 1.0);
    pW = cInv(pW, vec2(0.0, o.y), 1.0);
    pW.y -= o.y;
    return length(vec2(max(0.0, abs(pW.x - o.x) - w), pW.y));
}

float sdEmoji(vec2 p, float time, vec2 seed) {
    vec2 h = hash22(seed);
    p *= 1.4;
    float d = 1e10;
    float t = time * (0.8 + (h.x * h.y));
    vec2 lk = (0.75 + sin(t * (min(1.4, 0.5 + h.y * 0.66 + h.x * 1.33))) * 0.5) * (h - 0.5);
    bool eyeb = fract(4.932 * h.x) < 0.65;
    if (!eyeb) lk *= sin(time * h.x + h.y * 4.0);
    else if (sin(h.x * h.y) < 0.5) lk = -lk;
    d = min(d, abs(length(p) - 1.0) - 0.075);
    float blinktime = 0.45;
    float blx = 1.0, bly = 1.0;
    float blt = mod(time, 8.0) - (h.x * h.y) * 8.0;
    if (blt > 0.0 && blt < blinktime) {
        bly = 1.0 + sin((blt / blinktime) * 3.141) * 1.5;
        blx = 1.0 - sin((blt / blinktime) * 3.141) * 0.4;
    }
    float pX = lk.x + h.x * 0.15 + 0.3;
    float perspective = 0.25 * sign(pX) * pow(abs(pX), 0.9 + h.y);
    vec2 q = p - lk * 0.2;
    d = min(d, length(vec2((abs(q.x) - 0.36) * blx + perspective, (q.y - 0.27) * bly)) - 0.15);
    if (eyeb) {
        vec2 o = vec2(0.0, 1.0);
        float eb;
        if (fract(3.447 * h.x) < 0.5)
            eb = sdArc(vec2(abs(q.x) - 0.35, q.y - 0.5 * fract(1.46 * lk.y) - 0.35), 0.2, 2.0 * fract(h * 2.31) * h.y * o - 0.5 * o);
        else
            eb = min(sdArc(vec2( q.x - 0.35, q.y - 0.25 * fract( 2.31 * lk.y) - 0.4), 0.2, 2.0 * fract( h * 2.31) * h.y * o - 0.5 * o),
                     sdArc(vec2(-q.x - 0.35, q.y - 0.25 * fract(-1.81 * lk.y) - 0.4), 0.2, 2.0 * fract(-h * 1.92) * h.y * o - 0.5 * o));
        d = min(d, eb - 0.065);
    }
    if (fract(1.932 * h.x) < 0.10) {
        float sOsc = sin(0.2 + t * (2.0 * h.x + h.y)) * (0.005 + h.y * 0.08);
        d = min(d, length(vec2((q.x - 0.11) * (1.0 - h.y * 0.2), (q.y + 0.27) * 1.1)) - (0.2 + sOsc));
    } else {
        float mw = 0.4 * pow(max(0.0, h.x + sin(t * h.y) + 0.8), 0.5);
        d = min(d, sdArc(q + vec2(0.0, 0.35), mw, vec2(0.35, 1.0) * (fract(2.772 * h) - 0.5)) - 0.08);
    }
    return d / 1.4;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdBalloon(vec2 p, float offset, float time) {
    p.y -= 0.2;
    p.x += sin(time * 2.0 + offset) * 0.1;

    float d = length(p / vec2(1.0, 1.2)) - 0.45;
    float knot = length((p + vec2(0.0, 0.52)) * vec2(1.0, 2.0)) - 0.05;
    d = smin(d, knot, 0.05);
    float string = sdLine(p + vec2(0.0, 0.55), vec2(0.0, 0.0), vec2(sin(p.y * 10.0 + time * 5.0 + offset) * 0.05, -0.8));
    return min(d, string - 0.01);
}

float sdSperm(vec2 p, float time) {
    float t = 20.*time + 0.0;
    p.y -= 0.2;
    p.y += 0.3;
    float d = length(p / vec2(1.0, 1.2)) - 0.15;
    p.y -= 0.3;
    float knot = length((p + vec2(0.0, 0.52)) * vec2(1.0, 2.0)) - 0.05;
    d = smin(d, knot, 0.05);
    float string = sdLine(p + vec2(0.0, 0.55), vec2(0.0, 0.0), vec2(sin(p.y * 10.0 + t * 8.0) * 0.05, -0.8));
    return min(d, string - 0.01);
}

vec2 rot2(vec2 p, float a) {
    float s = sin(a), c = cos(a);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float sdButterfly(vec2 p, float time) {
    p.y += 0.1; float x = abs(p.x);
    float body = sdLine(p, vec2(0.0, -0.4), vec2(0.0, 0.4)) - 0.03;
    body = min(body, sdLine(vec2(x, p.y), vec2(0.0, 0.3), vec2(0.15, 0.6)) - 0.01);
    vec2 pU = rot2(vec2(x - 0.35, p.y - 0.25), -0.4);
    vec2 pL = rot2(vec2(x - 0.25, p.y + 0.2), 0.5);
    return smin(body, smin(length(pU * vec2(0.8, 1.2)) - 0.45, length(pL * vec2(1.2, 0.8)) - 0.35, 0.1) + x * sin(time * 10.0) * 0.1, 0.05);
}

float sdWeed(vec2 p) {
    vec2 q = p * 3.5;
    q.y += 0.85;
    float theta = atan(q.y, q.x);
    float wR = 0.22 * (1.0 + sin(theta)) * (1.0 + 0.9*cos(8.0*theta)) * (1.0 + 0.1*cos(24.0*theta));
    return length(q) - wR;
}

float sdBeerBottle(vec2 p) {
    p *= 1.8; p.y += 0.5; float x = abs(p.x), y = p.y, d = 1e10;
    d = min(d, sdLine(vec2(x, y), vec2(0.4, -1.5), vec2(0.4, 0.2)));
    d = min(d, sdLine(vec2(x, y), vec2(0.4, -1.5), vec2(0.0, -1.5)));
    if (y > 0.2 && y < 0.6) d = min(d, x - mix(0.4, 0.2, smoothstep(0.0, 1.0, (y-0.2)/0.4)));
    d = min(d, sdLine(vec2(x, y), vec2(0.2, 0.6), vec2(0.15, 1.3)));
    d = min(d, sdLine(vec2(x, y), vec2(0.15, 1.3), vec2(0.17, 1.36)));
    d = min(d, sdLine(vec2(x, y), vec2(0.17, 1.36), vec2(0.15, 1.55)));
    return min(d, sdLine(vec2(x, y), vec2(0.15, 1.55), vec2(0.0, 1.55))) - 0.05;
}

float sdPeace(vec2 p) {
    p *= 2.0;
    vec2 pcD = vec2(abs(p.x), p.y) * mat2(0.707,-0.707,0.707,0.707);
    return min(
        abs(length(p) - 0.5) - 0.025,
        min(max(abs(p.x) - 0.025, abs(p.y) - 0.5),
            max(abs(pcD.y) - 0.025, abs(pcD.x - 0.25) - 0.25))
    );
}

float sdDancer(vec2 uv, float time) {
    uv *= 0.8; uv.y += 0.05;
    float legLen = 0.18, armLen = 0.15;
    vec2 hipA = vec2(0.07, -0.17), hipB = vec2(-0.07, -0.17);
    vec2 kneeA = normalize(vec2(0.15 + Wobble(time, 7.6) * 0.1, -0.3) - hipA) * legLen + hipA;
    vec2 footA = normalize(vec2(0.1 + Wobble(time, 237.6) * 0.1, -0.5) - kneeA) * legLen + kneeA;
    vec2 kneeB = normalize(vec2(-0.15 + Wobble(time, 437.6) * 0.1, -0.3) - hipB) * legLen + hipB;
    vec2 footB = normalize(vec2(-0.1 + Wobble(time, 383.6) * 0.1, -0.5) - kneeB) * legLen + kneeB;
    vec2 shA = vec2(0.12, 0.17), shB = vec2(-0.12, 0.17);
    vec2 elA = normalize(vec2(0.3, -0.07 + Wobble(time, 7.6) * 0.3) - shA) * armLen + shA;
    vec2 hdA = elA + vec2(0.14, Wobble(time, 73.6) * 0.5);
    elA = normalize(elA - shA) * armLen + shA;
    hdA = normalize(hdA - elA) * armLen + elA;
    vec2 elB = normalize(vec2(-0.3, -0.07 + Wobble(time, 17.6) * 0.3) - shB) * armLen + shB;
    vec2 hdB = elB + vec2(-0.14, Wobble(time, 173.6) * 0.5);
    elB = normalize(elB - shB) * armLen + shB;
    hdB = normalize(hdB - elB) * armLen + elB;
    vec2 headPos = vec2(Wobble(time, 573.6) * 0.03, 0.33 + sin(time * 2.0) * 0.01);
    float d = sdLine(uv, vec2(0, -0.05), vec2(0, 0.1));
    d = min(d, sdLine(uv, hipA, kneeA)); d = min(d, sdLine(uv, kneeA, footA));
    d = min(d, sdLine(uv, hipB, kneeB)); d = min(d, sdLine(uv, kneeB, footB));
    d = min(d, sdLine(uv, shA, elA)); d = min(d, sdLine(uv, elA, hdA));
    d = min(d, sdLine(uv, shB, elB)); d = min(d, sdLine(uv, elB, hdB));
    return min(d, length(uv - headPos) - 0.05) - 0.015;
}

vec4 evaluateWallShape(vec2 uv, vec2 id, float time) {
    float n = hash21(id);
    float n2 = fract(n * 7.391 + hash21(id + vec2(13.7, 5.3)) * 3.17);
    int shape = int(n2 * 10.0);

    vec2 tileDist = abs(uv - 0.5);
    float tileMask = smoothstep(0.5, 0.46, max(tileDist.x, tileDist.y));
    if (tileMask <= 0.0) return vec4(0.0);

    vec2 p = uv - 0.5;

    float rotAngle = n * 6.28318;
    float c = cos(rotAngle), s_r = sin(rotAngle);
    p *= mat2(c, -s_r, s_r, c);
    p *= 0.85 + 0.08 * sin(time * 2.5 + n * 3.14);

    float d = 1e10;
    vec3 shapeColor = vec3(1.0);
    bool isOutline = false;

    if (shape == 0) {
        d = sdEmoji(p * 1.9, 7.*time, id);
        shapeColor = vec3(1.0, 0.85, 0.1);
    } else if (shape == 1) {
        d = sdDancer(p * 1.5, time * 5.0 + n * 5.0);
        shapeColor = vec3(1.0, 0.55, 0.1);
    } else if (shape == 2) {
        d = sdButterfly(p * 2.2, 5.*time + n * 3.0);
        shapeColor = vec3(1.0, 0.4, 0.1);
        isOutline = true;
    } else if (shape == 3) {
        d = sdPeace(p * 0.9);
        shapeColor = vec3(0.1, 0.85, 0.9);
    } else if (shape == 4) {
        d = sdWeed(p);
        shapeColor = vec3(0.1, 0.85, 0.15);
    } else if (shape == 5) {
        d = sdBeerBottle(p*3.);
        shapeColor = vec3(1.0, 0.78, 0.0);
    } else if (shape == 6) {
        vec2 hP = p * 5.0 + vec2(0.0, 0.35);
        float k = 1.2 * hP.y - sqrt(abs(hP.x) + 0.3);
        d = hP.x * hP.x + k * k - 1.0;
        shapeColor = vec3(1.0, 0.1, 0.35);
    } else if (shape == 7) {
        d = sdButterfly(vec2(-p.x, p.y) * 2.2, time * 2.3 + n * 2.0);
        shapeColor = vec3(0.65, 0.2, 1.0);
        isOutline = true;
    } else if (shape == 8) {
        d = sdBalloon(p * 2.0, time + n * 3.0, time);
        shapeColor = vec3(1.0, 0.15, 0.25);
    } else if (shape == 9) {
        d = sdSperm(p * 1.8, time + n * 3.0);
        shapeColor = vec3(0.95, 0.95, 0.95);
    } else {
        d = sdBalloon(p * 2.0, time + n * 3.0, time);
        shapeColor = vec3(1.0, 0.15, 0.25);
    }

    float stroke = 0.015;
    float mask = isOutline
        ? smoothstep(stroke + 0.018, stroke, abs(d)) * tileMask
        : smoothstep(0.03, 0.0, d) * tileMask;
    return vec4(shapeColor * mask, mask);
}

float tunnel(vec3 p, float r) {
    p = abs(p);
    return min(r - p.x, r - p.y);
}

vec4 marchVoxels(vec3 fp, vec3 sd, vec3 rs, vec3 dd, float iters, float minS,
                 out int side, float radius) {

    float s, d = 0.;
    float i;
    for (i = 0.; i++ < iters;) {

        if(sd.x <= sd.y && sd.x <= sd.z){
            sd.x += dd.x;
            fp.x += rs.x;
            side = 0;
        } else if(sd.y <= sd.z && sd.y <= sd.x) {
            sd.y += dd.y;
            fp.y += rs.y;
            side = 1;
        }  else {
            sd.z += dd.z;
            fp.z += rs.z;
            side = 2;
        }

        s = tunnel(fp * SCALE, radius);
        d += s;
        if (s < minS) break;

    }

    return vec4(fp, i);
}

vec3 tex(vec3 ro, vec3 rd, vec3 p, vec3 n) {
    vec3 rgb = vec3(0.0);

    float t = dot(n, p - ro) / dot(n, N(rd));
    vec3 hit = ro + N(rd) * t;
    rgb = mix(rgb, abs(vec3(1, 2, 1e1) / dot(cos(iTime + hit * 4.) * .1 + sin(iTime + hit * .1), vec3(.1))), .01);

    return rgb;
}

void getCamera(vec2 u, out vec3 ro, out vec3 rd, float time) {
    vec3 r = iResolution.xyy;
    ro = vec3(0.0, 0.0, time * 15.0);
    float rollAngle = 0.0;
    if (iEnableShake == 1) {
        float dynamicRoll = texture(iChannel0, vec2(0.5) / r.xy).r;
        rollAngle = dynamicRoll * SNARE_ROLL_INTENSITY;
    }
    vec2 uv = (u - r.xy / 2.) / r.y + vec2(0.2, 0.2) + vec2(sin(T * .4) * .4, sin(T * .3) * .4);
    uv *= R(rollAngle);
    uv *= R(tanh(sin(ro.z * .005) * 4.) * 3.);
    uv *= R(sin(T * .3) * .5);
    rd = vec3(uv, 1.0);
}

vec4 mainA(vec2 u) {
    vec3 ro, rd;
    
    getCamera(u, ro, rd,T/2.);
    vec3 D = N(rd);

    vec3 p = iResolution;
    vec4 o = vec4(0.0);
    vec4 ribbonGlow = vec4(0.0);

    float d = 0.0;
    float s = 0.0;

    float fftA = 0.0;
    float fftB = 0.0;
    vec3 pA, pB;
    float la = 0.0, lb = 0.0;

    bool hitWall = false;
    vec3 tunnelSpaceAtHit = vec3(0.0);
    float hitDistance = 0.0;

    float accumA = 0.0;
    float accumB = 0.0;

    for(float i = 0.0; i < 90.0; i++) {
        vec3 currP = ro + D * d;
        vec3 q = currP;

        float tunnelDist = 7.0 - length(q.xy);
        float rings = length(q.xy) - 6.8 + 0.2 * sin(q.z * 1.5 + T);
        tunnelDist = max(tunnelDist, -rings);

        fftA = texture(iChannel1, vec2(fract(q.z * 0.005), 0.25)).r;
        fftB = texture(iChannel1, vec2(fract(q.z * 0.003 + 0.5), 0.25)).r;

        pA = q;
        pB = q;

        pA.y += fftA * 2.5 * sin(q.z * 0.4 + T);
        pB.x -= fftB * 2.5 * cos(q.z * 0.4 - T);

        la = length(pA.xy + sin(cos(pA.z / 10.0) * 2.0 + vec2(0, 1.57)) * 4.5) - 0.15;
        lb = length(pB.xy + sin(cos(pB.z / 20.0) * 2.0 - vec2(0, 1.57)) * 4.5) - 0.15;
        float ribbonDist = min(abs(la), abs(lb));

        s = min(tunnelDist, ribbonDist);

        if (s == tunnelDist && tunnelDist < 0.02 && !hitWall) {
            hitWall = true;
            tunnelSpaceAtHit = q;
            hitDistance = d;
        }

        d += max(s, 0.015);

        float glowFade = exp(-d * 0.03);
        accumA += (0.012 / (0.015 + la * la)) * (0.15 + fftA) * glowFade;
        accumB += (0.012 / (0.015 + lb * lb)) * (0.15 + fftB) * glowFade;
    }

    accumA = min(accumA, 3.0);
    accumB = min(accumB, 3.0);

    ribbonGlow += vec4(1.0, 0.2, 0.4, 0.0) * accumA * COSMIC_RIBBON_CORE_BRIGHTNESS;
    ribbonGlow += vec4(0.1, 0.5, 1.0, 0.0) * accumB * COSMIC_RIBBON_CORE_BRIGHTNESS;

    if (hitWall) {
        vec2 wallDirection = normalize(tunnelSpaceAtHit.xy);

        float spiralAngle = atan(wallDirection.y, wallDirection.x);
        float radialAngle = spiralAngle * 1.90986;
        float forwardDist = tunnelSpaceAtHit.z * 0.25 + T * 0.2;
        vec2 wallUV = vec2(radialAngle, forwardDist);

        vec2 gridId = floor(wallUV);
        vec2 localUV = fract(wallUV);

        vec4 shapeResult = evaluateWallShape(localUV, gridId, T);
        float shapePulse = sin(T * 4.0 + hash21(gridId) * 20.0) * 0.3 + 0.7;
        vec4 neonColor = mix(vec4(0.0, 1.0, 0.75, 1.0), vec4(0.15, 0.45, 1.0, 1.0), hash21(gridId));

        float gridLines = smoothstep(0.04, 0.0, abs(localUV.x - 0.5) - 0.46) +
                          smoothstep(0.04, 0.0, abs(localUV.y - 0.5) - 0.46);

        float wallBackdrop = abs(sin(tunnelSpaceAtHit.z * 2.0 + T) * sin(atan(wallDirection.y, wallDirection.x) * 6.0));
        float wallMask = smoothstep(0.2, 0.8, wallBackdrop);

        o += vec4(0.05, 0.06, 0.09, 1.0) * wallMask * (1.0 - gridLines) * (35.0 / hitDistance);
        o += neonColor * gridLines * 0.25 * (1.0 + fftB);
        o += shapeResult * shapePulse * (0.8 + fftA * 2.0) * (40.0 / hitDistance);
    }

    o += vec4(0.015, 0.01, 0.025, 0.0) * d;

    o += ribbonGlow;

    o += (vec4(1.0, 0.2, 0.4, 1.0) * accumA * COSMIC_RIBBON_BLOOM_BRIGHTNESS);
    o += (vec4(0.1, 0.6, 1.0, 1.0) * accumB * COSMIC_RIBBON_BLOOM_BRIGHTNESS);

    o = tanh(o / 4.6);
    vec2 ndc = u / p.xy;
    o *= 0.35 + 0.65 * pow(16.0 * ndc.x * ndc.y * (1.0 - ndc.x) * (1.0 - ndc.y), 0.25);

    return o;
}

vec4 mainB(vec2 u) {
    vec4 o;
    int side;
    vec4 vox;
    vec3 n,
         lights,
         blue = vec3(.15, .11, .57) * 1.5,
         red = vec3(.7, .11, .05) * 2.5;

    float fftA = 0.0;
    float fftB = 0.0;
    vec3 pA, pB;
    float la = 1e5, lb = 1e5;
    vec4 ribbonGlow = vec4(0.0);

    vec3 ro, rd;
    getCamera(u, ro, rd,T);
    vec3 p = ro;

    vec3 rs = sign(rd),
         dd = 1. / abs(rd),
         sd = (rs * (floor(p) - p) + (rs * 0.5) + 0.5) * dd;

    o = vec4(0);

    fftA = texture(iChannel1, vec2(fract(ro.z * 0.005), 0.25)).r;
    fftB = texture(iChannel1, vec2(fract(ro.z * 0.003 + 0.5), 0.25)).r;

    vox = marchVoxels(floor(p), sd, rs, dd, 300., .01, side, 16.);
    n = vec3(side == 0, side == 1, side == 2);
    vec3 id1 = vox.xyz;
    p = vox.xyz + .5 - rs * .5;

    lights = .3 * abs(sin(p) / dot(sin(.2 * T + p), vec3(5)));

    vec3 rp1 = ro + rd * vox.w;
    float rpFftA1 = texture(iChannel1, vec2(fract(rp1.z * 0.005), 0.25)).r;
    float rpFftB1 = texture(iChannel1, vec2(fract(rp1.z * 0.003 + 0.5), 0.25)).r;
    vec3 rA1 = rp1, rB1 = rp1;
    rA1.y += rpFftA1 * 2.5 * sin(rp1.z * 0.5);
    rB1.y -= rpFftB1 * 2.5 * cos(rp1.z * 0.5);
    float distA1 = length(rA1.xy + sin(cos(rA1.z / 16.) * 2. + vec2(0, 1.57)) * 6.) - 0.15;
    float distB1 = length(rB1.xy + sin(cos(rB1.z / 32.) * 2. - vec2(0, 1.57)) * 6.) - 0.15;
    la = min(la, distA1);
    lb = min(lb, distB1);

    vec3 ribbonIllumination1 = ((vec3(8.0, 1.5, 2.5) / max(distA1 * distA1, 0.02)) * (0.15 + rpFftA1)
                             + (vec3(1.0, 3.5, 9.0) / max(distB1 * distB1, 0.02)) * (0.15 + rpFftB1)) * (RIBBON_CORE_BRIGHTNESS * 0.002);

    float freq1 = smoothstep(16., 0., abs(id1.z - ro.z)) * 3. + hash13(id1 + floor(T)) * 1.5;
    float audioFactor1 = getPitch(freq1, 1.);
    audioFactor1 = max(mix(audioFactor1, (texture(iChannel1, vec2(0.05, 0.25)).r + texture(iChannel1, vec2(0.25, 0.25)).r + texture(iChannel1, vec2(0.65, 0.25)).r) * 0.33, 0.5), MIN_WALL_BRIGHTNESS);

    vec3 layer1 = .3 * tex(ro, rd, p, n) + ribbonIllumination1;
    o.rgb += layer1 * audioFactor1;

    p = ro * .95;
    sd = (rs * (floor(p) - p) + (rs * 0.5) + 0.5) * dd;

    vox = marchVoxels(floor(p), sd, rs, dd, 300., .01, side, 24.);
    n = vec3(side == 0, side == 1, side == 2);
    vec3 id2 = vox.xyz;
    p = vox.xyz + .5 - rs * .5;

    vec3 rp2 = ro + rd * vox.w;
    float rpFftA2 = texture(iChannel1, vec2(fract(rp2.z * 0.005), 0.25)).r;
    float rpFftB2 = texture(iChannel1, vec2(fract(rp2.z * 0.003 + 0.5), 0.25)).r;
    vec3 rA2 = rp2, rB2 = rp2;
    rA2.y += rpFftA2 * 2.5 * sin(rp2.z * 0.5);
    rB2.y -= rpFftB2 * 2.5 * cos(rp2.z * 0.5);
    float distA2 = length(rA2.xy + sin(cos(rA2.z / 16.) * 2. + vec2(0, 1.57)) * 6.) - 0.15;
    float distB2 = length(rB2.xy + sin(cos(rB2.z / 32.) * 2. - vec2(0, 1.57)) * 6.) - 0.15;
    la = min(la, distA2);
    lb = min(lb, distB2);

    vec3 ribbonIllumination2 = ((vec3(8.0, 1.5, 2.5) / max(distA2 * distA2, 0.02)) * (0.15 + rpFftA2)
                             + (vec3(1.0, 3.5, 9.0) / max(distB2 * distB2, 0.02)) * (0.15 + rpFftB2)) * (RIBBON_CORE_BRIGHTNESS * 0.002);

    float freq2 = smoothstep(16., 0., abs(id2.z - ro.z)) * 3. + hash13(id2 + floor(T)) * 1.5;
    float audioFactor2 = getPitch(freq2, 1.);
    audioFactor2 = max(mix(audioFactor2, (texture(iChannel1, vec2(0.05, 0.25)).r + texture(iChannel1, vec2(0.25, 0.25)).r + texture(iChannel1, vec2(0.65, 0.25)).r) * 0.33, 0.5), MIN_WALL_BRIGHTNESS);

    vec3 layer2 = 4. * red * tex(ro, rd, p, n) + ribbonIllumination2;
    o.rgb += layer2 * audioFactor2;

    lights += abs(blue * sin(p.yzx) / dot(sin(.3 * T + p.xyz), vec3(1e1)));

    o.rgb += lights * audioFactor2;
    o = clamp(o, 0.0, 1.0);

    for(float stepDist = 0.0; stepDist < 60.0; stepDist += 0.5) {
        vec3 rp = ro + rd * stepDist;
        float rpFftA = texture(iChannel1, vec2(fract(rp.z * 0.005), 0.25)).r;
        float rpFftB = texture(iChannel1, vec2(fract(rp.z * 0.003 + 0.5), 0.25)).r;

        vec3 rA = rp, rB = rp;
        rA.y += rpFftA * 2.5 * sin(rp.z * 0.5);
        rB.y -= rpFftB * 2.5 * cos(rp.z * 0.5);

        float distA = length(rA.xy + sin(cos(rA.z / 16.) * 2. + vec2(0, 1.57)) * 6.) - 0.15;
        float distB = length(rB.xy + sin(cos(rB.z / 32.) * 2. - vec2(0, 1.57)) * 6.) - 0.15;

        ribbonGlow += (RIBBON_CORE_BRIGHTNESS * vec4(8.0, 1.5, 2.5, 0) / max(distA * distA, 0.02)) * (0.15 + rpFftA) * 0.33
                    + (RIBBON_CORE_BRIGHTNESS * vec4(1.0, 3.5, 9.0, 0) / max(distB * distB, 0.02)) * (0.15 + rpFftB) * 0.33;
    }

    float reflectMaskA = 1.0 / (0.008 + la * la);
    float reflectMaskB = 1.0 / (0.008 + lb * lb);

    o += tanh(ribbonGlow / 1.5e3);
    o += (vec4(1.0, 0.2, 0.4, 1.0) * reflectMaskA * RIBBON_BLOOM_BRIGHTNESS) * (0.5 + fftA);
    o += (vec4(0.2, 0.5, 1.0, 1.0) * reflectMaskB * RIBBON_BLOOM_BRIGHTNESS) * (0.5 + fftB);
    return o;
}

vec3 cPath(float z) {
    return vec3(32.0 * cos(z * vec2(0.02, 0.01)), z);
}

vec4 mainC(vec2 u) {
    float cT = iTime * 3.7;
    vec3 p = iResolution;

    vec3 ro = cPath(cT * 10.0);
    vec3 Z = N(cPath(cT * 10.0 + 2.0) - ro);
    vec3 X = N(vec3(Z.z, 0.0, -Z.x));

    float dynamicRoll = texture(iChannel0, vec2(0.5) / p.xy).r;
    float rollAngle = dynamicRoll * SNARE_ROLL_INTENSITY;

    vec2 uv = (u + u - p.xy) / p.y;
    vec3 D = N(vec3(uv, 0.6) * mat3(-X, cross(X, Z), Z));
    D.xz *= R(cT / 4.5);
    D.xy *= R(rollAngle);

    vec4 o = vec4(0.0);
    vec4 ribbonGlow = vec4(0.0);

    float d = 0.0;
    float s = 0.0;
    float l = 0.0;
    float la = 0.0;
    float lb = 0.0;
    float c = 0.0;
    float i = 0.0;
    float fftA = 0.0;
    float fftB = 0.0;
    vec3 pA, pB;
    vec3 q;

    for (i = 0.0; i < 100.0; i++) {
        p = ro + D * d;
        p.xy -= cPath(p.z).xy;
        q = p;

        fftA = texture(iChannel1, vec2(fract(p.z * 0.005), 0.25)).r;
        fftB = texture(iChannel1, vec2(fract(p.z * 0.003 + 0.5), 0.25)).r;

        pA = p;
        pB = p;
        pA.y += fftA * 2.5 * sin(p.z * 0.5);
        pB.y -= fftB * 2.5 * cos(p.z * 0.5);

        la = length(pA.xy + sin(cos(pA.z / 16.0) * 2.0 + vec2(0.0, 1.57)) * 6.0) - 0.15;
        lb = length(pB.xy + sin(cos(pB.z / 32.0) * 2.0 - vec2(0.0, 1.57)) * 6.0) - 0.15;
        l = min(abs(la), abs(lb));

        s = 0.0;
        for (c = 40.0; c > 1.0; c *= 0.4) {
            p = abs(fract(p / c) * c - c / 2.0);
            s = max(s, min(p.x, min(p.y, p.z)) - c / 6.5);
            p = q;
        }

        q = abs(q);
        s = min(l * 0.8, max(0.7 * s, 0.7 * min(30.0 - q.x - q.y, 6.5 - q.y / 2.0)));
        d += s;

        ribbonGlow += (RIBBON_CORE_BRIGHTNESS * vec4(8.0, 1.5, 2.5, 0.0) / max(la * la, 0.005)) * (0.15 + fftA)
                    + (RIBBON_CORE_BRIGHTNESS * vec4(1.0, 3.5, 9.0, 0.0) / max(lb * lb, 0.005)) * (0.15 + fftB);

        o += 0.4 / max(s, 0.01);
    }

    o += 1.2e2 * abs(vec4(4.0, 1.2, 0.8, 0.0) / dot(cos(p.z / 10.0 + p / 20.0), vec3(1.0)));
    o += 0.8e2 * abs(vec4(0.5, 1.2, d / 6.0, 0.0) / dot(cos(p.z / 20.0 + p / 30.0), vec3(1.0)));

    o = tanh(o / 2.5e4);

    float finalRefA = length(pA.xy + sin(cos(pA.z / 16.0) * 2.0 + vec2(0.0, 1.57)) * 6.0) - 0.15;
    float finalRefB = length(pB.xy + sin(cos(pB.z / 32.0) * 2.0 - vec2(0.0, 1.57)) * 6.0) - 0.15;
    float reflectMaskA = 1.0 / (0.008 + finalRefA * finalRefA);
    float reflectMaskB = 1.0 / (0.008 + finalRefB * finalRefB);

    o += tanh(ribbonGlow / 1.5e3);
    o += (vec4(1.0, 0.2, 0.4, 1.0) * reflectMaskA * RIBBON_BLOOM_BRIGHTNESS) * (0.5 + fftA);
    o += (vec4(0.2, 0.5, 1.0, 1.0) * reflectMaskB * RIBBON_BLOOM_BRIGHTNESS) * (0.5 + fftB);
    return o;
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    float seg = SCENE_STAY_DURATION + TRANSITION_DURATION;
    float t = mod(iTime/1.56, seg * 3.0);
    float wA = 0.0, wB = 0.0, wC = 0.0;

    if (t < SCENE_STAY_DURATION) {
        wA = 1.0;
    } else if (t < seg) {
        float blend = smoothstep(SCENE_STAY_DURATION, seg, t);
        wA = 1.0 - blend;
        wB = blend;
    } else if (t < seg + SCENE_STAY_DURATION) {
        wB = 1.0;
    } else if (t < seg * 2.0) {
        float blend = smoothstep(seg + SCENE_STAY_DURATION, seg * 2.0, t);
        wB = 1.0 - blend;
        wC = blend;
    } else if (t < seg * 2.0 + SCENE_STAY_DURATION) {
        wC = 1.0;
    } else {
        float blend = smoothstep(seg * 2.0 + SCENE_STAY_DURATION, seg * 3.0, t);
        wA = blend;
        wC = 1.0 - blend;
    }

    vec4 colA = mainA(fragCoord);
    vec4 colB = mainB(fragCoord);
    vec4 colC = mainC(fragCoord);

    fragColor = colA * wA + colB * wB + colC * wC;
}
