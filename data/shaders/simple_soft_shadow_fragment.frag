// Shader de Sombra Suave Simples
// Versão otimizada que funciona bem com a perspectiva isométrica do Tibia

uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform sampler2D u_Tex0;

// Parâmetros configuráveis (podem ser passados via uniform)
// Valores padrão caso os uniforms não sejam definidos
uniform float u_Time;              // Tempo para animações opcionais
uniform vec2 u_ShadowDirection;    // Direção da luz (normalizado)
uniform float u_ShadowLength;       // Comprimento da sombra
uniform float u_ShadowOpacity;     // Opacidade da sombra (0.0 - 1.0)
uniform float u_ShadowBlurRadius;  // Raio do blur (softness)

// Valores padrão para sombras isométricas do Tibia
const vec2 DEFAULT_SHADOW_DIR = vec2(0.707, 0.707); // 45 graus (isométrico)
const float DEFAULT_SHADOW_LENGTH = 0.08; // Comprimento padrão
const float DEFAULT_SHADOW_OPACITY = 0.4; // 40% de opacidade
const float DEFAULT_SHADOW_BLUR = 2.0; // Blur suave

void main() {
    // Pegar cor original
    vec4 originalColor = texture2D(u_Tex0, v_TexCoord);
    
    if (originalColor.a < 0.01) {
        discard;
    }
    
    // Aplicar blur gaussiano simples para suavizar a sombra
    vec4 blurredSample = vec4(0.0);
    float totalWeight = 0.0;
    
    // Kernel de blur 3x3 otimizado para sombras suaves
    float weights[3] = float[](0.4, 0.3, 0.1);
    float blurRadius = u_ShadowBlurRadius > 0.0 ? u_ShadowBlurRadius : DEFAULT_SHADOW_BLUR;
    vec2 texelSize = vec2(1.0 / 512.0, 1.0 / 512.0) * blurRadius;
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 sampleCoord = v_TexCoord + vec2(float(i), float(j)) * texelSize;
            
            // Verificar se está dentro dos limites
            if (sampleCoord.x >= 0.0 && sampleCoord.x <= 1.0 && 
                sampleCoord.y >= 0.0 && sampleCoord.y <= 1.0) {
                
                float weight = weights[abs(i)] * weights[abs(j)];
                blurredSample += texture2D(u_Tex0, sampleCoord) * weight;
                totalWeight += weight;
            }
        }
    }
    
    if (totalWeight > 0.0) {
        blurredSample /= totalWeight;
    }
    
    // Criar sombra preta com opacidade e blur
    // Este shader é usado apenas para desenhar a sombra (atrás do objeto)
    float shadowOpacity = u_ShadowOpacity > 0.0 ? u_ShadowOpacity : DEFAULT_SHADOW_OPACITY;
    
    // Usar o alpha do blur para criar uma sombra suave
    float shadowAlpha = blurredSample.a * shadowOpacity;
    
    // Aplicar cor preta com transparência (sombra)
    vec4 finalColor = vec4(0.0, 0.0, 0.0, shadowAlpha);
    
    if(finalColor.a < 0.01) discard;
    gl_FragColor = finalColor;
}


