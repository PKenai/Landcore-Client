/*
 * Sistema de Upscaling Multi-Algoritmo
 * Implementação do sistema unificado de upscaling
 */

#include "upscaler.h"
#include "hqnx.h"
#include <framework/core/resourcemanager.h>
#include <framework/core/logger.h>
#include <framework/graphics/shadermanager.h>

xbrz::ScalerCfg Upscaler::s_xbrzConfig;
bool Upscaler::s_postProcessingEnabled = true;
UpscaleAlgorithm Upscaler::s_currentAlgorithm = UpscaleAlgorithm::XBRZ;

ImagePtr Upscaler::upscale(const ImagePtr& image, UpscaleAlgorithm algorithm, int scaleFactor) {
    if (!image || scaleFactor < 2 || scaleFactor > 6) {
        return image;
    }
    
    switch (algorithm) {
        case UpscaleAlgorithm::XBRZ:
            return upscaleXBRZ(image, scaleFactor);
        case UpscaleAlgorithm::HQNX:
            return upscaleHQNX(image, scaleFactor);
        case UpscaleAlgorithm::NEAREST:
            return upscaleNearest(image, scaleFactor);
        case UpscaleAlgorithm::AUTO:
            // Escolhe xBRZ por padrão (melhor qualidade)
            return upscaleXBRZ(image, scaleFactor);
        default:
            return upscaleXBRZ(image, scaleFactor);
    }
}

ImagePtr Upscaler::upscaleXBRZ(const ImagePtr& image, int scaleFactor) {
    if (!image || image->getBpp() != 4) {
        return image;
    }
    
    int srcWidth = image->getWidth();
    int srcHeight = image->getHeight();
    
    // Converter pixels para formato ARGB
    std::vector<uint32_t> srcData(srcWidth * srcHeight);
    uint8* pixels = image->getPixelData();
    
    for (int i = 0; i < srcWidth * srcHeight; ++i) {
        uint32_t r = pixels[i * 4 + 0];
        uint32_t g = pixels[i * 4 + 1];
        uint32_t b = pixels[i * 4 + 2];
        uint32_t a = pixels[i * 4 + 3];
        srcData[i] = (a << 24) | (r << 16) | (g << 8) | b;
    }
    
    // Aplicar upscaling
    int dstWidth = srcWidth * scaleFactor;
    int dstHeight = srcHeight * scaleFactor;
    std::vector<uint32_t> dstData(dstWidth * dstHeight);
    
    xbrz::scale(static_cast<size_t>(scaleFactor), srcData.data(), dstData.data(), 
                srcWidth, srcHeight, xbrz::ColorFormat::ARGB, s_xbrzConfig);
    
    // Converter de volta para formato de imagem
    std::vector<uint8_t> newPixelData(dstData.size() * 4);
    for (size_t i = 0; i < dstData.size(); ++i) {
        uint32_t pixel = dstData[i];
        newPixelData[i * 4 + 0] = (pixel >> 16) & 0xFF;
        newPixelData[i * 4 + 1] = (pixel >> 8) & 0xFF;
        newPixelData[i * 4 + 2] = pixel & 0xFF;
        newPixelData[i * 4 + 3] = (pixel >> 24) & 0xFF;
    }
    
    return ImagePtr(new Image(Size(dstWidth, dstHeight), 4, newPixelData.data()));
}

ImagePtr Upscaler::upscaleHQNX(const ImagePtr& image, int scaleFactor) {
    if (!image || image->getBpp() != 4) {
        return image;
    }
    
    int srcWidth = image->getWidth();
    int srcHeight = image->getHeight();
    
    // Converter pixels para formato ARGB
    std::vector<uint32_t> srcData(srcWidth * srcHeight);
    uint8* pixels = image->getPixelData();
    
    for (int i = 0; i < srcWidth * srcHeight; ++i) {
        uint32_t r = pixels[i * 4 + 0];
        uint32_t g = pixels[i * 4 + 1];
        uint32_t b = pixels[i * 4 + 2];
        uint32_t a = pixels[i * 4 + 3];
        srcData[i] = (a << 24) | (r << 16) | (g << 8) | b;
    }
    
    // Aplicar upscaling hqnx
    int dstWidth = srcWidth * scaleFactor;
    int dstHeight = srcHeight * scaleFactor;
    std::vector<uint32_t> dstData(dstWidth * dstHeight);
    
    hqnx::scale(srcData.data(), dstData.data(), srcWidth, srcHeight, scaleFactor);
    
    // Converter de volta para formato de imagem
    std::vector<uint8_t> newPixelData(dstData.size() * 4);
    for (size_t i = 0; i < dstData.size(); ++i) {
        uint32_t pixel = dstData[i];
        newPixelData[i * 4 + 0] = (pixel >> 16) & 0xFF;
        newPixelData[i * 4 + 1] = (pixel >> 8) & 0xFF;
        newPixelData[i * 4 + 2] = pixel & 0xFF;
        newPixelData[i * 4 + 3] = (pixel >> 24) & 0xFF;
    }
    
    return ImagePtr(new Image(Size(dstWidth, dstHeight), 4, newPixelData.data()));
}

