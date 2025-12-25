uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform sampler2D u_Tex0;
uniform float u_Time;

// Função para gerar padrão de pedra procedural (sem textura externa)
float stonePattern(vec2 uv, float time) {
    // Cria múltiplas camadas de padrão de pedra usando noise procedural
    float pattern1 = sin(uv.x * 12.0 + time * 0.5) * sin(uv.y * 12.0 + time * 0.6);
    float pattern2 = sin(uv.x * 18.0 - time * 0.4) * sin(uv.y * 18.0 - time * 0.5);
    float pattern3 = sin(uv.x * 25.0 + time * 0.7) * sin(uv.y * 25.0 + time * 0.3);
    float pattern4 = sin(uv.x * 8.0 + time * 0.3) * sin(uv.y * 8.0 + time * 0.4);
    
    // Combina os padrões
    float combined = (pattern1 + pattern2 + pattern3 + pattern4) / 4.0;
    
    // Cria variação de intensidade
    float intensity = smoothstep(-0.5, 0.5, combined);
    intensity = pow(intensity, 0.7);
    
    return intensity;
}

// Função para detectar bordas e criar outline grosso
float detectEdge(vec2 uv, sampler2D tex) {
    // Múltiplas camadas de offset para criar outline grosso
    float offset1 = 0.002; // Camada interna
    float offset2 = 0.004; // Camada média
    float offset3 = 0.006; // Camada externa
    float offset4 = 0.008; // Camada mais externa
    
    vec4 center = texture2D(tex, uv);
    
    // Se o pixel atual tem conteúdo, não é outline
    if (center.a > 0.1) {
        return 0.0;
    }
    
    // Detecta outline em múltiplas camadas (cria outline grosso)
    float outline = 0.0;
    
    // Camada 1 (mais próxima)
    vec4 up1 = texture2D(tex, uv + vec2(0.0, -offset1));
    vec4 down1 = texture2D(tex, uv + vec2(0.0, offset1));
    vec4 left1 = texture2D(tex, uv + vec2(-offset1, 0.0));
    vec4 right1 = texture2D(tex, uv + vec2(offset1, 0.0));
    vec4 upLeft1 = texture2D(tex, uv + vec2(-offset1, -offset1));
    vec4 upRight1 = texture2D(tex, uv + vec2(offset1, -offset1));
    vec4 downLeft1 = texture2D(tex, uv + vec2(-offset1, offset1));
    vec4 downRight1 = texture2D(tex, uv + vec2(offset1, offset1));
    float neighborAlpha1 = (up1.a + down1.a + left1.a + right1.a + 
                           upLeft1.a + upRight1.a + downLeft1.a + downRight1.a) / 8.0;
    
    // Camada 2
    vec4 up2 = texture2D(tex, uv + vec2(0.0, -offset2));
    vec4 down2 = texture2D(tex, uv + vec2(0.0, offset2));
    vec4 left2 = texture2D(tex, uv + vec2(-offset2, 0.0));
    vec4 right2 = texture2D(tex, uv + vec2(offset2, 0.0));
    vec4 upLeft2 = texture2D(tex, uv + vec2(-offset2, -offset2));
    vec4 upRight2 = texture2D(tex, uv + vec2(offset2, -offset2));
    vec4 downLeft2 = texture2D(tex, uv + vec2(-offset2, offset2));
    vec4 downRight2 = texture2D(tex, uv + vec2(offset2, offset2));
    float neighborAlpha2 = (up2.a + down2.a + left2.a + right2.a + 
                           upLeft2.a + upRight2.a + downLeft2.a + downRight2.a) / 8.0;
    
    // Camada 3
    vec4 up3 = texture2D(tex, uv + vec2(0.0, -offset3));
    vec4 down3 = texture2D(tex, uv + vec2(0.0, offset3));
    vec4 left3 = texture2D(tex, uv + vec2(-offset3, 0.0));
    vec4 right3 = texture2D(tex, uv + vec2(offset3, 0.0));
    vec4 upLeft3 = texture2D(tex, uv + vec2(-offset3, -offset3));
    vec4 upRight3 = texture2D(tex, uv + vec2(offset3, -offset3));
    vec4 downLeft3 = texture2D(tex, uv + vec2(-offset3, offset3));
    vec4 downRight3 = texture2D(tex, uv + vec2(offset3, offset3));
    float neighborAlpha3 = (up3.a + down3.a + left3.a + right3.a + 
                           upLeft3.a + upRight3.a + downLeft3.a + downRight3.a) / 8.0;
    
    // Camada 4 (mais externa)
    vec4 up4 = texture2D(tex, uv + vec2(0.0, -offset4));
    vec4 down4 = texture2D(tex, uv + vec2(0.0, offset4));
    vec4 left4 = texture2D(tex, uv + vec2(-offset4, 0.0));
    vec4 right4 = texture2D(tex, uv + vec2(offset4, 0.0));
    vec4 upLeft4 = texture2D(tex, uv + vec2(-offset4, -offset4));
    vec4 upRight4 = texture2D(tex, uv + vec2(offset4, -offset4));
    vec4 downLeft4 = texture2D(tex, uv + vec2(-offset4, offset4));
    vec4 downRight4 = texture2D(tex, uv + vec2(offset4, offset4));
    float neighborAlpha4 = (up4.a + down4.a + left4.a + right4.a + 
                           upLeft4.a + upRight4.a + downLeft4.a + downRight4.a) / 8.0;
    
    // Combina todas as camadas para criar outline grosso
    // Camadas mais externas têm menos intensidade, mas ainda contribuem
    outline = neighborAlpha1 * 1.0 +  // Camada mais próxima (mais intensa)
              neighborAlpha2 * 0.8 +  // Camada média
              neighborAlpha3 * 0.6 +  // Camada externa
              neighborAlpha4 * 0.4;   // Camada mais externa
    
    // Normaliza e intensifica
    outline = min(outline, 1.0) * 1.5;
    
    return outline;
}

