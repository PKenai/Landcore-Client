#include <client/outfit.h>
#include <client/spritemanager.h>
#include <framework/graphics/atlas.h>
#include <framework/graphics/drawcache.h>
#include <framework/graphics/drawqueue.h>
#include <framework/graphics/framebuffermanager.h>
#include <framework/graphics/graphics.h>
#include <framework/graphics/image.h>
#include <framework/graphics/painter.h>
#include <framework/graphics/shadermanager.h>
#include <framework/graphics/textrender.h>
#include <framework/graphics/texturemanager.h>
#include <framework/util/point.h>
#include <framework/util/rect.h>
#include <stack>

std::shared_ptr<DrawQueue> g_drawQueue;

void DrawQueueItemTextureCoords::draw() {
  g_painter->setColor(m_color);
  g_painter->drawTextureCoords(m_coordsBuffer, m_texture);
}

bool DrawQueueItemTextureCoords::cache() {
  if (!m_texture->canCache())
    return false;
  m_texture->update();

  uint64_t hash = 100 + m_texture->getUniqueId();
  bool drawNow = false;
  Point atlasPos = g_atlas.cache(hash, m_texture->getSize(), drawNow);
  if (atlasPos.x < 0) {
    return false;
  } // can't be cached
  if (drawNow) {
    g_drawCache.bind();
    draw(atlasPos);
  }

  int size = m_coordsBuffer.getVertexCount();
  if (!g_drawCache.hasSpace(size))
    return false;

  g_drawCache.addTexturedCoords(m_coordsBuffer, atlasPos, m_color);
  return true;
}

void DrawQueueItemTextureCoords::draw(const Point &pos) {
  g_painter->resetColor();
  g_painter->drawTexturedRect(Rect(pos, m_texture->getSize()), m_texture);
}

void DrawQueueItemColoredTextureCoords::draw() {
  g_painter->drawTextureCoords(m_coordsBuffer, m_texture, &m_colors);
}

void DrawQueueItemImageWithShader::draw() {
  if (!m_texture)
    return;
  PainterShaderProgramPtr shader = g_shaders.getShader(m_shader);
  if (!shader)
    return;

  g_painter->setShaderProgram(shader);
  shader->bindMultiTextures();
  g_painter->setColor(m_color);
  g_painter->drawTextureCoords(m_coordsBuffer, m_texture);
  g_painter->resetShaderProgram();
}

void DrawQueueItemImageWithShader::draw(const Point &pos) {
  if (!m_texture)
    return;
  PainterShaderProgramPtr shader = g_shaders.getShader(m_shader);
  if (!shader)
    return;

  g_painter->setShaderProgram(shader);
  shader->bindMultiTextures();
  g_painter->resetColor();
  g_painter->drawTexturedRect(Rect(pos, m_texture->getSize()), m_texture);
  g_painter->resetShaderProgram();
}

void DrawQueueItemTexturedRect::draw() {
  g_painter->setColor(m_color);
  g_painter->drawTexturedRect(m_dest, m_texture, m_src);
}

bool DrawQueueItemTexturedRect::cache() {
  if (m_dest.size() > m_src.size()) // upscaling may create artifacts
    return false;
  if (!m_texture->canCache())
    return false;

  m_texture->update();
  uint64_t hash = 100 + m_texture->getUniqueId();
  bool drawNow = false;
  Point atlasPos = g_atlas.cache(hash, m_texture->getSize(), drawNow);
  if (atlasPos.x < 0) {
    return false;
  } // can't be cached
  if (drawNow) {
    g_drawCache.bind();
    draw(atlasPos);
  }

  if (!g_drawCache.hasSpace(6))
    return false;

  g_drawCache.addTexturedRect(m_dest, m_src + atlasPos, m_color);
  return true;
}

void DrawQueueItemTexturedRect::draw(const Point &pos) {
  g_painter->resetColor();
  g_painter->drawTexturedRect(Rect(pos, m_texture->getSize()), m_texture);
}

bool DrawQueueItemFilledRect::cache() {
  if (!g_drawCache.hasSpace(6))
    return false;
  g_drawCache.addRect(m_dest, m_color);
  return true;
}

