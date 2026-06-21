// Fiber optics
// By Noztol

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uvScreen = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    vec2 offset = vec2(
        sin(iTime * 0.6) * 0.25, // Controls Left/Right turning
        cos(iTime * 0.45) * 0.25 // Controls Up/Down turning
    );
    uvScreen -= offset;

    float radius = length(uvScreen);
    float angle = atan(uvScreen.y, uvScreen.x);
    float depth = 1.0 / radius; 


    float timeTwist = sin(iTime * 0.15) * 6.28318; 
    float twistedAngle = angle + timeTwist + (depth * 0.5);
    vec2 uv = vec2(depth + iTime * 6.0, twistedAngle);
    
    float numCables = 80.0; 
    
    float cableId = floor((twistedAngle * numCables) / 6.28318);
    cableId = mod(cableId, numCables); 
    
    float rand = fract(sin(cableId * 12.9898) * 43758.5453);

    float cableMask = cos(twistedAngle * numCables);
    cableMask = smoothstep(0.4, 0.8, cableMask); 

    float pulseSpeed = 10.0 + rand * 15.0; 
    float pulseFreq = 2.0 + rand * 3.0;  
    
    float pulse = sin(uv.x * pulseFreq - iTime * pulseSpeed + rand * 20.0);
    pulse = smoothstep(0.9, 1.0, pulse); 

    vec3 colorA = vec3(0.0, 0.6, 1.0); // Cyan/Blue
    vec3 colorB = vec3(1.0, 0.1, 0.8); // Pink/Magenta
    vec3 colorC = vec3(0.1, 1.0, 0.3); // Neon Green

    vec3 cableColor = mix(colorA, colorB, fract(rand * 5.43));
    cableColor = mix(cableColor, colorC, fract(rand * 8.91));

    vec3 finalColor = cableMask * cableColor * 0.15; 
    finalColor += cableMask * pulse * cableColor * 3.0; 
    finalColor *= smoothstep(0.0, 0.8, radius);
    fragColor = vec4(finalColor, 1.0);
}