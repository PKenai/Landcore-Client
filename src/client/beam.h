#ifndef BEAM_H
#define BEAM_H

#include "creature.h"
#include <framework/luaengine/luaobject.h>
#include <framework/util/color.h>


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
  void setShader(const std::string &shader) { m_shader = shader; }
  void setDuration(int duration);

  CreaturePtr getSourceCreature() { return m_sourceCreature; }
  CreaturePtr getTargetCreature() { return m_targetCreature; }

  Position getSourcePos();
  Position getTargetPos();

  float getThickness() { return m_thickness; }
  Color getColor() { return m_color; }
  std::string getShader() { return m_shader; }

  bool isFinished();

  BeamPtr asBeam() { return static_self_cast<Beam>(); }

private:
  CreaturePtr m_sourceCreature;
  CreaturePtr m_targetCreature;
  Position m_sourcePos;
  Position m_targetPos;
  float m_thickness;
  Color m_color;
  std::string m_shader;
  ticks_t m_endTime;
};

#endif
