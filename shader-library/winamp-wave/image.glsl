// Winamp Wave

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 rayDir = normalize(vec3(2.0 * fragCoord - iResolution.xy, -iResolution.x));
    float rayDistance = 0.0;
    vec3 accumulatedColor = vec3(0.0);

    // Pre-fetch 4 distinct audio frequencies: Bass, Low-Mid, High-Mid, Treble
    vec4 audioBands = vec4(
        texture(iChannel0, vec2(0.05, 0.25)).x,
        texture(iChannel0, vec2(0.25, 0.25)).x,
        texture(iChannel0, vec2(0.50, 0.25)).x,
        texture(iChannel0, vec2(0.75, 0.25)).x
    );

    // Cool Spectrum Palette (Blue, Purple, Green, Teal)
    vec3 colorBass    = vec3(0.4, 0.0, 0.9); // Electric Purple
    vec3 colorLowMid  = vec3(0.0, 0.2, 1.0); // Deep Blue
    vec3 colorHighMid = vec3(0.0, 0.8, 0.6); // Teal
    vec3 colorTreble  = vec3(0.0, 0.9, 0.2); // Vibrant Green

    for(float stepCount = 0.0; stepCount < 100.0; stepCount++) {
        vec3 rayPos = rayDir * rayDistance;
        
        // Map space into 4 distinct "strand" zones using a spatial sine wave.
        float spatialPhase = rayPos.x * 1.5 + rayPos.z * 1.0;
        
        // Offset the phase by Pi/2 for each band to separate them in space
        vec4 phases = spatialPhase + vec4(0.0, 1.5708, 3.1415, 4.7123); 
        
        // Use a high power to sharpen the bands and create gaps between them
        vec4 rawWeights = pow(max(sin(phases), 0.0), vec4(6.0));
        float strandPresence = max(max(rawWeights.x, rawWeights.y), max(rawWeights.z, rawWeights.w));
        
        // Normalize the weights to blend colors and audio data
        vec4 strandWeights = rawWeights / (dot(rawWeights, vec4(1.0)) + 0.0001);
        
        // The specific audio frequency and color driving this exact point in space
        float localAudioFreq = dot(strandWeights, audioBands);
        vec3 localColor = strandWeights.x * colorBass + 
                          strandWeights.y * colorLowMid + 
                          strandWeights.z * colorHighMid + 
                          strandWeights.w * colorTreble;

        // Apply fractal geometry deformation
        for (float scale = 0.1; scale < 1.0; scale *= 2.0) {
            float waveAmplitude = 0.002 + (0.045 * localAudioFreq);
            float displacement = dot(sin(rayPos * scale * 16.0), vec3(waveAmplitude)) / scale;
            rayPos -= displacement;

            float angle = 0.3 * iTime;
            mat2 rotation = mat2(cos(angle), -sin(angle), 
                                 sin(angle), cos(angle));
            rayPos.xz *= rotation;
        }

        // Distance to the undulating "surface"
        float distanceToSurface = 0.01 + abs(rayPos.y);
        float glowIntensity = 0.001 / (distanceToSurface * distanceToSurface + 0.0015);
        glowIntensity *= strandPresence;

        // Depth Fade: Darken waves that are further away to create contrast 
        float depthFade = exp(-rayDistance * 0.2);

        // Accumulate light
        accumulatedColor += localColor * glowIntensity * depthFade;

        // Advance the ray
        rayDistance += distanceToSurface;
    }
    fragColor = vec4(1.0 - exp(-accumulatedColor * 0.08), 1.0);
}