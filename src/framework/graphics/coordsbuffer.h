/*
 * Copyright (c) 2010-2017 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef COORDSBUFFER_H
#define COORDSBUFFER_H

#include "vertexarray.h"
#include <framework/util/point.h>
#include <framework/util/rect.h>

class CoordsBuffer {
public:
  CoordsBuffer();
  ~CoordsBuffer();
  CoordsBuffer(CoordsBuffer &c) = delete;
  CoordsBuffer &operator=(CoordsBuffer &c) = delete;
  CoordsBuffer(CoordsBuffer &&c) noexcept
      : m_vertexArray(c.m_vertexArray),
        m_textureCoordArray(c.m_textureCoordArray) {
    m_locked = c.m_locked = true;
  };

  void clear() {
    if (m_locked)
      unlock(true);
    m_textureCoordArray->clear();
    m_vertexArray->clear();
  }

  void addTriangle(const Point &a, const Point &b, const Point &c) {
    if (m_locked)
      unlock();
    m_vertexArray->addTriangle(a, b, c);
  }
  void addRect(const Rect &dest) {
    if (m_locked)
      unlock();
    m_vertexArray->addRect(dest);
  }
  void addRect(const Rect &dest, const Rect &src) {
    if (m_locked)
      unlock();
    m_vertexArray->addRect(dest);
    m_textureCoordArray->addRect(src);
  }
  void addRect(const RectF &dest, const RectF &src) {
    if (m_locked)
      unlock();
    m_vertexArray->addRect(dest);
    m_textureCoordArray->addRect(src);
  }
  void addQuad(const Rect &dest, const Rect &src) {
    if (m_locked)
      unlock();
    m_vertexArray->addQuad(dest);
    m_textureCoordArray->addQuad(src);
  }
  void addUpsideDownQuad(const Rect &dest, const Rect &src) {
    if (m_locked)
      unlock();
    m_vertexArray->addUpsideDownQuad(dest);
    m_textureCoordArray->addQuad(src);
  }

  // Custom Quad with arbitrary vertices (TL, TR, BR, BL order)
  void addCustomQuad(const PointF &p1, const PointF &p2, const PointF &p3,
                     const PointF &p4, const RectF &tex) {
    if (m_locked)
      unlock();

    float tL = tex.left(), tT = tex.top(), tR = tex.right(), tB = tex.bottom();

    // Triangle 1: p1(TL), p2(TR), p4(BL)
    m_vertexArray->addVertex(p1.x, p1.y);
    m_textureCoordArray->addVertex(tL, tT);
    m_vertexArray->addVertex(p2.x, p2.y);
    m_textureCoordArray->addVertex(tR, tT);
    m_vertexArray->addVertex(p4.x, p4.y);
    m_textureCoordArray->addVertex(tL, tB);

    // Triangle 2: p4(BL), p2(TR), p3(BR)
    m_vertexArray->addVertex(p4.x, p4.y);
    m_textureCoordArray->addVertex(tL, tB);
    m_vertexArray->addVertex(p2.x, p2.y);
    m_textureCoordArray->addVertex(tR, tT);
    m_vertexArray->addVertex(p3.x, p3.y);
    m_textureCoordArray->addVertex(tR, tB);
  }

  void addBoudingRect(const Rect &dest, int innerLineWidth);
  void addRepeatedRects(const Rect &dest, const Rect &src);

  float *getVertexArray() { return m_vertexArray->vertices(); }
  float *getTextureCoordArray() { return m_textureCoordArray->vertices(); }
  int getVertexCount() { return m_vertexArray->vertexCount(); }
  int getTextureCoordCount() { return m_textureCoordArray->vertexCount(); }
  HardwareBuffer *getVertexHardwareCache() {
    return m_vertexArray->getHardwareCache();
  }
  HardwareBuffer *getTextureHardwareCache() {
    return m_textureCoordArray->getHardwareCache();
  }

  void unlock(bool clear = false);
  void cache() {
    m_locked = true;
    m_vertexArray->cache();
    m_textureCoordArray->cache();
  }
  Rect getTextureRect();

private:
  bool m_locked = false;
  std::shared_ptr<VertexArray> m_vertexArray;
  std::shared_ptr<VertexArray> m_textureCoordArray;
};

#endif
