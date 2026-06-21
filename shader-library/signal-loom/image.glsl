// ============================================================
//  SIGNAL LOOM
//  Paste into Shadertoy (no channels needed)
//
//  A woven truchet circuit: two overlapping scales of arc
//  tiles form an endless braided maze, and packets of light
//  race along the threads. Pure 2D — the mesmerism comes from
//  watching signals split, merge, and orbit forever
//
// This work is dedicated to the public domain under CC0 1.0: 
// https://creativecommons.org/publicdomain/zero/1.0/
// ============================================================
#define PI 3.14159265

float hash21(vec2 p){
    p = fract(p*vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x*p.y);
}

// distance to the two quarter-circle arcs of a truchet tile,
// plus a coordinate along the arc for the traveling pulses
vec3 truchet(vec2 uv, float scale, float speed, float seed){
    uv *= scale;
    vec2 id = floor(uv);
    vec2 gv = fract(uv) - 0.5;
    float n = hash21(id + seed);
    if(n < 0.5) gv.x = -gv.x;                 // flip half the tiles
    // arcs centered on two opposite corners
    vec2 cUv = gv - sign(gv.x + gv.y + 0.001)*0.5;
    float d  = abs(length(cUv) - 0.5);        // distance to thread
    // angle along the arc -> flow coordinate
    float a = atan(cUv.x, cUv.y);             // -PI..PI
    float flow = a/(0.5*PI);                  // ~ -2..2 across the arc
    // make flow direction consistent-ish per tile so pulses travel
    float checker = mod(id.x + id.y, 2.0)*2.0 - 1.0;
    flow *= checker * (n < 0.5 ? 1.0 : -1.0);
    float pulse = fract(flow*0.5 - iTime*speed + hash21(id+seed+7.0));
    return vec3(d, pulse, n);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // screen-space coords, kept stable for the vignette
    vec2 uv0 = (2.0*fragCoord - iResolution.xy)/iResolution.y;
    vec2 uv = uv0;

    // slow drift and rotation of the whole loom
    float c = cos(iTime*0.03), s = sin(iTime*0.03);
    uv = mat2(c,-s,s,c)*uv;
    uv += vec2(iTime*0.05, iTime*0.02);

    vec3 col = vec3(0.0);
    float px = 2.0/iResolution.y;             // pixel size in uv

    // ---- layer 1 : coarse copper weave -------------------------
    {
        vec3 tr = truchet(uv, 2.0, 0.35, 0.0);
        float w = 0.045;
        float thread = smoothstep(w+px, w-px, tr.x);
        // braided shading: darken where the "under" strand passes
        float weave = 0.6 + 0.4*sin(tr.x*60.0);
        vec3 base = vec3(0.10, 0.045, 0.02)*thread*weave*3.0;
        float packet = pow(smoothstep(0.35, 0.0, abs(tr.y - 0.5)), 6.0);
        vec3 glowCol = vec3(1.0, 0.45, 0.12);          // ember packets
        col += base;
        col += glowCol * packet * thread * 2.2;
        col += glowCol * packet * 0.10/(tr.x + 0.02);  // halo off the wire
    }

    // ---- layer 2 : fine cyan filaments, counter-flowing --------
    {
        vec3 tr = truchet(uv + 13.7, 6.0, -0.6, 5.0);
        float w = 0.03;
        float thread = smoothstep(w+px*3.0, w-px*3.0, tr.x);
        vec3 base = vec3(0.0, 0.05, 0.07)*thread*2.0;
        float packet = pow(smoothstep(0.3, 0.0, abs(tr.y - 0.5)), 8.0);
        vec3 glowCol = vec3(0.15, 0.9, 1.0);
        col += base*0.7;
        col += glowCol * packet * thread * 1.6;
        col += glowCol * packet * 0.05/(tr.x + 0.02);
    }

    // breathing exposure + soft vignette (anchored to screen, not drift)
    col *= 0.85 + 0.15*sin(iTime*0.5);
    col *= 1.0 - 0.4*dot(uv0*0.3, uv0*0.3);
    col = 1.0 - exp(-col*1.6);                // filmic-ish rolloff
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}