// Função para gerar cor de pedra
vec3 getStoneColor(float pattern, float time) {
    // Cores de pedra: cinza, marrom, bege
    vec3 darkStone = vec3(0.45, 0.42, 0.38); // Pedra escura (marrom acinzentado)
    vec3 midStone = vec3(0.65, 0.62, 0.58); // Pedra média (bege acinzentado)
    vec3 lightStone = vec3(0.75, 0.72, 0.68); // Pedra clara (bege claro)
    
    // Varia a cor baseada no padrão
    vec3 baseColor = mix(darkStone, midStone, pattern);
    baseColor = mix(baseColor, lightStone, pattern * 0.5);
    
    // Adiciona pulsação suave
    float pulse = sin(time * 1.5) * 0.05 + 0.95;
    baseColor *= pulse;
    
    return baseColor;
}

void main()
{
    // Carrega a textura original
    vec4 originalColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    
    // Descarta pixels completamente transparentes
    if(originalColor.a < 0.01) {
        discard;
    }
    
    // Gera padrão de pedra procedural
    float stonePattern = stonePattern(v_TexCoord, u_Time);
    
    // Detecta bordas para criar outline
    float outline = detectEdge(v_TexCoord, u_Tex0);
    
    // Gera cor de pedra
    vec3 stoneColor = getStoneColor(stonePattern, u_Time);
    
    // Cor do outline (pedra escura e visível)
    vec3 outlineColor = vec3(0.4, 0.37, 0.33); // Pedra escura para outline grosso
    
    // Aplica cor de pedra ao personagem
    vec3 finalColor = originalColor.rgb;
    
    // Aplica efeito de pedra baseado nas cores do outfit
    if(texcolor.r > 0.9) {
        // Vermelho -> Pedra
        vec4 outfitColor = texcolor.g > 0.9 ? u_Color[0] : u_Color[1];
        finalColor = originalColor.rgb * outfitColor.rgb * stoneColor;
    } else if(texcolor.g > 0.9) {
        // Verde -> Pedra
        vec4 outfitColor = u_Color[2];
        finalColor = originalColor.rgb * outfitColor.rgb * stoneColor;
    } else if(texcolor.b > 0.9) {
        // Azul -> Pedra escura
        vec4 outfitColor = u_Color[3];
        vec3 darkStone = stoneColor * 0.8; // Mais escuro para azul
        finalColor = originalColor.rgb * outfitColor.rgb * darkStone;
    } else {
        // Outras áreas -> Aplica pedra diretamente
        finalColor = originalColor.rgb * stoneColor;
    }
    
    // Adiciona variação de textura baseada no padrão
    finalColor = mix(finalColor, finalColor * 1.1, stonePattern * 0.3);
    
    // Aplica outline grosso ao redor do personagem
    if (outline > 0.0) {
        // Para pixels de outline, usa a cor de pedra diretamente
        finalColor = mix(finalColor, outlineColor, outline);
        // Adiciona brilho e intensidade no outline para ficar mais visível
        finalColor += outlineColor * outline * 0.8;
        // Garante que o outline seja bem visível
        finalColor = mix(finalColor, outlineColor, outline * 0.9);
    }
    
    // Aumenta um pouco o brilho geral
    finalColor *= 1.15;
    
    // Output final
    gl_FragColor = vec4(finalColor, originalColor.a);
}
