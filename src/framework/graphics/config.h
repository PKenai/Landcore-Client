// CRIADO POR SIRIUS, CASO VOCÊ NAO TENHA ADIQUIRIDO COMIGO, ME FALE ATRAVES DO DISCORD __KENAI__
// OBRIGADO POR USAR O MEU SCALER!

#ifndef XBRZ_CONFIG_HEADER_284578425345
#define XBRZ_CONFIG_HEADER_284578425345

//nao inclua nenhum header aqui! usado pelo xBRZ_dll!!!

namespace xbrz
{
struct ScalerCfg
{
    double luminanceWeight            = 1;
    double equalColorTolerance        = 30;
    double dominantDirectionThreshold = 3.6;
    double steepDirectionThreshold    = 2.2;
    double newTestAttribute           = 0; //unused; test new parameters
};

// Configurações de aprimoramento visual
struct EnhancementCfg
{
    // Configurações do xBRZ para melhor qualidade
    double xbrzLuminanceWeight            = 1.0;
    double xbrzEqualColorTolerance        = 25.0;  // Reduzido para mais detalhes
    double xbrzDominantDirectionThreshold = 3.4;   // Ajustado para melhor preservação de bordas
    double xbrzSteepDirectionThreshold    = 2.0;   // Ajustado para melhor suavização
    
    // Configurações de pós-processamento (shader)
    float sharpness  = 0.3f;  // Nitidez (0.0 - 1.0)
    float contrast   = 1.15f; // Contraste (1.0 = normal, >1.0 = mais contraste)
    float brightness = 0.05f; // Brilho (-1.0 a 1.0)
    float saturation = 1.2f; // Saturação (1.0 = normal, >1.0 = mais saturado)
    
    // Ativar/desativar melhorias
    bool enablePostProcessing = true;
    bool enableEnhancedUpscale = true;
};
}

#endif

