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

#include "luavaluecasts_client.h"
#include <framework/luaengine/luainterface.h>

int push_luavalue(const Outfit& outfit)
{
    g_lua.createTable(0, 50); // Increased size for paperdoll fields
    g_lua.pushInteger(outfit.getId());
    g_lua.setField("type");
    g_lua.pushInteger(outfit.getAuxId());
    g_lua.setField("auxType");
    if(g_game.getFeature(Otc::GamePlayerAddons)) {
        g_lua.pushInteger(outfit.getAddons());
        g_lua.setField("addons");
    }
    g_lua.pushInteger(outfit.getHead());
    g_lua.setField("head");
    g_lua.pushInteger(outfit.getBody());
    g_lua.setField("body");
    g_lua.pushInteger(outfit.getLegs());
    g_lua.setField("legs");
    g_lua.pushInteger(outfit.getFeet());
    g_lua.setField("feet");
    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        g_lua.pushInteger(outfit.getMount());
        g_lua.setField("mount");
    }
    if (g_game.getFeature(Otc::GameWingsAndAura)) {
        g_lua.pushInteger(outfit.getWings());
        g_lua.setField("wings");
        g_lua.pushInteger(outfit.getAura());
        g_lua.setField("aura");
    }
    if (g_game.getFeature(Otc::GameOutfitShaders)) {
        g_lua.pushString(outfit.getShader());
        g_lua.setField("shader");
    }
    if (g_game.getFeature(Otc::GameHealthInfoBackground)) {
        g_lua.pushInteger(outfit.getHealthBar());
        g_lua.setField("healthBar");
        g_lua.pushInteger(outfit.getManaBar());
        g_lua.setField("manaBar");
    }
    
    // Push paperdoll data to Lua
    g_lua.pushInteger(outfit.getHair());
    g_lua.setField("hair");
    g_lua.pushInteger(outfit.getHairColor());
    g_lua.setField("hairColor");
    g_lua.pushInteger(outfit.getSkinColor());
    g_lua.setField("skinColor");
    g_lua.pushInteger(outfit.getRightHand());
    g_lua.setField("rightHand");
    g_lua.pushInteger(outfit.getRightHandColor());
    g_lua.setField("rightHandColor");
    g_lua.pushInteger(outfit.getLeftHand());
    g_lua.setField("leftHand");
    g_lua.pushInteger(outfit.getLeftHandColor());
    g_lua.setField("leftHandColor");
    g_lua.pushInteger(outfit.getHelmet());
    g_lua.setField("helmet");
    g_lua.pushInteger(outfit.getHelmetColor());
    g_lua.setField("helmetColor");
    g_lua.pushInteger(outfit.getArmor());
    g_lua.setField("armor");
    g_lua.pushInteger(outfit.getArmorColor());
    g_lua.setField("armorColor");
    g_lua.pushInteger(outfit.getShirt());
    g_lua.setField("shirt");
    g_lua.pushInteger(outfit.getShirtColor());
    g_lua.setField("shirtColor");
    g_lua.pushInteger(outfit.getPants());
    g_lua.setField("pants");
    g_lua.pushInteger(outfit.getPantsColor());
    g_lua.setField("pantsColor");
    g_lua.pushInteger(outfit.getBoots());
    g_lua.setField("boots");
    g_lua.pushInteger(outfit.getBootsColor());
    g_lua.setField("bootsColor");
    g_lua.pushInteger(outfit.getNecklace());
    g_lua.setField("necklace");
    g_lua.pushInteger(outfit.getNecklaceColor());
    g_lua.setField("necklaceColor");
    g_lua.pushInteger(outfit.getRingLeft());
    g_lua.setField("ringLeft");
    g_lua.pushInteger(outfit.getRingLeftColor());
    g_lua.setField("ringLeftColor");
    g_lua.pushInteger(outfit.getRingRight());
    g_lua.setField("ringRight");
    g_lua.pushInteger(outfit.getRingRightColor());
    g_lua.setField("ringRightColor");
    g_lua.pushInteger(outfit.getBackpack());
    g_lua.setField("backpack");
    g_lua.pushInteger(outfit.getBackpackColor());
    g_lua.setField("backpackColor");
    g_lua.pushInteger(outfit.getCloak());
    g_lua.setField("cloak");
    g_lua.pushInteger(outfit.getCloakColor());
    g_lua.setField("cloakColor");
    g_lua.pushInteger(outfit.getGloves());
    g_lua.setField("gloves");
    g_lua.pushInteger(outfit.getGlovesColor());
    g_lua.setField("glovesColor");
    g_lua.pushInteger(outfit.getBelt());
    g_lua.setField("belt");
    g_lua.pushInteger(outfit.getBeltColor());
    g_lua.setField("beltColor");
    
    return 1;
}

