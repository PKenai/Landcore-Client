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

#ifndef OUTFIT_H
#define OUTFIT_H

#include <framework/util/color.h>
#include "thingtypemanager.h"
#include <framework/graphics/drawqueue.h>

class Outfit
{
public:
    Outfit();

    static Color getColor(int color)
    {
        return Color::getOutfitColor(color);
    }

    void draw(Point dest, Otc::Direction direction, uint walkAnimationPhase, bool animate = true, LightView* lightView = nullptr, bool ui = false);
    void draw(const Rect& dest, Otc::Direction direction, uint animationPhase, bool animate = true, bool ui = false, bool oldScaling = false);

    void setId(int id) { m_id = id; }
    void setAuxId(int id) { m_auxId = id; }
    void setHead(int head) { m_head = head; }
    void setBody(int body) { m_body = body; }
    void setLegs(int legs) { m_legs = legs; }
    void setFeet(int feet) { m_feet = feet; }
    void setAddons(int addons) { m_addons = addons; }
    void setMount(int mount) { m_mount = mount; }
    void setWings(int wings) { m_wings = wings; }
    void setAura(int aura) { m_aura = aura; }
    void setCategory(ThingCategory category) { m_category = category; }
    void setShader(const std::string& shader) { m_shader = shader; }
    void setHealthBar(uint8 id) { m_healthBar = id; }
    void setManaBar(uint8 id) { m_manaBar = id; }
    void setCenter(bool value) { m_center = value; }

    // Paperdoll setters
    void setHair(int hair) { m_hair = hair; }
    void setHairColor(int hairColor) { m_hairColor = hairColor; }
    void setSkinColor(int skinColor) { m_skinColor = skinColor; }
    void setRightHand(int rightHand) { m_rightHand = rightHand; }
    void setRightHandColor(int rightHandColor) { m_rightHandColor = rightHandColor; }
    void setLeftHand(int leftHand) { m_leftHand = leftHand; }
    void setLeftHandColor(int leftHandColor) { m_leftHandColor = leftHandColor; }
    void setHelmet(int helmet) { m_helmet = helmet; }
    void setHelmetColor(int helmetColor) { m_helmetColor = helmetColor; }
    void setArmor(int armor) { m_armor = armor; }
    void setArmorColor(int armorColor) { m_armorColor = armorColor; }
    void setShirt(int shirt) { m_shirt = shirt; }
    void setShirtColor(int shirtColor) { m_shirtColor = shirtColor; }
    void setPants(int pants) { m_pants = pants; }
    void setPantsColor(int pantsColor) { m_pantsColor = pantsColor; }
    void setBoots(int boots) { m_boots = boots; }
    void setBootsColor(int bootsColor) { m_bootsColor = bootsColor; }
    void setNecklace(int necklace) { m_necklace = necklace; }
    void setNecklaceColor(int necklaceColor) { m_necklaceColor = necklaceColor; }
    void setRingLeft(int ringLeft) { m_ringLeft = ringLeft; }
    void setRingLeftColor(int ringLeftColor) { m_ringLeftColor = ringLeftColor; }
    void setRingRight(int ringRight) { m_ringRight = ringRight; }
    void setRingRightColor(int ringRightColor) { m_ringRightColor = ringRightColor; }
    void setBackpack(int backpack) { m_backpack = backpack; }
    void setBackpackColor(int backpackColor) { m_backpackColor = backpackColor; }
    void setCloak(int cloak) { m_cloak = cloak; }
    void setCloakColor(int cloakColor) { m_cloakColor = cloakColor; }
    void setGloves(int gloves) { m_gloves = gloves; }
    void setGlovesColor(int glovesColor) { m_glovesColor = glovesColor; }
    void setBelt(int belt) { m_belt = belt; }
    void setBeltColor(int beltColor) { m_beltColor = beltColor; }

    void resetClothes();
    void resetShader() { m_shader = ""; }

    int getId() const { return m_id; }
    int getAuxId() const { return m_auxId; }
    int getHead() const { return m_head; }
    int getBody() const { return m_body; }
    int getLegs() const { return m_legs; }
    int getFeet() const { return m_feet; }
    int getAddons() const { return m_addons; }
    int getMount() const { return m_mount; }
    int getWings() const { return m_wings; }
    int getAura() const { return m_aura; }
    ThingCategory getCategory() const { return m_category; }
    std::string getShader() const { return m_shader; }
    int getHealthBar() const { return m_healthBar; }
    int getManaBar() const { return m_manaBar; }

