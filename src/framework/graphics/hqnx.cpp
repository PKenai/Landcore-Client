/*
 * hqnx - High Quality NeX upscaling algorithm
 * Implementação simplificada do algoritmo hqnx para pixel art
 */

#include "hqnx.h"
#include <algorithm>
#include <cstring>
#include <vector>

namespace hqnx {

// Funções auxiliares para comparar cores
inline bool isDifferent(uint32_t c1, uint32_t c2, int threshold = 48) {
    int r1 = (c1 >> 16) & 0xFF, g1 = (c1 >> 8) & 0xFF, b1 = c1 & 0xFF;
    int r2 = (c2 >> 16) & 0xFF, g2 = (c2 >> 8) & 0xFF, b2 = c2 & 0xFF;
    int dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
    return (dr * dr + dg * dg + db * db) > (threshold * threshold);
}

inline uint32_t interpolate(uint32_t c1, uint32_t c2) {
    int r1 = (c1 >> 16) & 0xFF, g1 = (c1 >> 8) & 0xFF, b1 = c1 & 0xFF;
    int r2 = (c2 >> 16) & 0xFF, g2 = (c2 >> 8) & 0xFF, b2 = c2 & 0xFF;
    int a1 = (c1 >> 24) & 0xFF, a2 = (c2 >> 24) & 0xFF;
    
    int r = (r1 + r2) / 2;
    int g = (g1 + g2) / 2;
    int b = (b1 + b2) / 2;
    int a = (a1 + a2) / 2;
    
    return (a << 24) | (r << 16) | (g << 8) | b;
}

inline uint32_t interpolate3(uint32_t c1, uint32_t c2, uint32_t c3) {
    int r1 = (c1 >> 16) & 0xFF, g1 = (c1 >> 8) & 0xFF, b1 = c1 & 0xFF;
    int r2 = (c2 >> 16) & 0xFF, g2 = (c2 >> 8) & 0xFF, b2 = c2 & 0xFF;
    int r3 = (c3 >> 16) & 0xFF, g3 = (c3 >> 8) & 0xFF, b3 = c3 & 0xFF;
    int a1 = (c1 >> 24) & 0xFF, a2 = (c2 >> 24) & 0xFF, a3 = (c3 >> 24) & 0xFF;
    
    int r = (r1 + r2 + r3) / 3;
    int g = (g1 + g2 + g3) / 3;
    int b = (b1 + b2 + b3) / 3;
    int a = (a1 + a2 + a3) / 3;
    
    return (a << 24) | (r << 16) | (g << 8) | b;
}

void scale2x(const uint32_t* src, uint32_t* dst, int width, int height) {
    int dstWidth = width * 2;
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            uint32_t c = src[y * width + x];
            
            // Obter pixels vizinhos
            uint32_t a = (x > 0 && y > 0) ? src[(y - 1) * width + (x - 1)] : c;
            uint32_t b = (y > 0) ? src[(y - 1) * width + x] : c;
            uint32_t d = (x > 0) ? src[y * width + (x - 1)] : c;
            uint32_t e = c;
            uint32_t f = (x < width - 1) ? src[y * width + (x + 1)] : c;
            uint32_t h = (y < height - 1) ? src[(y + 1) * width + x] : c;
            
            // Aplicar regras do hq2x
            uint32_t e0 = e, e1 = e, e2 = e, e3 = e;
            
            if (isDifferent(b, d) && isDifferent(d, h) && isDifferent(b, f)) {
                e0 = isDifferent(d, b) ? interpolate(d, e) : e;
                e1 = isDifferent(b, f) ? interpolate(b, e) : e;
                e2 = isDifferent(d, h) ? interpolate(d, e) : e;
                e3 = isDifferent(h, f) ? interpolate(f, e) : e;
            } else {
                if (isDifferent(d, b)) e0 = interpolate(d, e);
                if (isDifferent(b, f)) e1 = interpolate(b, e);
                if (isDifferent(d, h)) e2 = interpolate(d, e);
                if (isDifferent(h, f)) e3 = interpolate(f, e);
            }
            
            // Escrever os 4 pixels de saída
            int dstY = y * 2;
            int dstX = x * 2;
            dst[dstY * dstWidth + dstX] = e0;
            dst[dstY * dstWidth + dstX + 1] = e1;
            dst[(dstY + 1) * dstWidth + dstX] = e2;
            dst[(dstY + 1) * dstWidth + dstX + 1] = e3;
        }
    }
}

void scale3x(const uint32_t* src, uint32_t* dst, int width, int height) {
    // Para 3x, usamos uma abordagem simplificada: aplicar scale2x e depois interpolar
    // Implementação mais simples: usar scale2x e depois nearest neighbor
    int tempWidth = width * 2;
    int tempHeight = height * 2;
    std::vector<uint32_t> temp(tempWidth * tempHeight);
    
    scale2x(src, temp.data(), width, height);
    
    // Aplicar scale novamente usando nearest neighbor para chegar a 3x
    int dstWidth = width * 3;
    int dstHeight = height * 3;
    
    for (int y = 0; y < dstHeight; ++y) {
        for (int x = 0; x < dstWidth; ++x) {
            int srcX = (x * tempWidth) / dstWidth;
            int srcY = (y * tempHeight) / dstHeight;
            if (srcX < tempWidth && srcY < tempHeight) {
                dst[y * dstWidth + x] = temp[srcY * tempWidth + srcX];
            }
        }
    }
}

void scale4x(const uint32_t* src, uint32_t* dst, int width, int height) {
    // Aplicar scale2x duas vezes
    int tempWidth = width * 2;
    int tempHeight = height * 2;
    std::vector<uint32_t> temp(tempWidth * tempHeight);
    
    scale2x(src, temp.data(), width, height);
    scale2x(temp.data(), dst, tempWidth, tempHeight);
}

void scale(const uint32_t* src, uint32_t* dst, int width, int height, int factor) {
    switch (factor) {
        case 2:
            scale2x(src, dst, width, height);
            break;
        case 3:
            scale3x(src, dst, width, height);
            break;
        case 4:
            scale4x(src, dst, width, height);
            break;
        default:
            // Nearest neighbor para outros fatores
            for (int y = 0; y < height; ++y) {
                for (int x = 0; x < width; ++x) {
                    uint32_t pixel = src[y * width + x];
                    for (int dy = 0; dy < factor; ++dy) {
                        for (int dx = 0; dx < factor; ++dx) {
                            dst[(y * factor + dy) * (width * factor) + (x * factor + dx)] = pixel;
                        }
                    }
                }
            }
            break;
    }
}

} // namespace hqnx

