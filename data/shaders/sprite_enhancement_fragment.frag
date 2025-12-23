// Shader de aprimoramento visual para sprites
// Melhora nitidez, contraste e sombras para um visual mais bonito

varying vec2 v_TexCoord;
uniform vec4 u_Color;
uniform sampler2D u_Tex0;
uniform float u_Sharpness;
uniform float u_Contrast;
uniform float u_Brightness;
uniform float u_Saturation;

void main()
{
    vec4 texColor = texture2D(u_Tex0, v_TexCoord);
    
    if(texColor.a < 0.01)
        discard;
    
    // Aplicar cor base
    texColor *= u_Color;
    
    // Melhorar contraste
    texColor.rgb = ((texColor.rgb - 0.5) * u_Contrast) + 0.5;
    
    // Ajustar brilho
    texColor.rgb += u_Brightness;
    
    // Aumentar saturação para cores mais vibrantes
    float gray = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
    texColor.rgb = mix(vec3(gray), texColor.rgb, u_Saturation);
    
    // Aplicar nitidez (unsharp mask)
    vec2 texelSize = vec2(1.0 / 512.0, 1.0 / 512.0); // Ajustar conforme resolução do sprite
    vec4 sharpColor = texColor;
    sharpColor += (texColor - texture2D(u_Tex0, v_TexCoord + vec2(texelSize.x, 0.0))) * u_Sharpness;
    sharpColor += (texColor - texture2D(u_Tex0, v_TexCoord - vec2(texelSize.x, 0.0))) * u_Sharpness;
    sharpColor += (texColor - texture2D(u_Tex0, v_TexCoord + vec2(0.0, texelSize.y))) * u_Sharpness;
    sharpColor += (texColor - texture2D(u_Tex0, v_TexCoord - vec2(0.0, texelSize.y))) * u_Sharpness;
    
    // Clamp para evitar overflow
    sharpColor.rgb = clamp(sharpColor.rgb, 0.0, 1.0);
    
    gl_FragColor = sharpColor;
}