bool luavalue_cast(int index, Outfit& outfit)
{
    if(g_lua.isTable(index)) {
        g_lua.getField("type", index);
        outfit.setId(g_lua.popInteger());
        g_lua.getField("auxType", index);
        outfit.setAuxId(g_lua.popInteger());
        if(g_game.getFeature(Otc::GamePlayerAddons)) {
            g_lua.getField("addons", index);
            outfit.setAddons(g_lua.popInteger());
        }
        g_lua.getField("head", index);
        outfit.setHead(g_lua.popInteger());
        g_lua.getField("body", index);
        outfit.setBody(g_lua.popInteger());
        g_lua.getField("legs", index);
        outfit.setLegs(g_lua.popInteger());
        g_lua.getField("feet", index);
        outfit.setFeet(g_lua.popInteger());
        if (g_game.getFeature(Otc::GamePlayerMounts)) {
            g_lua.getField("mount", index);
            outfit.setMount(g_lua.popInteger());
        }
        if (g_game.getFeature(Otc::GameWingsAndAura)) {
            g_lua.getField("wings", index);
            outfit.setWings(g_lua.popInteger());
            g_lua.getField("aura", index);
            outfit.setAura(g_lua.popInteger());
        }
        //if (g_game.getFeature(Otc::GameOutfitShaders)) {
            g_lua.getField("shader", index);
            outfit.setShader(g_lua.popString());
        //}
        if (g_game.getFeature(Otc::GameHealthInfoBackground)) {
            g_lua.getField("healthBar", index);
            outfit.setHealthBar(g_lua.popInteger());
            g_lua.getField("manaBar", index);
            outfit.setManaBar(g_lua.popInteger());
        }
        
        // Read paperdoll data from Lua
        g_lua.getField("hair", index);
        outfit.setHair(g_lua.popInteger());
        g_lua.getField("hairColor", index);
        outfit.setHairColor(g_lua.popInteger());
        g_lua.getField("skinColor", index);
        outfit.setSkinColor(g_lua.popInteger());
        g_lua.getField("rightHand", index);
        outfit.setRightHand(g_lua.popInteger());
        g_lua.getField("rightHandColor", index);
        outfit.setRightHandColor(g_lua.popInteger());
        g_lua.getField("leftHand", index);
        outfit.setLeftHand(g_lua.popInteger());
        g_lua.getField("leftHandColor", index);
        outfit.setLeftHandColor(g_lua.popInteger());
        g_lua.getField("helmet", index);
        outfit.setHelmet(g_lua.popInteger());
        g_lua.getField("helmetColor", index);
        outfit.setHelmetColor(g_lua.popInteger());
        g_lua.getField("armor", index);
        outfit.setArmor(g_lua.popInteger());
        g_lua.getField("armorColor", index);
        outfit.setArmorColor(g_lua.popInteger());
        g_lua.getField("shirt", index);
        outfit.setShirt(g_lua.popInteger());
        g_lua.getField("shirtColor", index);
        outfit.setShirtColor(g_lua.popInteger());
        g_lua.getField("pants", index);
        outfit.setPants(g_lua.popInteger());
        g_lua.getField("pantsColor", index);
        outfit.setPantsColor(g_lua.popInteger());
        g_lua.getField("boots", index);
        outfit.setBoots(g_lua.popInteger());
        g_lua.getField("bootsColor", index);
        outfit.setBootsColor(g_lua.popInteger());
        g_lua.getField("necklace", index);
        outfit.setNecklace(g_lua.popInteger());
        g_lua.getField("necklaceColor", index);
        outfit.setNecklaceColor(g_lua.popInteger());
        g_lua.getField("ringLeft", index);
        outfit.setRingLeft(g_lua.popInteger());
        g_lua.getField("ringLeftColor", index);
        outfit.setRingLeftColor(g_lua.popInteger());
        g_lua.getField("ringRight", index);
        outfit.setRingRight(g_lua.popInteger());
        g_lua.getField("ringRightColor", index);
        outfit.setRingRightColor(g_lua.popInteger());
        g_lua.getField("backpack", index);
        outfit.setBackpack(g_lua.popInteger());
        g_lua.getField("backpackColor", index);
        outfit.setBackpackColor(g_lua.popInteger());
        g_lua.getField("cloak", index);
        outfit.setCloak(g_lua.popInteger());
        g_lua.getField("cloakColor", index);
        outfit.setCloakColor(g_lua.popInteger());
        g_lua.getField("gloves", index);
        outfit.setGloves(g_lua.popInteger());
        g_lua.getField("glovesColor", index);
        outfit.setGlovesColor(g_lua.popInteger());
        g_lua.getField("belt", index);
        outfit.setBelt(g_lua.popInteger());
        g_lua.getField("beltColor", index);
        outfit.setBeltColor(g_lua.popInteger());
        
        return true;
    }
    return false;
}

