attribute vec2 a_Vertex;
attribute vec2 a_TexCoord;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
varying vec2 v_TexCoord3;
uniform mat3 u_TransformMatrix;
uniform mat3 u_ProjectionMatrix;
uniform vec2 u_Offset;
uniform float u_Time;

void main()
{
    gl_Position = vec4((u_ProjectionMatrix * u_TransformMatrix * vec3(a_Vertex.xy, 1.0)).xy, 1.0, 1.0);
    v_TexCoord = (u_TextureMatrix * vec3(a_TexCoord,1.0)).xy;
    v_TexCoord2 = (u_TextureMatrix * vec3(a_TexCoord + u_Offset,1.0)).xy;
    
    // Coordenadas para a textura stone - textura infinita (tiled) movendo em 45 graus
    // Usa as coordenadas de textura transformadas para criar textura infinita
    vec2 baseTexCoord = (u_TextureMatrix * vec3(a_TexCoord, 1.0)).xy;
    
    // Direção em 45 graus (1, 1) normalizada
    vec2 direction45 = normalize(vec2(1.0, 1.0));
    
    // Velocidade de movimento (rápida para ser bem visível)
    float speed = 0.5;
    vec2 movement = direction45 * u_Time * speed;
    
    // Cria textura infinita usando fract (repetição)
    // Multiplica por um fator para criar tiles menores e mais repetições
    vec2 stoneUV = fract(baseTexCoord * 4.0 + movement);
    
    v_TexCoord3 = stoneUV;
}

