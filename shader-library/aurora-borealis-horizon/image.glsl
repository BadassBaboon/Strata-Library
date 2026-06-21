void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 flippedCoord = vec2(fragCoord.x, iResolution.y - fragCoord.y);
    vec2 uv = flippedCoord / iResolution.xy;

    vec2 vanish = vec2(0.56, 0.51);

    float belowHorizon = step(0.51, uv.y);
    float distFromHorizon = uv.y - 0.51;

    vec2 sampleUV = uv;
    sampleUV.y = mix(uv.y, 2.0 * 0.51 - uv.y, belowHorizon);

    vec2 dir = sampleUV - vanish;
    float rightSide = step(0.0, dir.x);
    float rightSoft = smoothstep(-0.142, 0.142, dir.x);
    float r = length(dir);
    float ang = atan(-dir.y, dir.x);

    float bendStrength = pow(clamp(r, 0.0, 1.0), 1.25);
    float bendFactor = max(1.0 - 0.19 * bendStrength * rightSide, 0.05);
    float angBent = ang * bendFactor;

    float angT = clamp(angBent / 1.19, 0.0, 1.0);

    vec3 auroraCol = vec3(1, 0.7, 0.32);
    auroraCol = mix(auroraCol, vec3(1, 0.55, 0.3), smoothstep(0.02, 0.25, angT));
    auroraCol = mix(auroraCol, vec3(1, 0.5, 0.78), smoothstep(0.2, 0.5, angT));
    auroraCol = mix(auroraCol, vec3(0.15, 0.6, 0.6), smoothstep(0.49, 0.85, angT));

    vec3 baseSky = mix(vec3(0., 0.23, 0.7), vec3(0., 0.07, 0.34), smoothstep(0.51, 0.0, sampleUV.y) * 1.);

    float auroraAlpha = 1.0 - smoothstep(1.19 - 0.2, 1.19 + 0.2, angBent);
    auroraAlpha *= smoothstep(-0.1, 0.05, ang);
    auroraAlpha *= rightSoft;

    float reflectionMask = mix(1.0, 0.85 * (1.0 - smoothstep(0.0, 0.22, distFromHorizon)), belowHorizon);
    auroraAlpha *= reflectionMask;

    float heightAbove = max(0.51 - uv.y, 0.0);
    float heightFalloff = mix(0.53, 1.0, 1.0 - smoothstep(0.0, 1., heightAbove));
    auroraAlpha *= heightFalloff;

    vec3 col = mix(baseSky, auroraCol, auroraAlpha);

    float waterFade = smoothstep(0.0, 0.22 * 2.0, distFromHorizon);
    col = mix(col, vec3(0, 0.04, 0.22), belowHorizon * waterFade * 0.9);

    float distToHorizon = abs(uv.y - 0.51);
    float horizonLine = smoothstep(0.002, 0.0, distToHorizon);
    float horizonGlow = smoothstep(0.06, 0.0, distToHorizon);
    float aboveHorizon = 1.0 - belowHorizon;
    float horizonWide = smoothstep(0.18, 0.0, distToHorizon) * aboveHorizon;

    float horizonStrength = smoothstep(0.55, 0.0, abs(uv.x - 0.56));
    float wideStrength = smoothstep(1., 0.0, abs(uv.x - 0.56));
    float leftSideMask = 1.0 - rightSoft;

    col = mix(col, vec3(1, 1, 1), horizonLine * horizonStrength);
    col += vec3(1, 1, 1) * horizonGlow * horizonStrength * 0.7 * 0.3;
    col += vec3(1, 1, 1) * horizonWide * wideStrength * leftSideMask * 0.55 * 0.5;

    vec2 vanishPx = vec2(0.56, 0.51);
    vec2 bloomDelta = (uv - vanishPx) * vec2(iResolution.x / iResolution.y, 1.0);
    bloomDelta.x /= 2.89;
    float vanishDist = length(bloomDelta);
    float bloom = smoothstep(0.035, 0.0, vanishDist);
    col += vec3(1, 1, 1) * bloom * 0.64;

    fragColor = vec4(col * 1., 1.);
}