void DrawQueueItemFilledRectWithShader::draw() {
  if (m_shader.empty()) {
    // Fallback to normal filled rect if no shader
    g_painter->setColor(m_color);
    g_painter->drawFilledRect(m_dest);
    return;
  }

  PainterShaderProgramPtr shader = g_shaders.getShader(m_shader);
  if (!shader) {
    // Fallback if shader not found
    g_painter->setColor(m_color);
    g_painter->drawFilledRect(m_dest);
    return;
  }

  // Create a coords buffer for the rectangle with proper texture coordinates
  CoordsBuffer coordsBuffer;
  // Add rectangle with normalized texture coordinates (0,0 to 1,1)
  coordsBuffer.addRect(m_dest, Rect(0, 0, 1, 1));

  // Create a 1x1 white texture for the shader to work with
  static TexturePtr whiteTexture = nullptr;
  if (!whiteTexture) {
    ImagePtr whiteImage = ImagePtr(new Image(Size(1, 1), 4));
    whiteImage->setPixel(0, 0, Color::white);
    whiteTexture = TexturePtr(new Texture(whiteImage));
    whiteTexture->setSmooth(false);
  }

  g_painter->setShaderProgram(shader);
  shader->bindMultiTextures();
  shader->setCenter(m_dest.center());
  shader->setOffset(m_dest.topLeft());
  shader->updateTime();
  g_painter->setColor(m_color);
  g_painter->drawTextureCoords(coordsBuffer, whiteTexture);
  g_painter->resetShaderProgram();
}

void DrawQueueItemClearRect::draw() { g_painter->clearRect(m_color, m_dest); }

bool DrawQueueItemFillCoords::cache() {
  int size = m_coordsBuffer.getVertexCount();
  if (!g_drawCache.hasSpace(size))
    return false;

  g_drawCache.addCoords(m_coordsBuffer, m_color);
  return true;
}

void DrawQueueItemText::draw() {
  g_text.drawText(m_point, m_hash, m_color, m_shadow);
}

void DrawQueueItemTextColored::draw() {
  g_text.drawColoredText(m_point, m_hash, m_colors, m_shadow);
}

void ::DrawQueueItemLine::draw() {
  g_painter->setColor(m_color);
  static std::vector<float> vertices(1024, 0);
  if (vertices.size() < m_points.size())
    vertices.resize(m_points.size());
  int i = 0;
  for (Point &point : m_points) {
    vertices[i++] = point.x;
    vertices[i++] = point.y;
  }
  g_painter->drawLine(vertices, i / 2, m_width);
}

