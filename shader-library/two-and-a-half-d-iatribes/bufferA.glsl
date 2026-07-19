#define SNARE_THRESHOLD 0.45      // Minimum volume to trigger
#define SNARE_SENSITIVITY 2.05     // Response multiplier 
#define DECAY_RATE 0.92           // Lower = snappier return, Higher = longer roll hold

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Only use the bottom-left pixel to store data
    if (floor(fragCoord) == vec2(0.0)) {
        
        // 1. Read the previous frame's roll value from itself
        float lastRoll = texture(iChannel1, vec2(0.5) / iResolution.xy).r;
        
        // 2. Smoothly decay the last roll back toward 0.0
        lastRoll *= DECAY_RATE;
        
        // 3. Sample real-time snare data
        float snareAudio = texture(iChannel0, vec2(0.55, 0.0)).r;
        
        // 4. Threshold check
        if (snareAudio > SNARE_THRESHOLD) {
            float strikeIntensity = (snareAudio - SNARE_THRESHOLD) * SNARE_SENSITIVITY;
            
            // Alternating directions based on time so it doesn't just lean one way
            float currentStrike = strikeIntensity * sin(iTime * 8.0);
            
            // Take the largest movement (prevents sudden cancels if audio fluctuates)
            if (abs(currentStrike) > abs(lastRoll)) {
                lastRoll = currentStrike;
            }
        }
        
        // Save the value into the Red channel
        fragColor = vec4(lastRoll, 0.0, 0.0, 1.0);
    } else {
        discard;
    }
}