    // Paperdoll getters
    int getHair() const { return m_hair; }
    int getHairColor() const { return m_hairColor; }
    int getSkinColor() const { return m_skinColor; }
    int getRightHand() const { return m_rightHand; }
    int getRightHandColor() const { return m_rightHandColor; }
    int getLeftHand() const { return m_leftHand; }
    int getLeftHandColor() const { return m_leftHandColor; }
    int getHelmet() const { return m_helmet; }
    int getHelmetColor() const { return m_helmetColor; }
    int getArmor() const { return m_armor; }
    int getArmorColor() const { return m_armorColor; }
    int getShirt() const { return m_shirt; }
    int getShirtColor() const { return m_shirtColor; }
    int getPants() const { return m_pants; }
    int getPantsColor() const { return m_pantsColor; }
    int getBoots() const { return m_boots; }
    int getBootsColor() const { return m_bootsColor; }
    int getNecklace() const { return m_necklace; }
    int getNecklaceColor() const { return m_necklaceColor; }
    int getRingLeft() const { return m_ringLeft; }
    int getRingLeftColor() const { return m_ringLeftColor; }
    int getRingRight() const { return m_ringRight; }
    int getRingRightColor() const { return m_ringRightColor; }
    int getBackpack() const { return m_backpack; }
    int getBackpackColor() const { return m_backpackColor; }
    int getCloak() const { return m_cloak; }
    int getCloakColor() const { return m_cloakColor; }
    int getGloves() const { return m_gloves; }
    int getGlovesColor() const { return m_glovesColor; }
    int getBelt() const { return m_belt; }
    int getBeltColor() const { return m_beltColor; }

private:
    ThingCategory m_category;
    int m_id, m_auxId, m_head, m_body, m_legs, m_feet, m_addons, m_mount = 0, m_wings = 0, m_aura = 0;
    int m_healthBar = 0, m_manaBar = 0;
    std::string m_shader;
    bool m_center = false;
    
    // Paperdoll member variables
    int m_hair = 0, m_hairColor = 0, m_skinColor = 0;
    int m_rightHand = 0, m_rightHandColor = 0, m_leftHand = 0, m_leftHandColor = 0;
    int m_helmet = 0, m_helmetColor = 0, m_armor = 0, m_armorColor = 0;
    int m_shirt = 0, m_shirtColor = 0, m_pants = 0, m_pantsColor = 0;
    int m_boots = 0, m_bootsColor = 0, m_necklace = 0, m_necklaceColor = 0;
    int m_ringLeft = 0, m_ringLeftColor = 0, m_ringRight = 0, m_ringRightColor = 0;
    int m_backpack = 0, m_backpackColor = 0, m_cloak = 0, m_cloakColor = 0;
    int m_gloves = 0, m_glovesColor = 0, m_belt = 0, m_beltColor = 0;
};

struct DrawQueueItemOutfit : public DrawQueueItemTexturedRect {
    DrawQueueItemOutfit(const Rect& rect, const TexturePtr& texture, const Rect& src, const Point& offset, int32_t colors, const Color& color, bool doCenter) :
        DrawQueueItemTexturedRect(rect, texture, src, color), m_offset(offset), m_colors(colors), m_doCenter(doCenter)
    {};

    void draw() override;
    void draw(const Point& pos) override;
    bool cache() override;

    Point m_offset;
    int32_t m_colors;
    bool m_doCenter;
};

struct DrawQueueItemOutfitWithShader : public DrawQueueItemTexturedRect {
    DrawQueueItemOutfitWithShader(const Rect& rect, const TexturePtr& texture, const Rect& src, const Point& offset, const Point& center, int32_t colors, const std::string& shader, bool doCenter) :
        DrawQueueItemTexturedRect(rect, texture, src, Color::white), m_offset(offset), m_center(center), m_colors(colors), m_shader(shader), m_doCenter(doCenter)
    {};

    void draw() override;
    void draw(const Point& pos) override
    {}
    bool cache() override
    {
        return false;
    }

    Point m_offset;
    Point m_center;
    int32_t m_colors;
    std::string m_shader;
    bool m_doCenter;
};

#endif
