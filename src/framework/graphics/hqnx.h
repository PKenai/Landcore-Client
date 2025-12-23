/*
 * hqnx - High Quality NeX upscaling algorithm
 * Implementação baseada no algoritmo hqnx para pixel art
 */

#ifndef HQNX_H
#define HQNX_H

#include <cstdint>

namespace hqnx {
    // Upscale usando algoritmo hq2x, hq3x ou hq4x
    void scale2x(const uint32_t* src, uint32_t* dst, int width, int height);
    void scale3x(const uint32_t* src, uint32_t* dst, int width, int height);
    void scale4x(const uint32_t* src, uint32_t* dst, int width, int height);
    
    // Função genérica
    void scale(const uint32_t* src, uint32_t* dst, int width, int height, int factor);
}

#endif

