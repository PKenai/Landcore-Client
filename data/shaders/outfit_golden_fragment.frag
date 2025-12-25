uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
varying vec2 v_TexCoord3;
uniform sampler2D u_Tex0;
uniform sampler2D u_Tex1;
uniform float u_Time;

// Função para gerar sparkles espalhados e difusos
float sparkle(vec2 uv, float time) {
    // Cria múltiplas camadas de sparkles espalhados
    float sparkle1 = sin(uv.x * 25.0 + time * 2.5) * sin(uv.y * 25.0 + time * 3.0);
    float sparkle2 = sin(uv.x * 20.0 - time * 2.0) * sin(uv.y * 20.0 - time * 2.5);
    float sparkle3 = sin(uv.x * 30.0 + time * 3.0) * sin(uv.y * 30.0 + time * 2.0);
    float sparkle4 = sin(uv.x * 18.0 + time * 1.8) * sin(uv.y * 18.0 + time * 2.2);
    float sparkle5 = sin(uv.x * 35.0 - time * 2.8) * sin(uv.y * 35.0 - time * 1.5);
    
    // Combina os sparkles de forma mais suave e espalhada
    float combined = (sparkle1 + sparkle2 + sparkle3 + sparkle4 + sparkle5) / 5.0;
    
    // Cria brilho espalhado e difuso (não concentrado)
    float sparkleIntensity = smoothstep(0.0, 1.0, abs(combined));
    sparkleIntensity = pow(sparkleIntensity, 0.7); // Mais espalhado, menos concentrado
    
    // Adiciona pulsação suave aos sparkles
    float pulse = sin(time * 3.5) * 0.2 + 0.8;
    
    return sparkleIntensity * pulse;
}

// Função para detectar bordas e criar aura dourada usando textura de nuvem
float goldenAura(vec2 uv, sampler2D tex, sampler2D cloudTex, vec2 cloudUV, float time) {
    // Offset para detectar bordas (ajuste conforme necessário)
    float offset = 0.002;
    
    // Amostra a textura em múltiplos pontos ao redor
    vec4 center = texture2D(tex, uv);
    vec4 up = texture2D(tex, uv + vec2(0.0, -offset));
    vec4 down = texture2D(tex, uv + vec2(0.0, offset));
    vec4 left = texture2D(tex, uv + vec2(-offset, 0.0));
    vec4 right = texture2D(tex, uv + vec2(offset, 0.0));
    
    // Amostras diagonais para melhor detecção
    vec4 upLeft = texture2D(tex, uv + vec2(-offset, -offset));
    vec4 upRight = texture2D(tex, uv + vec2(offset, -offset));
    vec4 downLeft = texture2D(tex, uv + vec2(-offset, offset));
    vec4 downRight = texture2D(tex, uv + vec2(offset, offset));
    
    // Detecta se estamos em uma borda
    float edge = 0.0;
    if (center.a > 0.1) {
        // Se o pixel atual tem conteúdo, verifica se há transparência ao redor
        float neighborAlpha = (up.a + down.a + left.a + right.a + 
                              upLeft.a + upRight.a + downLeft.a + downRight.a) / 8.0;
        
        // Se há menos alpha nos vizinhos, estamos perto de uma borda
        if (neighborAlpha < center.a * 0.7) {
            edge = 1.0 - (neighborAlpha / center.a);
        }
    } else {
        // Se o pixel atual é transparente, verifica se há conteúdo próximo
        float neighborAlpha = (up.a + down.a + left.a + right.a + 
                              upLeft.a + upRight.a + downLeft.a + downRight.a) / 8.0;
        
        // Se há conteúdo próximo, estamos na área da aura
        if (neighborAlpha > 0.1) {
            edge = neighborAlpha * 0.8;
        }
    }
    
    // Usa a textura stone para criar padrão orgânico na aura
    vec4 stoneSample = texture2D(cloudTex, cloudUV);
    float stonePattern = stoneSample.r; // Usa o canal vermelho (pode usar .a para alpha se necessário)
    
    // Se a textura não estiver sendo aplicada, usa um padrão alternativo
    if (stonePattern < 0.01) {
        stonePattern = 0.5; // Fallback se a textura não estiver carregada
    }
    
    // Combina detecção de borda com padrão stone
    float aura = edge * stonePattern;
    
    // Adiciona pulsação à aura
    float pulse = sin(time * 2.0) * 0.2 + 0.8;
    
    return aura * pulse;
}