int push_luavalue(const Position& pos)
{
    if(pos.isValid()) {
        g_lua.createTable(0, 3);
        g_lua.pushInteger(pos.x);
        g_lua.setField("x");
        g_lua.pushInteger(pos.y);
        g_lua.setField("y");
        g_lua.pushInteger(pos.z);
        g_lua.setField("z");
    } else
        g_lua.pushNil();
    return 1;
}

bool luavalue_cast(int index, Position& pos)
{
    if(g_lua.isTable(index)) {
        g_lua.getField("x", index);
        pos.x = g_lua.popInteger();
        g_lua.getField("y", index);
        pos.y = g_lua.popInteger();
        g_lua.getField("z", index);
        pos.z = g_lua.popInteger();
        return true;
    }
    return false;
}

int push_luavalue(const MarketData& data)
{
    g_lua.createTable(0, 6);
    g_lua.pushInteger(data.category);
    g_lua.setField("category");
    g_lua.pushString(data.name);
    g_lua.setField("name");
    g_lua.pushInteger(data.requiredLevel);
    g_lua.setField("requiredLevel");
    g_lua.pushInteger(data.restrictVocation);
    g_lua.setField("restrictVocation");
    g_lua.pushInteger(data.showAs);
    g_lua.setField("showAs");
    g_lua.pushInteger(data.tradeAs);
    g_lua.setField("tradeAs");
    return 1;
}

bool luavalue_cast(int index, MarketData& data)
{
    if (g_lua.isTable(index)) {
        g_lua.getField("category", index);
        data.category = g_lua.popInteger();
        g_lua.getField("name", index);
        data.name = g_lua.popString();
        g_lua.getField("requiredLevel", index);
        data.requiredLevel = g_lua.popInteger();
        g_lua.getField("restrictVocation", index);
        data.restrictVocation = g_lua.popInteger();
        g_lua.getField("showAs", index);
        data.showAs = g_lua.popInteger();
        g_lua.getField("tradeAs", index);
        data.tradeAs = g_lua.popInteger();
        return true;
    }
    return false;
}

int push_luavalue(const StoreCategory& category)
{
    g_lua.createTable(0, 5);
    g_lua.pushString(category.name);
    g_lua.setField("name");
    g_lua.pushString(category.description);
    g_lua.setField("description");
    g_lua.pushInteger(category.state);
    g_lua.setField("state");
    g_lua.pushString(category.icon);
    g_lua.setField("icon");
    g_lua.pushString(category.parent);
    g_lua.setField("parent");
    return 1;
}

bool luavalue_cast(int index, StoreCategory& data)
{
    if (g_lua.isTable(index)) {
        g_lua.getField("name", index);
        data.name = g_lua.popString();
        g_lua.getField("description", index);
        data.description = g_lua.popString();
        g_lua.getField("state", index);
        data.state = g_lua.popInteger();
        g_lua.getField("icon", index);
        data.icon = g_lua.popString();
        g_lua.getField("parent", index);
        data.parent = g_lua.popString();
        return true;
    }
    return false;
}

int push_luavalue(const StoreOffer& offer)
{
    g_lua.createTable(0, 6);
    g_lua.pushInteger(offer.id);
    g_lua.setField("id");
    g_lua.pushString(offer.name);
    g_lua.setField("name");
    g_lua.pushString(offer.description);
    g_lua.setField("description");
    g_lua.pushInteger(offer.price);
    g_lua.setField("price");
    g_lua.pushInteger(offer.state);
    g_lua.setField("state");
    g_lua.pushString(offer.icon);
    g_lua.setField("icon");
    return 1;
}

