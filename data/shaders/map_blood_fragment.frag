varying vec2 v_TexCoord;
uniform vec4 u_Color;
uniform sampler2D u_Tex0;
uniform float u_Time;
uniform vec2 u_ViewportSize; // Tamanho da viewport (opcional, pode não estar disponível)

void main()
{
    // Obtém a cor original do mapa
    vec4 mapColor = texture2D(u_Tex0, v_TexCoord) * u_Color;
    
    // Descarta pixels transparentes
    if(mapColor.a < 0.01)
        discard;
    
    // Obtém coordenadas da tela em pixels
    vec2 screenCoord = gl_FragCoord.xy;
    
    // Calcula coordenadas normalizadas (0.0 a 1.0)
    // Se u_ViewportSize estiver disponível, usa ele, senão usa uma resolução padrão
    vec2 viewportSize = u_ViewportSize;
    if(viewportSize.x <= 0.0 || viewportSize.y <= 0.0) {
        // Fallback: usa resolução padrão comum
        viewportSize = vec2(1920.0, 1080.0);
    }
    
    // Normaliza as coordenadas da tela
    vec2 normalizedCoord = screenCoord / viewportSize;
    
    // Garante que está no range 0.0 a 1.0
    normalizedCoord = clamp(normalizedCoord, 0.0, 1.0);
    
    // Calcula distância de cada borda (0.0 = na borda, 1.0 = no centro)
    float distFromLeft = normalizedCoord.x;
    float distFromRight = 1.0 - normalizedCoord.x;
    float distFromTop = normalizedCoord.y;
    float distFromBottom = 1.0 - normalizedCoord.y;
    
    // Pega a menor distância (mais próxima da borda)
    float minDist = min(min(distFromLeft, distFromRight), min(distFromTop, distFromBottom));
    
    // Define a largura da borda de sangue (0.0 a 1.0, onde 1.0 = toda a tela)
    float bloodEdgeWidth = 0.25; // 25% da tela nas bordas terá sangue
    
    // Calcula intensidade do sangue nas bordas (1.0 = borda, 0.0 = centro)
    float edgeIntensity = 1.0 - smoothstep(0.0, bloodEdgeWidth, minDist);
    
    // Efeito de pulsação do sangue (múltiplas camadas para efeito mais orgânico)
    float pulse1 = sin(u_Time * 2.0) * 0.3 + 0.7; // Oscila entre 0.4 e 1.0
    float pulse2 = cos(u_Time * 1.5) * 0.2 + 0.8; // Segunda camada
    float pulse3 = sin(u_Time * 2.7 + 1.0) * 0.15 + 0.85; // Terceira camada
    
    // Combina as pulsações para efeito mais natural
    float bloodPulse = (pulse1 + pulse2 + pulse3) / 3.0;
    
    // Adiciona variação de intensidade baseada na posição
    float positionVariation = sin(normalizedCoord.x * 10.0 + u_Time) * 
                              cos(normalizedCoord.y * 8.0 + u_Time * 1.2) * 0.1 + 0.9;
    
    // Intensidade final do sangue nas bordas
    float bloodIntensity = edgeIntensity * bloodPulse * positionVariation;
    
    // Cor do sangue (vermelho escuro/vermelho sangue com variações)
    vec3 bloodColorBright = vec3(0.9, 0.15, 0.15); // Vermelho sangue brilhante
    vec3 bloodColor = vec3(0.7, 0.1, 0.1); // Vermelho sangue
    vec3 bloodColorDark = vec3(0.5, 0.05, 0.05); // Vermelho mais escuro
    
    // Mistura a cor do sangue com base na pulsação
    vec3 finalBloodColor = mix(bloodColorDark, bloodColor, bloodPulse);
    finalBloodColor = mix(finalBloodColor, bloodColorBright, pulse1 * 0.3);
    
    // Aplica o efeito de sangue nas bordas (mistura com a cor do mapa)
    vec3 finalColor = mix(mapColor.rgb, finalBloodColor, bloodIntensity * 0.85);
    
    // Escurece o centro da tela (onde não há sangue)
    float centerDarkness = 1.0 - edgeIntensity;
    float darkenAmount = 0.35; // Quanto escurecer o centro (0.0 = não escurece, 1.0 = preto total)
    
    // Aplica escurecimento gradual no centro
    float darkenFactor = smoothstep(0.0, 0.5, centerDarkness);
    finalColor = mix(finalColor, finalColor * darkenAmount, darkenFactor);
    
    // Aplica a cor final mantendo o alpha original
    gl_FragColor = vec4(finalColor, mapColor.a);
}