void main()
{
    gl_FragColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    
    // Testa a textura stone diretamente primeiro
    vec4 stoneColor = texture2D(u_Tex1, v_TexCoord3);
    
    // Cor amarela NEON muito clara e brilhante
    vec3 divineGold = vec3(1.0, 1.0, 0.4); // Amarelo neon muito claro
    vec3 brightGold = vec3(1.0, 1.0, 0.6); // Amarelo neon brilhante para sparkles
    vec3 sparkleGold = vec3(1.0, 1.0, 0.5); // Amarelo neon sparkle
    vec3 auraGold = vec3(1.0, 1.0, 0.45); // Amarelo neon para aura
    
    // Efeito pulsante suave
    float pulse = sin(u_Time * 2.5) * 0.15 + 0.85; // Oscila entre 0.7 e 1.0
    
    // Gera sparkles espalhados
    float sparkleValue = sparkle(v_TexCoord, u_Time);
    
    // Gera aura dourada ao redor das bordas usando textura stone
    float auraValue = goldenAura(v_TexCoord, u_Tex0, u_Tex1, v_TexCoord3, u_Time);
    
    // Aplica cor dourada baseada nas cores do outfit
    if(texcolor.r > 0.9) {
        // Vermelho -> Dourado divino brilhante
        vec4 outfitColor = texcolor.g > 0.9 ? u_Color[0] : u_Color[1];
        vec3 goldenTint = divineGold * pulse;
        
        // Adiciona sparkles espalhados (mistura mais suave)
        vec3 sparkleColor = mix(goldenTint, sparkleGold, sparkleValue * 0.5);
        sparkleColor = mix(sparkleColor, brightGold, sparkleValue * 0.3);
        
        gl_FragColor.rgb = gl_FragColor.rgb * outfitColor.rgb * sparkleColor;
        gl_FragColor.a = gl_FragColor.a * outfitColor.a;
    } else if(texcolor.g > 0.9) {
        // Verde -> Dourado divino
        vec4 outfitColor = u_Color[2];
        vec3 goldenTint = divineGold * pulse;
        
        // Adiciona sparkles espalhados
        vec3 sparkleColor = mix(goldenTint, sparkleGold, sparkleValue * 0.5);
        sparkleColor = mix(sparkleColor, brightGold, sparkleValue * 0.3);
        
        gl_FragColor.rgb = gl_FragColor.rgb * outfitColor.rgb * sparkleColor;
        gl_FragColor.a = gl_FragColor.a * outfitColor.a;
    } else if(texcolor.b > 0.9) {
        // Azul -> Dourado divino escuro
        vec4 outfitColor = u_Color[3];
        vec3 goldenTint = vec3(1.0, 1.0, 0.35) * pulse; // Amarelo neon para azul
        
        // Adiciona sparkles espalhados
        vec3 sparkleColor = mix(goldenTint, sparkleGold, sparkleValue * 0.4);
        sparkleColor = mix(sparkleColor, brightGold, sparkleValue * 0.25);
        
        gl_FragColor.rgb = gl_FragColor.rgb * outfitColor.rgb * sparkleColor;
        gl_FragColor.a = gl_FragColor.a * outfitColor.a;
    } else {
        // Outras áreas -> Aplica dourado divino com sparkles espalhados
        vec3 goldenTint = divineGold * pulse;
        vec3 sparkleColor = mix(goldenTint, sparkleGold, sparkleValue * 0.6);
        sparkleColor = mix(sparkleColor, brightGold, sparkleValue * 0.4);
        gl_FragColor.rgb = gl_FragColor.rgb * sparkleColor;
    }
    
    // Aumenta o brilho geral MUITO para ficar bem claro e neon
    gl_FragColor.rgb *= 1.8;
    
    // Adiciona um brilho espalhado e difuso nas áreas com sparkles (amarelo neon)
    gl_FragColor.rgb += sparkleValue * vec3(0.4, 0.4, 0.1);
    
    // APLICA SHADER APENAS ONDE HÁ PIXELS DO PERSONAGEM
    // Descarta pixels transparentes ANTES de aplicar qualquer efeito
    if(gl_FragColor.a < 0.01) discard;
    
    // Usa a textura stone apenas dentro do personagem
    vec4 stoneSample = texture2D(u_Tex1, v_TexCoord3);
    float stoneIntensity = (stoneSample.r + stoneSample.g + stoneSample.b) / 3.0;
    
    // Aplica efeitos dourados apenas onde há conteúdo do personagem
    // Adiciona brilho dourado com padrão stone nas bordas internas
    if (auraValue > 0.0 && gl_FragColor.a > 0.1) {
        vec3 auraColor = auraGold * auraValue * (0.5 + stoneIntensity * 0.5);
        // Mistura suavemente com a cor atual
        gl_FragColor.rgb = mix(gl_FragColor.rgb, auraColor, auraValue * 0.4);
        // Adiciona brilho extra nas bordas com padrão stone
        gl_FragColor.rgb += auraColor * stoneIntensity * 0.3;
    }
    
    // Adiciona textura stone apenas dentro do personagem
    if (stoneIntensity > 0.2 && gl_FragColor.a > 0.1) {
        vec3 stoneGlow = auraGold * stoneIntensity * 0.3;
        gl_FragColor.rgb += stoneGlow;
    }
}
