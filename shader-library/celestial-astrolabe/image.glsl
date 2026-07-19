// Shape
// use GPT5.5 for assistence

#ifdef GL_ES
precision mediump float;
#endif

#define TAU 6.28318530718
#define S(a,b,x) smoothstep(a,b,x)

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(41.0, 289.0))) * 43758.5453);
}

float stroke(float d, float w, float s) {
    return 1.0 - S(w, w + s, abs(d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;
    float aa = 1.4 / iResolution.y;
    float h = -0.22;

    float skyMask = step(h, uv.y);
    float blend = S(h - 0.06, h + 0.07, uv.y);
    vec3 ink = vec3(0.014, 0.018, 0.040);
    vec3 dusk = vec3(0.180, 0.090, 0.070);
    vec3 deep = vec3(0.006, 0.034, 0.044);
    float y = mix(h + abs(uv.y - h), uv.y, blend);
    vec3 sky = mix(dusk, ink, S(h, 0.74, y));
    vec3 water = mix(sky, deep, 0.25 + 0.52 * (1.0 - S(h - 0.78, h, uv.y)));
    vec3 col = mix(water, sky, blend);

    float mist = 1.0 - S(0.0, 0.18, abs(uv.y - h));
    col += mist * vec3(0.16, 0.08, 0.04);
    col += (1.0 - S(0.08, 0.78, length(uv - vec2(0.0, -0.02)))) * vec3(0.035, 0.026, 0.018);

    vec2 g = uv * 30.0 + vec2(0.0, t * 0.025);
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    float n = hash(id);
    float stars = step(0.962, n) * (1.0 - S(0.010, 0.043, length(f))) * (0.72 + 0.28 * sin(t * 2.0 + n * TAU));
    col += stars * skyMask * vec3(0.95, 0.84, 0.62);

    vec2 c = vec2(0.0, 0.075);
    vec2 p = uv - c;
    float r = length(p);
    float a = atan(p.y, p.x);
    vec3 gold = vec3(0.92, 0.62, 0.34);
    vec3 jade = vec3(0.32, 0.76, 0.66);
    vec3 ivory = vec3(0.92, 0.86, 0.70);

    float rose = stroke(r - (0.205 + 0.032 * cos(7.0 * a - t * 0.45)), 0.003, aa * 2.0);
    float rings = stroke(r - 0.325, 0.003, aa * 2.0) + stroke(r - 0.250, 0.0025, aa * 2.0) + stroke(r - 0.092, 0.004, aa * 2.0);
    float tick = stroke(r - 0.365, 0.004, aa * 2.0) * (1.0 - S(0.055, 0.080, abs(fract(a / TAU * 44.0 + 0.5 + t * 0.015) - 0.5)));
    float halo = 1.0 - S(0.14, 0.50, r);
    col += halo * vec3(0.028, 0.034, 0.044);
    col += rings * gold * 1.10 + rose * mix(jade, gold, 0.42) * 1.35 + tick * ivory * 0.78;

    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        vec2 o = vec2(cos(t * 0.32 + fi * TAU / 4.0), sin(t * 0.32 + fi * TAU / 4.0)) * 0.325;
        float m = 1.0 - S(0.012, 0.022, length(p - o));
        col += m * mix(ivory, gold, fi / 3.0);
    }

    vec2 rp = vec2(uv.x + 0.020 * sin((uv.y - h) * 30.0 + t), 2.0 * h - uv.y - c.y);
    float rr = length(rp);
    float ra = atan(rp.y, rp.x);
    float ref = stroke(rr - 0.325, 0.005, 0.020) + stroke(rr - (0.205 + 0.032 * cos(7.0 * ra - t * 0.45)), 0.004, 0.028);
    float fade = (1.0 - blend) * S(h - 0.66, h - 0.02, uv.y) * (1.0 - S(0.0, 0.55, abs(uv.x)));
    float ripple = 1.0 - S(0.012, 0.040, abs(mod((uv.y - h) * 26.0 + sin(uv.x * 8.0 + t), 1.0) - 0.5));
    col += fade * (ref * gold * 0.22 + ripple * jade * 0.11);

    col *= 0.66 + 0.34 * (1.0 - S(0.32, 1.18, length(uv)));
    col += vec3(hash(fragCoord.xy + floor(t * 24.0)) - 0.5) * 0.008;
    col = max(col, vec3(0.0));
    col = pow(col / (vec3(1.0) + col), vec3(0.94));
    fragColor = vec4(col, 1.0);
}
