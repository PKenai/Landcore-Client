#ifndef BEAM_H
#define BEAM_H

#include "creature.h"
#include <framework/luaengine/luaobject.h>
#include <framework/util/color.h>
#include <vector>

// Forward declaration (defined in drawqueue.h)
struct BeamParticle;

// @bindclass
class Beam : public LuaObject {
public:
  Beam();
  virtual ~Beam() = default;

  void setSourceCreature(const CreaturePtr &creature) {
    m_sourceCreature = creature;
    m_sourcePos = Position();
  }
  void setTargetCreature(const CreaturePtr &creature) {
    m_targetCreature = creature;
    m_targetPos = Position();
  }

  void setSourcePos(const Position &pos) {
    m_sourcePos = pos;
    m_sourceCreature = nullptr;
  }
  void setTargetPos(const Position &pos) {
    m_targetPos = pos;
    m_targetCreature = nullptr;
  }

  void setThickness(float thickness) { m_thickness = thickness; }
  void setColor(const Color &color) { m_color = color; }
  void setParticleColor(const Color &color) { m_particleColor = color; }
  void setShader(const std::string &shader) { m_shader = shader; }
  void setDuration(int duration);

  CreaturePtr getSourceCreature() { return m_sourceCreature; }
  CreaturePtr getTargetCreature() { return m_targetCreature; }

  Position getSourcePos();
  Position getTargetPos();

  float getThickness() { return m_thickness; }
  Color getColor() { return m_color; }
  Color getParticleColor() { return m_particleColor; }
  std::string getShader() { return m_shader; }
  float getTime() { return m_time; }
  const std::vector<BeamParticle> &getParticles() const { return m_particles; }

  void update(float deltaTime);
  bool isFinished();

  BeamPtr asBeam() { return static_self_cast<Beam>(); }

private:
  void spawnParticle();
  void updateParticles(float deltaTime);
  float randomFloat(float min, float max);

  CreaturePtr m_sourceCreature;
  CreaturePtr m_targetCreature;
  Position m_sourcePos;
  Position m_targetPos;
  float m_thickness;
  Color m_color;
  Color m_particleColor;
  std::string m_shader;
  ticks_t m_endTime;
  float m_time;
  std::vector<BeamParticle> m_particles;
};

#endif