void DrawQueueItemBeam::draw() {
  PointF direction = PointF(m_end.x - m_start.x, m_end.y - m_start.y);
  float length = direction.length();

  // VALIDATION: Reject absurd coordinates
  if (length > 10000.0f || length < 0.1f) {
    return;
  }

  // Use a 1x1 white texture for solid color quads
  static TexturePtr whiteTexture = nullptr;
  if (!whiteTexture) {
    ImagePtr whiteImage = ImagePtr(new Image(Size(1, 1), 4));
    whiteImage->setPixel(0, 0, Color::white);
    whiteTexture = TexturePtr(new Texture(whiteImage));
  }

  g_painter->saveState();
  g_painter->setTexture(whiteTexture);

  // Calculate normalized direction and perpendicular
  float invLen = 1.0f / length;
  PointF dir = direction * invLen;
  PointF perp(-dir.y, dir.x);
  // Laser parameters
  float coreWidth = m_thickness * 0.3f; // 30% for white core
  float auraWidth = m_thickness;        // 100% for outer glow

  // Cap size (rounded ends) - use half thickness minus 5px for closer fit
  float capSize = m_thickness * 0.5f - 5.0f;

  // Shorten beam body to leave space for caps
  PointF startF((float)m_start.x, (float)m_start.y);
  PointF endF((float)m_end.x, (float)m_end.y);
  PointF bodyStart = startF + dir * capSize;
  PointF bodyEnd = endF - dir * capSize;
  float bodyLength = length - (capSize * 2.0f);

  // Segment length (small for smooth appearance)
  float segmentLength = 6.0f;
  int numSegments = std::max(1, (int)(bodyLength / segmentLength));
  float actualSegLen = bodyLength / numSegments;

  // Draw all segments (BODY only, caps drawn separately)
  for (int i = 0; i < numSegments; ++i) {
    float t = (float)i / numSegments;
    PointF segCenter = bodyStart + dir * (t * bodyLength);

    float halfSegLen = actualSegLen * 0.5f;

    // ANIMATION: Traveling intensity wave
    float wave = std::sin(m_time * 6.0f - t * 12.0f);
    float intensity = 0.7f + wave * 0.3f;

    // ANIMATION: Subtle width pulsation
    float widthPulse = 1.0f + std::sin(m_time * 4.0f + t * 10.0f) * 0.08f;

    // EDGE FADE: Soften beam start/end for polished look
    float edgeFade = std::min((t < 0.1f) ? (t / 0.1f) : 1.0f,
                              (t > 0.9f) ? ((1.0f - t) / 0.1f) : 1.0f);
    intensity *= edgeFade;

    // --- AURA LAYER (Multi-layer for soft glow) ---
    const int auraLayers = 5;
    for (int layer = 0; layer < auraLayers; ++layer) {
      float layerT = (float)layer / (auraLayers - 1);

      // Shrink width as we go inward
      float layerWidth = (auraWidth * widthPulse) * (1.0f - layerT * 0.6f);
      float halfWidth = layerWidth * 0.5f;

      // Quadratic alpha falloff for strong fade
      float layerAlpha = 1.0f - layerT;
      layerAlpha *= layerAlpha;

      PointF p1 = segCenter - perp * halfWidth - dir * halfSegLen;
      PointF p2 = segCenter + perp * halfWidth - dir * halfSegLen;
      PointF p3 = segCenter + perp * halfWidth + dir * halfSegLen;
      PointF p4 = segCenter - perp * halfWidth + dir * halfSegLen;

      Color auraColor = m_color;
      auraColor.setAlpha((int)(64 * intensity * layerAlpha));

      g_painter->setColor(auraColor);
      CoordsBuffer coordsBuffer;
      coordsBuffer.addCustomQuad(p1, p2, p3, p4, RectF(0, 0, 1, 1));
      g_painter->drawTextureCoords(coordsBuffer, whiteTexture);
    }

    // --- CORE LAYER (Multi-layer for soft glow) ---
    const int coreLayers = 5;
    for (int layer = 0; layer < coreLayers; ++layer) {
      float layerT = (float)layer / (coreLayers - 1);

      // Shrink width as we go inward
      float layerWidth = (coreWidth * widthPulse) * (1.0f - layerT * 0.6f);
      float halfWidth = layerWidth * 0.5f;

      // Quadratic alpha falloff
      float layerAlpha = 1.0f - layerT;
      layerAlpha *= layerAlpha;

      PointF p1 = segCenter - perp * halfWidth - dir * halfSegLen;
      PointF p2 = segCenter + perp * halfWidth - dir * halfSegLen;
      PointF p3 = segCenter + perp * halfWidth + dir * halfSegLen;
      PointF p4 = segCenter - perp * halfWidth + dir * halfSegLen;

      Color coreColor = m_color * 2.0f; // Brighten the beam color for the core
                                        // (maintaining black if color is black)
      coreColor.setAlpha((int)(230 * intensity * layerAlpha));

      g_painter->setColor(coreColor);
      CoordsBuffer coordsBuffer;
      coordsBuffer.addCustomQuad(p1, p2, p3, p4, RectF(0, 0, 1, 1));
      g_painter->drawTextureCoords(coordsBuffer, whiteTexture);
    }
  }

  // --- ROUNDED CAPS (True Half-Circles) ---
  // Helper lambda to draw half-circle using triangle fan
  auto drawHalfCircle = [&](const PointF &center, const PointF &forward,
                            float radius, const Color &color, bool invert) {
    const int segments = 16;
    const float PI = 3.14159265359f;

    PointF dir = forward;
    float len = std::sqrt(dir.x * dir.x + dir.y * dir.y);
    if (len > 0.0001f) {
      dir.x /= len;
      dir.y /= len;
    }

    PointF right(-dir.y, dir.x);

    g_painter->setColor(color);

    // Draw triangle fan: sweep from -90° to +90° perpendicular to dir
    for (int i = 0; i < segments; ++i) {
      float t1 = (float)i / segments;
      float t2 = (float)(i + 1) / segments;

      // Angle from -PI/2 to +PI/2 (perpendicular sweep)
      float angle1 = (t1 - 0.5f) * PI;
      float angle2 = (t2 - 0.5f) * PI;

      // Points on the arc: rotate around the perpendicular direction
      PointF p1 = center + dir * (std::cos(angle1) * radius) +
                  right * (std::sin(angle1) * radius);
      PointF p2 = center + dir * (std::cos(angle2) * radius) +
                  right * (std::sin(angle2) * radius);

      // Triangle: center, p1, p2 (draw as degenerate quad)
      CoordsBuffer coordsBuffer;
      coordsBuffer.addCustomQuad(center, p1, p2, p2, RectF(0, 0, 1, 1));
      g_painter->drawTextureCoords(coordsBuffer, whiteTexture);
    }
  };

  Color capCoreColor = m_coreColor;
  capCoreColor.setAlpha(230);

  // Draw START cap (facing backward) - aura then core
  drawHalfCircle(bodyStart, dir * -1.0f, auraWidth * 0.5f,
                 Color((uint8)m_color.r(), (uint8)m_color.g(),
                       (uint8)m_color.b(), (uint8)64),
                 true);
  drawHalfCircle(bodyStart, dir * -1.0f, coreWidth * 0.5f, capCoreColor, true);

  // Draw END cap (facing forward) - aura then core
  drawHalfCircle(bodyEnd, dir, auraWidth * 0.5f,
                 Color((uint8)m_color.r(), (uint8)m_color.g(),
                       (uint8)m_color.b(), (uint8)64),
                 false);
  drawHalfCircle(bodyEnd, dir, coreWidth * 0.5f, capCoreColor, false);

  // --- PARTICLES (After beam, so they appear to "escape") ---
  for (const auto &particle : m_particles) {
    // Calculate particle position
    PointF basePos = startF + dir * (particle.t * length);
    PointF particlePos = basePos + perp * particle.offset;

    // Fade based on remaining life
    float alpha = particle.life / particle.maxLife;

    // Small circle (radius ~1.5px)
    float radius = 1.5f;

    // Golden/white color matching beam aura
    Color particleColor = m_particleColor;
    particleColor.setAlpha((int)(128 * alpha)); // 50% max opacity, fading

    g_painter->setColor(particleColor);

    // Draw as small quad (approximating circle)
    PointF p1 = particlePos + PointF(-radius, -radius);
    PointF p2 = particlePos + PointF(radius, -radius);
    PointF p3 = particlePos + PointF(radius, radius);
    PointF p4 = particlePos + PointF(-radius, radius);

    CoordsBuffer coordsBuffer;
    coordsBuffer.addCustomQuad(p1, p2, p3, p4, RectF(0, 0, 1, 1));
    g_painter->drawTextureCoords(coordsBuffer, whiteTexture);
  }

  g_painter->restoreSavedState();
}