bool luavalue_cast(int index, StoreOffer& data)
{
    if (g_lua.isTable(index)) {
        g_lua.getField("id", index);
        data.id = g_lua.popInteger();
        g_lua.getField("name", index);
        data.name = g_lua.popString();
        g_lua.getField("description", index);
        data.description = g_lua.popString();
        g_lua.getField("state", index);
        data.state = g_lua.popInteger();
        g_lua.getField("price", index);
        data.price = g_lua.popInteger();
        g_lua.getField("icon", index);
        data.icon = g_lua.popString();
        return true;
    }
    return false;
}

int push_luavalue(const Imbuement& i)
{
    g_lua.createTable(0, 11);
    g_lua.pushInteger(i.id);
    g_lua.setField("id");
    g_lua.pushString(i.name);
    g_lua.setField("name");
    g_lua.pushString(i.description);
    g_lua.setField("description");
    g_lua.pushString(i.group);
    g_lua.setField("group");
    g_lua.pushInteger(i.imageId);
    g_lua.setField("imageId");
    g_lua.pushInteger(i.duration);
    g_lua.setField("duration");
    g_lua.pushBoolean(i.premiumOnly);
    g_lua.setField("premiumOnly");
    g_lua.createTable(i.sources.size(), 0);
    for (size_t j = 0; j < i.sources.size(); ++j) {
        g_lua.createTable(0, 2);
        g_lua.pushObject(i.sources[j].first);
        g_lua.setField("item");
        g_lua.pushString(i.sources[j].second);
        g_lua.setField("description");
        g_lua.rawSeti(j + 1);
    }
    g_lua.setField("sources");
    g_lua.pushInteger(i.cost);
    g_lua.setField("cost");
    g_lua.pushInteger(i.successRate);
    g_lua.setField("successRate");
    g_lua.pushInteger(i.protectionCost);
    g_lua.setField("protectionCost");
    return 1;
}

int push_luavalue(const Light& light)
{
    g_lua.createTable(0, 2);
    g_lua.pushInteger(light.color);
    g_lua.setField("color");
    g_lua.pushInteger(light.intensity);
    g_lua.setField("intensity");
    return 1;
}

bool luavalue_cast(int index, Light& light)
{
    if(g_lua.isTable(index)) {
        g_lua.getField("color", index);
        light.color = g_lua.popInteger();
        g_lua.getField("intensity", index);
        light.intensity = g_lua.popInteger();
        return true;
    }
    return false;
}

int push_luavalue(const UnjustifiedPoints& unjustifiedPoints)
{
    g_lua.createTable(0, 7);
    g_lua.pushInteger(unjustifiedPoints.killsDay);
    g_lua.setField("killsDay");
    g_lua.pushInteger(unjustifiedPoints.killsDayRemaining);
    g_lua.setField("killsDayRemaining");
    g_lua.pushInteger(unjustifiedPoints.killsWeek);
    g_lua.setField("killsWeek");
    g_lua.pushInteger(unjustifiedPoints.killsWeekRemaining);
    g_lua.setField("killsWeekRemaining");
    g_lua.pushInteger(unjustifiedPoints.killsMonth);
    g_lua.setField("killsMonth");
    g_lua.pushInteger(unjustifiedPoints.killsMonthRemaining);
    g_lua.setField("killsMonthRemaining");
    g_lua.pushInteger(unjustifiedPoints.skullTime);
    g_lua.setField("skullTime");
    return 1;
}

bool luavalue_cast(int index, UnjustifiedPoints& unjustifiedPoints)
{
    if(g_lua.isTable(index)) {
        g_lua.getField("killsDay", index);
        unjustifiedPoints.killsDay = g_lua.popInteger();
        g_lua.getField("killsDayRemaining", index);
        unjustifiedPoints.killsDayRemaining = g_lua.popInteger();
        g_lua.getField("killsWeek", index);
        unjustifiedPoints.killsWeek = g_lua.popInteger();
        g_lua.getField("killsWeekRemaining", index);
        unjustifiedPoints.killsWeekRemaining = g_lua.popInteger();
        g_lua.getField("killsMonth", index);
        unjustifiedPoints.killsMonth = g_lua.popInteger();
        g_lua.getField("killsMonthRemaining", index);
        unjustifiedPoints.killsMonthRemaining = g_lua.popInteger();
        g_lua.getField("skullTime", index);
        unjustifiedPoints.skullTime = g_lua.popInteger();
        return true;
    }
    return false;
}
