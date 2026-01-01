varying vec2 v_TexCoord;
uniform vec4 u_Color;
uniform sampler2D u_Tex0;
uniform float u_Time;

void main()
{
    vec4 color = texture2D(u_Tex0, v_TexCoord) * u_Color;

    if(color.a < 0.01)
        discard;

    // Coordenadas normalizadas (0.0 a 1.0)
    vec2 coord = v_TexCoord;

    // Centro da textura (0.5, 0.5)
    vec2 center = vec2(0.5, 0.5);

    // Distância do centro (0.0 = centro, ~0.707 = canto)
    float distFromCenter = distance(coord, center);

    // Área de brilho branco no centro (raio médio/grande)
    float glowRadius = 0.4; // 40% do raio total
    float glowIntensity = 1.0 - smoothstep(0.0, glowRadius, distFromCenter);

    // Efeito de pulsação vermelho nas bordas (tons de vida)
    float pulse = sin(u_Time * 2.0) * 0.3 + 0.7;

    // Aplicar tom vermelho pulsante nas bordas
    vec3 lifeTint = vec3(1.0, 0.7 - pulse * 0.3, 0.7 - pulse * 0.3);

    // Brilho branco no centro com pulsação suave
    float centerPulse = sin(u_Time * 1.5) * 0.2 + 0.8;
    vec3 centerGlow = vec3(1.5, 1.5, 1.5) * centerPulse; // Branco brilhante

    // Misturar entre o efeito de vida nas bordas e brilho no centro
    vec3 finalTint = mix(lifeTint, centerGlow, glowIntensity * 0.8);

    color.rgb *= finalTint;

    gl_FragColor = color;
}
