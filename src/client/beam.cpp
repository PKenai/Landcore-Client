#include "beam.h"
#include <framework/core/clock.h>

Beam::Beam()
    : m_thickness(10.0f), m_color(Color::white), m_shader("beam_shader"),
      m_endTime(0) {}

void Beam::setDuration(int duration) {
  if (duration > 0)
    m_endTime = g_clock.millis() + duration;
  else
    m_endTime = 0;
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