void DrawQueueConditionClip::start(DrawQueue *) {
  m_prevClip = g_painter->getClipRect();
  g_painter->setClipRect(m_rect);
}

void DrawQueueConditionClip::end(DrawQueue *) {
  g_painter->setClipRect(m_prevClip);
}

void DrawQueueConditionRotation::start(DrawQueue *) {
  g_painter->pushTransformMatrix();
  g_painter->rotate(m_center, m_angle);
}

void DrawQueueConditionRotation::end(DrawQueue *) {
  g_painter->popTransformMatrix();
}

void DrawQueueConditionMark::start(DrawQueue *) {
  // nothing
}

void DrawQueueConditionFlipHorizontal::start(DrawQueue *) {
  g_painter->pushTransformMatrix();
  // Espelha horizontalmente em torno do centro informado
  g_painter->translate(m_center.x, m_center.y);
  g_painter->scale(-1.0f, 1.0f);
  g_painter->translate(-m_center.x, -m_center.y);
}

void DrawQueueConditionFlipHorizontal::end(DrawQueue *) {
  g_painter->popTransformMatrix();
}

void DrawQueueConditionMark::end(DrawQueue *queue) {
  g_painter->setDrawColorOnTextureShaderProgram();
  g_painter->setColor(m_color);
  for (size_t i = m_start; i < m_end; ++i) {
    DrawQueueItemTexturedRect *texture =
        dynamic_cast<DrawQueueItemTexturedRect *>(queue->m_queue[i]);
    if (texture)
      g_painter->drawTexturedRect(texture->m_dest, texture->m_texture,
                                  texture->m_src);

    // Também aplica marcação em outfits (com e sem shader)
    if (auto outfit = dynamic_cast<DrawQueueItemOutfit *>(queue->m_queue[i])) {
      g_painter->drawTexturedRect(outfit->m_dest, outfit->m_texture,
                                  outfit->m_src);
    }
    if (auto outfitShader =
            dynamic_cast<DrawQueueItemOutfitWithShader *>(queue->m_queue[i])) {
      g_painter->drawTexturedRect(outfitShader->m_dest, outfitShader->m_texture,
                                  outfitShader->m_src);
    }
  }
  g_painter->resetShaderProgram();
}

