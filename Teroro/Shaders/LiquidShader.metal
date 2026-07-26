#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 liquidShader(float2 position, half4 color, float time, float2 size) {
    float2 uv = position / size;
    
    // Wave warp for organic movement
    float2 warp = float2(
        sin(uv.y * 4.0 + time * 1.0) * 0.1 + cos(uv.x * 3.0 - time * 0.7) * 0.08,
        cos(uv.x * 4.0 + time * 0.8) * 0.1 + sin(uv.y * 3.5 - time * 0.9) * 0.08
    );
    
    uv += warp;
    
    // Rich gradient colors matching the requested palette
    half3 c1 = half3(0.35, 0.25, 0.9);  // Bright purple/violet
    half3 c2 = half3(0.09, 0.55, 0.95); // Royal blue
    half3 c3 = half3(0.05, 0.02, 0.12); // Deep dark space background
    
    float wave = sin(uv.x * 2.0 + time * 0.5) * 0.5 + 0.5;
    float wave2 = cos(uv.y * 1.5 - time * 0.3) * 0.5 + 0.5;
    
    half3 finalColor = mix(c1, c2, half(wave));
    finalColor = mix(finalColor, c3, half(wave2 * 0.7));
    
    return half4(finalColor, 1.0);
}
