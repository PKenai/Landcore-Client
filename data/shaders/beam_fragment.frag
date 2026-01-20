// Laser Beam Shader (Static, No Noise)
uniform float u_Time;
uniform vec4 u_Color; // Base color (e.g., Red or Purple)
varying vec2 v_TexCoord;

void main() {
    // x: length, y: thickness (0..1)
    // Map y to range -1.0 to 1.0 (0 at center)
    float y = (v_TexCoord.y - 0.5) * 2.0;
    float dist = abs(y);

    // --- LASER PROFILE ---
    
    // 1. Core (Bright White Center)
    // Sharp falloff near 0. Width approx 30% of total thickness.
    float coreWidth = 0.3;
    float coreMask = smoothstep(coreWidth, 0.0, dist);
    
    // 2. Aura (Translucent Glow)
    // Soft falloff from center to edge.
    // Starts fading immediately, reaches 0 at edge (1.0).
    float auraMask = smoothstep(1.0, 0.2, dist);
    
    // --- COMPOSITION ---
    
    // Aura Color: Use the uniform color (e.g. from Lua).
    // If u_Color is weak, boost it slightly.
    vec3 auraColorRGB = u_Color.rgb * 1.5; 
    
    // Core Color: Pure White.
    vec3 coreColorRGB = vec3(1.0, 1.0, 1.0);
    
    // Mix Core on top of Aura
    // If coreMask is high, show White. Else show Aura Color.
    vec3 finalColor = mix(auraColorRGB, coreColorRGB, coreMask);
    
    // Alpha Logic
    // Combined opacity of Core + Aura.
    // Core is solid (1.0). Aura is translucent (e.g. 0.5 max).
    // We want the edge to fade to 0.
    
    float auraAlpha = 0.6 * auraMask; // Max aura opacity 0.6
    float coreAlpha = 1.0 * coreMask; // Core is opaque
    
    // Combine alphas (Core overrides Aura)
    float finalAlpha = max(coreAlpha, auraAlpha);
    
    // Hard clamp at edge to prevent bleeding if smoothstep allows it
    finalAlpha *= smoothstep(1.0, 0.8, dist);

    gl_FragColor = vec4(finalColor, finalAlpha);
}
