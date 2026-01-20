#include "beam.h"
#include <cmath>
#include <cstdlib>
#include <framework/core/clock.h>

Beam::Beam()
    : m_thickness(10.0f), m_color(Color::white),
      m_particleColor(255, 230, 153), // Default golden
      m_shader("beam_shader"), m_endTime(0), m_time(0.0f) {}

void Beam::setDuration(int duration) {
  if (duration > 0)
    m_endTime = g_clock.millis() + duration;
  else
    m_endTime = 0;
}

void Beam::update(float deltaTime) {
  m_time += deltaTime;
  updateParticles(deltaTime);

  // Spawn particles (max 20, 20% chance per frame)
  if (m_particles.size() < 20 && randomFloat(0.0f, 1.0f) < 0.2f) {
    spawnParticle();
  }
}

void Beam::spawnParticle() {
  BeamParticle p;
  p.t = randomFloat(0.0f, 1.0f);
  p.offset = randomFloat(-6.0f, 6.0f);
  p.speed = randomFloat(-0.2f, 0.4f);
  p.life = p.maxLife = randomFloat(0.4f, 0.8f);
  m_particles.push_back(p);
}

void Beam::updateParticles(float deltaTime) {
  for (int i = 0; i < (int)m_particles.size(); i++) {
    auto &p = m_particles[i];

    p.life -= deltaTime;
    p.t += p.speed * deltaTime;

    // Drift with sine wave
    p.offset += std::sin(m_time * 6.0f + i) * deltaTime * 3.0f;

    // Remove dead particles
    if (p.life <= 0.0f) {
      m_particles.erase(m_particles.begin() + i);
      i--;
    }
  }
}

float Beam::randomFloat(float min, float max) {
  return min + (float)rand() / RAND_MAX * (max - min);
}

Position Beam::getSourcePos() {
  if (m_sourceCreature)
    return m_sourceCreature->getPosition();
  return m_sourcePos;
}

Position Beam::getTargetPos() {
  if (m_targetCreature)
    return m_targetCreature->getPosition();
  return m_targetPos;
}

bool Beam::isFinished() {
  if (m_endTime == 0)
    return false;
  return g_clock.millis() >= m_endTime;
}