ImagePtr Upscaler::upscaleNearest(const ImagePtr& image, int scaleFactor) {
    if (!image) {
        return image;
    }
    
    int srcWidth = image->getWidth();
    int srcHeight = image->getHeight();
    int dstWidth = srcWidth * scaleFactor;
    int dstHeight = srcHeight * scaleFactor;
    int bpp = image->getBpp();
    
    ImagePtr newImage(new Image(Size(dstWidth, dstHeight), bpp));
    uint8* srcPixels = image->getPixelData();
    uint8* dstPixels = newImage->getPixelData();
    
    for (int y = 0; y < srcHeight; ++y) {
        for (int x = 0; x < srcWidth; ++x) {
            int srcPos = (y * srcWidth + x) * bpp;
            for (int dy = 0; dy < scaleFactor; ++dy) {
                for (int dx = 0; dx < scaleFactor; ++dx) {
                    int dstPos = ((y * scaleFactor + dy) * dstWidth + (x * scaleFactor + dx)) * bpp;
                    for (int i = 0; i < bpp; ++i) {
                        dstPixels[dstPos + i] = srcPixels[srcPos + i];
                    }
                }
            }
        }
    }
    
    return newImage;
}

void Upscaler::setXBRZConfig(const xbrz::ScalerCfg& cfg) {
    s_xbrzConfig = cfg;
}

xbrz::ScalerCfg Upscaler::getXBRZConfig() {
    return s_xbrzConfig;
}

void Upscaler::setPostProcessingEnabled(bool enabled) {
    s_postProcessingEnabled = enabled;
}

bool Upscaler::isPostProcessingEnabled() {
    return s_postProcessingEnabled;
}

std::string Upscaler::getAlgorithmName(UpscaleAlgorithm algorithm) {
    switch (algorithm) {
        case UpscaleAlgorithm::XBRZ:
            return "xBRZ (Scale by Rules)";
        case UpscaleAlgorithm::HQNX:
            return "hqnx (High Quality NeX)";
        case UpscaleAlgorithm::NEAREST:
            return "Nearest Neighbor";
        case UpscaleAlgorithm::AUTO:
            return "Auto (xBRZ)";
        default:
            return "Unknown";
    }
}

UpscaleAlgorithm Upscaler::getDefaultAlgorithm() {
    return UpscaleAlgorithm::XBRZ;
}

void Upscaler::setCurrentAlgorithm(UpscaleAlgorithm algorithm) {
    s_currentAlgorithm = algorithm;
}

UpscaleAlgorithm Upscaler::getCurrentAlgorithm() {
    return s_currentAlgorithm;
}

ImagePtr Upscaler::applyPostProcessing(const ImagePtr& image) {
    if (!image || !s_postProcessingEnabled) {
        return image;
    }
    
    // O pós-processamento via shader será aplicado durante a renderização
    // Esta função pode ser usada para aplicar efeitos via CPU se necessário
    // Por enquanto, retorna a imagem original (shader será aplicado na GPU)
    return image;
}

void Upscaler::initPostProcessingShader() {
    // Carregar shader de aprimoramento visual
    // Este shader melhora nitidez, contraste, brilho e saturação
    try {
        g_shaders.createShader("sprite_enhancement",
            "sprite_enhancement_vertex.frag",
            "sprite_enhancement_fragment.frag");
    } catch (...) {
        // Shader opcional, não é crítico se falhar
    }
}

