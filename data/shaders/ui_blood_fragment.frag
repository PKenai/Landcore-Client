varying vec2 v_TexCoord;
uniform vec4 u_Color;
uniform sampler2D u_Tex0;
uniform float u_Time;

void main()
{
    // Obtém a cor original da imagem
    vec4 originalColor = texture2D(u_Tex0, v_TexCoord) * u_Color;
    
    // Descarta pixels transparentes
    if(originalColor.a < 0.01)
        discard;
    
    // Usa coordenadas de textura (0.0 a 1.0) em vez de coordenadas da tela
    // Isso funciona melhor para widgets UI com dimensões específicas
    vec2 coord = v_TexCoord;
    
    // Calcula distância de cada borda (0.0 = na borda, 1.0 = no centro)
    float distFromLeft = coord.x;
    float distFromRight = 1.0 - coord.x;
    float distFromTop = coord.y;
    float distFromBottom = 1.0 - coord.y;
    
    // Pega a menor distância (mais próxima da borda)
    float minDist = min(min(distFromLeft, distFromRight), min(distFromTop, distFromBottom));
    
    // Define a largura da borda de sangue (0.0 a 1.0)
    // Ajustado para funcionar melhor com widgets UI
    float bloodEdgeWidth = 0.15; // 15% das bordas terá sangue
    
    // Calcula intensidade do sangue nas bordas (1.0 = borda, 0.0 = centro)
    float edgeIntensity = 1.0 - smoothstep(0.0, bloodEdgeWidth, minDist);
    
    // Efeito de pulsação do sangue (múltiplas camadas para efeito mais orgânico)
    float pulse1 = sin(u_Time * 2.5) * 0.4 + 0.6; // Oscila entre 0.2 e 1.0
    float pulse2 = cos(u_Time * 1.8) * 0.3 + 0.7; // Segunda camada
    float pulse3 = sin(u_Time * 3.2 + 1.5) * 0.2 + 0.8; // Terceira camada
    
    // Combina as pulsações para efeito mais natural
    float bloodPulse = (pulse1 + pulse2 + pulse3) / 3.0;
    
    // Adiciona variação de intensidade baseada na posição
    float positionVariation = sin(coord.x * 8.0 + u_Time * 1.5) * 
                              cos(coord.y * 6.0 + u_Time * 1.8) * 0.15 + 0.85;
    
    // Intensidade final do sangue nas bordas
    float bloodIntensity = edgeIntensity * bloodPulse * positionVariation;
    
    // Cor do sangue (vermelho sangue com variações)
    vec3 bloodColorBright = vec3(0.95, 0.2, 0.2); // Vermelho sangue brilhante
    vec3 bloodColor = vec3(0.8, 0.15, 0.15); // Vermelho sangue
    vec3 bloodColorDark = vec3(0.6, 0.1, 0.1); // Vermelho mais escuro
    
    // Mistura a cor do sangue com base na pulsação
    vec3 finalBloodColor = mix(bloodColorDark, bloodColor, bloodPulse);
    finalBloodColor = mix(finalBloodColor, bloodColorBright, pulse1 * 0.4);
    
    // Aplica o efeito de sangue nas bordas (mistura com a cor original)
    // Intensidade reduzida para não sobrepor completamente a imagem
    vec3 finalColor = mix(originalColor.rgb, finalBloodColor, bloodIntensity * 0.6);
    
    // Escurecimento sutil no centro (muito menos agressivo que o map_blood)
    float centerDarkness = 1.0 - edgeIntensity;
    float darkenAmount = 0.75; // Escurece apenas 25% no centro (em vez de 65%)
    float darkenFactor = smoothstep(0.0, 0.6, centerDarkness);
    finalColor = mix(finalColor, finalColor * darkenAmount, darkenFactor * 0.3);
    
    // Aplica a cor final mantendo o alpha original
    gl_FragColor = vec4(finalColor, originalColor.a);
}