void DrawQueue::setFrameBuffer(const Rect &dest, const Size &size,
                               const Rect &src) {
  m_useFrameBuffer = true;
  m_frameBufferSize = size;
  m_frameBufferDest = dest;
  m_frameBufferSrc = src;
  size_t max_size =
      std::max(m_frameBufferSize.width(), m_frameBufferSize.height());
  while (max_size > 2048u) {
    max_size /= 2;
    m_scaling /= 2.f;
  }
  if (m_scaling < 0.99f) {
    m_frameBufferSize = Size(2048, 2048);
    m_frameBufferSrc = m_frameBufferSrc * m_scaling;
  }
}

void DrawQueue::addText(BitmapFontPtr font, const std::string &text,
                        const Rect &screenCoords, Fw::AlignmentFlag align,
                        const Color &color, bool shadow) {
  if (!font || text.empty())
    return;
  uint64_t hash = g_text.addText(font, text, screenCoords.size(), align);
  m_queue.push_back(new DrawQueueItemText(
      screenCoords.topLeft(), font->getTexture(), hash, color, shadow));
}

void DrawQueue::addColoredText(BitmapFontPtr font, const std::string &text,
                               const Rect &screenCoords,
                               Fw::AlignmentFlag align,
                               const std::vector<std::pair<int, Color>> &colors,
                               bool shadow) {
  if (!font || text.empty())
    return;
  uint64_t hash = g_text.addText(font, text, screenCoords.size(), align);
  m_queue.push_back(new DrawQueueItemTextColored(
      screenCoords.topLeft(), font->getTexture(), hash, colors, shadow));
}

void DrawQueue::correctOutfit(const Rect &dest, int fromPos, bool oldScaling) {
  std::vector<Rect *> rects;
  if (!oldScaling) {
    bool center = false;
    int centerX = 0;
    int centerY = 0;
    for (size_t i = fromPos; i < m_queue.size(); ++i) {
      if (DrawQueueItemOutfit *texture =
              dynamic_cast<DrawQueueItemOutfit *>(m_queue[i])) {
        rects.push_back(&texture->m_dest);
        if (!center) {
          center = texture->m_doCenter;
        }

        if (texture->m_doCenter) {
          centerX = std::max<int>(centerX, texture->m_dest.center().x);
          centerY = std::max<int>(centerY, texture->m_dest.center().y);
        }
      } else if (DrawQueueItemOutfitWithShader *texture =
                     dynamic_cast<DrawQueueItemOutfitWithShader *>(
                         m_queue[i])) {
        rects.push_back(&texture->m_dest);
        if (!center) {
          center = texture->m_doCenter;
        }

        if (texture->m_doCenter) {
          centerX = std::max<int>(centerX, texture->m_dest.center().x);
        }
      } else if (DrawQueueItemTexturedRect *texture =
                     dynamic_cast<DrawQueueItemTexturedRect *>(m_queue[i])) {
        rects.push_back(&texture->m_dest);
      }
    }

    int x1 = -g_sprites.spriteSize(), y1 = -g_sprites.spriteSize(),
        x2 = g_sprites.spriteSize(), y2 = g_sprites.spriteSize();
    float scale = std::min<float>((float)dest.height() / (y2 - y1),
                                  (float)dest.width() / (x2 - x1));
    for (auto &rect : rects) {
      int x = rect->left() - x1 - centerX,
          y = rect->top() - y1 - centerY; // offset
      *rect = Rect(dest.left() + x * scale, dest.top() + y * scale,
                   rect->size() * scale);
    }
  } else {
    for (size_t i = fromPos; i < m_queue.size(); ++i) {
      if (DrawQueueItemTexturedRect *texture =
              dynamic_cast<DrawQueueItemTexturedRect *>(m_queue[i]))
        rects.push_back(&texture->m_dest);
    }

    int x1 = 0, y1 = 1, x2 = 0, y2 = 0;
    for (auto &rect : rects) {
      x1 = std::min<int>(x1, rect->left());
      y1 = std::min<int>(y1, rect->top());
      x2 = std::max<int>(x2, rect->right());
      y2 = std::max<int>(y2, rect->bottom());
    }
    if (x1 == x2 || y1 == y2)
      return;

    float scale = std::min<float>((float)dest.height() / (y2 - y1),
                                  (float)dest.width() / (x2 - x1));
    for (auto &rect : rects) {
      int x = rect->left() - x1, y = rect->top() - y1; // offset
      *rect = Rect(dest.left() + x * scale, dest.top() + y * scale,
                   rect->size() * scale);
    }
  }
}

