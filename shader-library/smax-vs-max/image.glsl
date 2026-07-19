// k controls smoothness (larger = smoother) / k 控制平滑度（值越大越平滑）
float smax(float x, float y, float k) {
    return (x + y + sqrt(pow(x - y, 2.0) + k)) / 2.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = 4.0 * (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    float f1 = sin(uv.x + iTime);
    float f2 = cos(uv.x - iTime * 0.5) * 1.5;

    float k = (iMouse.z > 0.0) ? (iMouse.x / iResolution.x) * 1.5 : 0.1;

    float y_max = max(f1, f2);
    float y_smax = smax(f1, f2, k);

    // Background and grid
    vec3 col = vec3(0.12);
    vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
    col = mix(col, vec3(0.25), 1.0 - smoothstep(0.0, 1.5, min(grid.x, grid.y)));
    col = mix(col, vec3(0.5), 1.0 - smoothstep(0.0, 2.0, abs(uv.x)/fwidth(uv.x))); // Y-axis / Y轴
    col = mix(col, vec3(0.5), 1.0 - smoothstep(0.0, 2.0, abs(uv.y)/fwidth(uv.y))); // X-axis / X轴

    // Draw base curves
    float d_f1 = abs(uv.y - f1) / fwidth(uv.y - f1);
    float d_f2 = abs(uv.y - f2) / fwidth(uv.y - f2);
    col = mix(col, vec3(0.3, 0.4, 0.7), 1.0 - smoothstep(0.0, 1.5, d_f1));
    col = mix(col, vec3(0.3, 0.7, 0.4), 1.0 - smoothstep(0.0, 1.5, d_f2));

    // Notice the sharp corners
    float d_max = abs(uv.y - y_max) / fwidth(uv.y - y_max);
    col = mix(col, vec3(0.9, 0.2, 0.2), 1.0 - smoothstep(0.0, 2.0, d_max));

    // Smoothly transitions over the corners
    float d_smax = abs(uv.y - y_smax) / fwidth(uv.y - y_smax);
    col = mix(col, vec3(1.0, 0.8, 0.1), 1.0 - smoothstep(0.0, 1.5, d_smax));

    fragColor = vec4(col, 1.0);
}