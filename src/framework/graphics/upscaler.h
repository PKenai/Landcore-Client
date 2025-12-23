/*
 * Sistema de Upscaling Multi-Algoritmo
 * Suporta xBRZ, hqnx e outros algoritmos de upscaling
 */

#ifndef UPSCALER_H
#define UPSCALER_H

#include "declarations.h"
#include "image.h"
#include "xbrz.h"
#include <string>

enum class UpscaleAlgorithm {
    XBRZ,      // xBRZ - Scale by Rules (atual, melhor qualidade)
    HQNX,      // hqnx - High Quality NeX (alternativa clássica)
    NEAREST,   // Nearest Neighbor (sem upscaling, apenas redimensiona)
    AUTO       // Escolhe automaticamente baseado na qualidade
};

class Upscaler {
public:
    static ImagePtr upscale(const ImagePtr& image, UpscaleAlgorithm algorithm = UpscaleAlgorithm::XBRZ, int scaleFactor = 2);
    
    // Configurações por algoritmo
    static void setXBRZConfig(const xbrz::ScalerCfg& cfg);
    static xbrz::ScalerCfg getXBRZConfig();
    
    // Configurações de pós-processamento
    static void setPostProcessingEnabled(bool enabled);
    static bool isPostProcessingEnabled();
    
    // Aplicar pós-processamento a uma imagem (usando shader)
    static ImagePtr applyPostProcessing(const ImagePtr& image);
    
    // Inicializar shader de pós-processamento (chamar após g_shaders.init())
    static void initPostProcessingShader();
    
    // Estatísticas
    static std::string getAlgorithmName(UpscaleAlgorithm algorithm);
    static UpscaleAlgorithm getDefaultAlgorithm();
    
    // Configuração do algoritmo atual
    static void setCurrentAlgorithm(UpscaleAlgorithm algorithm);
    static UpscaleAlgorithm getCurrentAlgorithm();

private:
    static ImagePtr upscaleXBRZ(const ImagePtr& image, int scaleFactor);
    static ImagePtr upscaleHQNX(const ImagePtr& image, int scaleFactor);
    static ImagePtr upscaleNearest(const ImagePtr& image, int scaleFactor);
    
    static xbrz::ScalerCfg s_xbrzConfig;
    static bool s_postProcessingEnabled;
    static UpscaleAlgorithm s_currentAlgorithm;
};

#endif