void DrawQueue::draw(DrawType drawType) {
  size_t start = 0;
  size_t end = m_queue.size();
  if (drawType == DRAW_BEFORE_MAP) {
    end = mapPosition;
  } else if (drawType == DRAW_AFTER_MAP) {
    start = mapPosition;
  }

  std::sort(
      m_conditions.begin(), m_conditions.end(),
      [](const DrawQueueCondition *a, const DrawQueueCondition *b) -> bool {
        return a->m_start == b->m_start ? a->m_end < b->m_end
                                        : a->m_start < b->m_start;
      });

  Size originalResolution = g_painter->getResolution();
  if (m_scaling > 0.f && m_scaling < 0.99f) {
    Size resolution = originalResolution * (1.f / m_scaling);
    Matrix3 projectionMatrix = {2.0f / resolution.width(),
                                0.0f,
                                0.0f,
                                0.0f,
                                -2.0f / resolution.height(),
                                0.0f,
                                -1.0f,
                                1.0f,
                                1.0f};
    g_painter->setProjectionMatrix(projectionMatrix);
  }

  auto condition = m_conditions.begin();
  std::stack<DrawQueueCondition *> activeConditions;
  // skip conditions
  while (condition != m_conditions.end() && (*condition)->m_end <= start)
    ++condition;
  // execute conditions & draw
  for (size_t i = start; i < end; ++i) {
    if (DrawQueueItemBeam *beamItem =
            dynamic_cast<DrawQueueItemBeam *>(m_queue[i])) {
      static float lastPrint = 0;
      if (g_clock.seconds() - lastPrint > 2.0f) {
        // No log here anymore
      }
    }
    while (!activeConditions.empty() && activeConditions.top()->m_end <= i) {
      g_drawCache.draw();
      activeConditions.top()->end(this);
      activeConditions.pop();
    }
    while (condition != m_conditions.end() && (*condition)->m_start <= i) {
      g_drawCache.draw();
      (*condition)->start(this);
      activeConditions.push(*condition);
      ++condition;
    }

    if (!m_queue[i]->cache()) {
      g_drawCache.draw();
      if (!m_queue[i]->cache()) { // try to cache again, now g_drawCache
                                  // should be empty, maybe there's new space
        m_queue[i]->draw();
      }
    }
    if (g_drawCache.getSize() >= g_drawCache.HALF_MAX_SIZE) {
      g_drawCache.draw();
    }
  }
  g_drawCache.draw();
  // end all actibe conditions
  while (!activeConditions.empty()) {
    activeConditions.top()->end(this);
    activeConditions.pop();
  }

  g_painter->setResolution(originalResolution);
  g_painter->resetState();
  g_graphics.checkForError(__FUNCTION__, __FILE__, __LINE__);
}
