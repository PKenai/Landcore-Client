# 📚 Documentação Completa dos Sistemas Landcore

> **Bem-vindo à documentação técnica dos sistemas implementados no Landcore!**

Esta documentação abrange todos os sistemas customizados implementados tanto no **cliente** quanto no **servidor** do Landcore, com explicações detalhadas, APIs e exemplos práticos.

---

## 🎯 Índice dos Sistemas

### 🖥️ **Sistemas do Cliente**
| Sistema | Status | Descrição |
|---------|--------|-----------|
| **[Sistema de Som](#-sistema-de-som)** | ✅ Completo | Sistema de áudio integrado com notificações |
| **[Sistema de Timer Visual](#-sistema-de-timer-visual)** | ✅ Completo | Timer visual com efeitos especiais |

### 🖥️ **Sistemas do Servidor**
| Sistema | Status | Descrição |
|---------|--------|-----------|
| **[Sistema de Progress Bar](#-sistema-de-progress-bar)** | ✅ Completo | Barras de progresso para criaturas |
| **[Sistema de Shield Bar](#-sistema-de-shield-bar)** | ✅ Completo | Sistema de escudo absorvedor |
| **[Sistema de Monster Icons](#-sistema-de-monster-icons)** | ✅ Completo | Ícones visuais para monstros |
| **[Sistema de Stun Target](#-sistema-de-stun-target)** | ✅ Completo | Indicador visual de atordoamento |
| **[Sistema de Shader UI](#-sistema-de-shader-ui)** | ✅ Completo | Efeitos visuais na interface |
| **[Sistema Market Andando](#-sistema-market-andando)** | ✅ Completo | Market acessível durante movimento |
| **[Sistema Monstros Coloridos](#-sistema-monstros-coloridos)** | ✅ Completo | Monstros com ataques coloridos |

---

## 🖥️ SISTEMAS DO CLIENTE

### 🔊 Sistema de Som

**Status:** ✅ Completo | **Arquivo:** `modules/game_sounds/`

O sistema de áudio integrado proporciona feedback sonoro para todas as interações do jogo, com sons personalizáveis por evento.

#### 🎵 Características Principais
- **Integração automática** com notificações
- **Sons personalizáveis** por evento
- **Performance otimizada**
- **Compatibilidade total** com código existente

#### 📋 API Lua (Cliente)
```lua
-- Notificação com som automático
sendPlayerNotification(player, "Mensagem!", 5, "text", "icone", {})

-- Som personalizado adicional
sound.sendSoundOtc(player, "level_up", 3)

-- Notificação global
sendGlobalNotification("Anúncio!", 10, "text", "aviso", {})
```

#### 📁 Arquivos Relacionados
- **Módulo:** `modules/game_sounds/`
- **Sons:** `data/sounds/*.ogg`
- **Integração:** `modules/game_interface/gameinterface.lua`

#### 📚 Documentação Completa
- [**Tutorial Completo**](Sistema%20de%20Som%20-%20Tutorial%20Completo.md)
- [**Exemplos Práticos**](Exemplos%20de%20Uso%20-%20Sistema%20de%20Som.md)
- [**Checklist**](Checklist%20-%20Sistema%20de%20Som.md)

---

### ⏰ Sistema de Timer Visual

**Status:** ✅ Completo | **Arquivo:** `modules/game_timer/`

Sistema de timer visual com efeitos cinematográficos para exibir contadores regressivos no jogo.

#### 🎭 Características Principais
- **Imagem de fundo customizada** (`timerbackground.png`)
- **Animação de revelação** tipo "pôr do sol" (de baixo para cima)
- **Texto com fade-in** coordenado
- **Fade out automático** nos últimos 5 segundos
- **Posicionamento** acima da spell bar
- **Comando integrado** `/timer <segundos>`

#### 🎬 Efeitos Visuais
1. **Revelação dramática**: Imagem surge cortada de baixo para cima
2. **Texto coordenado**: Aparece suavemente junto com a imagem
3. **Contagem precisa**: Atualização em tempo real
4. **Final elegante**: Fade out gradual antes de desaparecer

#### 📋 API Lua (Servidor)
```lua
-- Comando talkaction
/timer 300  -- 5 minutos

-- Via script (workaround atual)
player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "TIMER_START:300")

-- Após recompilação do servidor
player:sendTimer(300)  -- Método direto
```

#### 📋 API Lua (Cliente)
```lua
-- Iniciar timer (automático via servidor)
modules.game_timer.startTimer(300)

-- Verificar se há timer ativo
local ativo = modules.game_timer.isTimerActive()

-- Obter tempo restante
local restante = modules.game_timer.getRemainingTime()
```

#### 📁 Arquivos Relacionados
- **Módulo:** `modules/game_timer/`
- **UI:** `timer.otui`
- **Lógica:** `timer.lua`
- **Protocolo:** `modules/game_protocol/protocol.lua`

---

## 🖥️ SISTEMAS DO SERVIDOR

### 📊 Sistema de Progress Bar

**Status:** ✅ Completo | **Arquivo:** Sistema integrado no core

Sistema de barras de progresso visuais que aparecem abaixo das barras de HP/MP das criaturas, útil para mostrar tempo de cast de magias, buffs/debuffs, etc.

#### 📈 Características Principais
- **Visual integrado**: Aparece abaixo das barras HP/MP
- **Controle total**: Direção, duração, cancelamento automático
- **Bloqueio de magias**: Impede casts durante progress bar ativa
- **Cancelamento inteligente**: Opcional ao andar

#### 📋 API Lua (Servidor)
```lua
-- Progress bar básica (3 segundos, esquerda-direita, cancela ao andar)
creature:sendProgressBar(3000, true, true)

-- Progress bar sem cancelamento ao andar
creature:sendProgressBar(5000, false, false)

-- Cancelar manualmente
creature:stopProgressBar()

-- Funções globais
Game.startProgressbar(creature, 3000, true, true)
Game.stopProgressbar(creature)
```

#### 🎮 Exemplos Práticos

**Magia de Canalização:**
```lua
function onCastSpell(creature, variant)
    -- Progress bar bloqueia outras magias
    creature:sendProgressBar(2000, true, true)

    addEvent(function()
        combat:execute(creature, variant)
    end, 2000)

    return true
end
```

**Buff/Debuff Visual:**
```lua
-- Mostra duração do efeito
creature:sendProgressBar(10000, true, false)  -- 10s, não cancela ao andar
```

#### ⚙️ Parâmetros
- `duration`: Milissegundos (ex: 3000 = 3s)
- `ltr`: `true` = esquerda-direita, `false` = direita-esquerda
- `cancelOnWalk`: `true` = cancela ao andar, `false` = continua

#### 📁 Arquivos Relacionados
- **Core:** `src/game.cpp`, `src/creature.cpp`
- **Lua:** `src/luascript.cpp`
- **Cliente:** `src/client/creature.cpp`

---

### 🛡️ Sistema de Shield Bar

**Status:** ✅ Completo | **Arquivo:** Sistema integrado no core

Sistema de proteção adicional que funciona como uma camada de vida extra, absorvendo dano antes da vida principal.

#### 🛡️ Características Principais
- **Absorção total**: Todo dano vai primeiro para o escudo
- **Visual integrado**: Barra cinza dentro da barra de vida
- **Decay automático**: Diminui 3% a cada 500ms
- **Sem stacking**: Não acumula múltiplos escudos
- **Mana Shield compatível**: Não interfere com utamo vita

#### 📋 API Lua (Servidor)
```lua
-- Verificar escudo atual
local current, max = creature:getShieldBar()
local hasShield = creature:hasActiveShield()

-- Aplicar escudo (método seguro - não stacka)
local success = creature:addShieldBar(1000, false)  -- 1000 HP, não stacka

-- Aplicar escudo (admin - força valor)
creature:setShieldBar(500, 1000)  -- 500 atual, 1000 máximo

-- Remover escudo
creature:removeShieldBar(200)  -- Remove 200 do escudo
```

#### 🎮 Exemplos Práticos

**Spell de Escudo:**
```lua
function onCastSpell(creature, variant)
    local success = creature:addShieldBar(500, false)  -- 500 HP escudo
    if success then
        creature:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    else
        creature:sendCancelMessage("Já possui escudo ativo!")
    end
    return true
end
```

**Buff de Proteção:**
```lua
-- Em um globalevent ou creatureevent
creature:addShieldBar(1000, false)  -- Escudo de 1000 HP
```

#### 📊 Mecânica de Decay
- **Intervalo:** 500ms (0.5 segundos)
- **Decaimento:** 3% do valor máximo por ciclo
- **Exemplo:** Escudo de 1000 HP perde 30 HP a cada 500ms

#### 📁 Arquivos Relacionados
- **Core:** `src/creature.cpp`, `src/player.cpp`
- **Lua:** `src/luascript.cpp`
- **Cliente:** Protocolo integrado

---

### 🎯 Sistema de Monster Icons

**Status:** ✅ Completo | **Arquivo:** Sistema integrado

Sistema de ícones visuais que aparecem sobre monstros para indicar tipos especiais, quests, bosses, etc.

#### 🎯 Características Principais
- **Ícones customizáveis** sobre monstros
- **Cores e tipos** diferenciados
- **Informações visuais** rápidas
- **Integração automática** com spawns

#### 📋 API Lua (Servidor)
```lua
-- Definir ícone para monstro
monster:setMonsterIcon(1)  -- Tipo 1 (boss)
monster:setMonsterIcon(2)  -- Tipo 2 (quest)
monster:setMonsterIcon(0)  -- Remover ícone

-- Verificar ícone atual
local iconType = monster:getMonsterIcon()
```

#### 🎨 Tipos de Ícones
- **0**: Nenhum (padrão)
- **1**: Boss/Elite (vermelho)
- **2**: Quest (azul)
- **3**: Evento (verde)
- **4**: Mini-boss (amarelo)

#### 📁 Arquivos Relacionados
- **Imagens:** `data/images/landcore/monstericons/`
- **Core:** `src/monster.cpp`
- **Cliente:** Renderização integrada

---

### ⚡ Sistema de Stun Target

**Status:** ✅ Completo | **Arquivo:** Sistema integrado

Indicador visual que aparece quando uma criatura está atordoada/stunned, mostrando o tempo restante do efeito.

#### ⚡ Características Principais
- **Visual claro** de atordoamento
- **Contagem regressiva** do efeito
- **Integração automática** com conditions
- **Feedback visual** imediato

#### 📋 API Lua (Servidor)
```lua
-- Aplicar stun com indicador visual
creature:addCondition(condition)  -- Sistema detecta automaticamente

-- Verificar se está stunned
local isStunned = creature:isStunned()
```

#### 📁 Arquivos Relacionados
- **Core:** `src/condition.cpp`
- **Cliente:** Renderização especial

---

### 🎨 Sistema de Shader UI

**Status:** ✅ Completo | **Arquivo:** Sistema integrado

Aplicação de efeitos visuais (shaders) na interface do usuário para melhorar a experiência visual.

#### 🎨 Características Principais
- **Efeitos visuais** na UI
- **Performance otimizada**
- **Shaders customizáveis**
- **Integração transparente**

#### 📋 API Lua (Cliente)
```lua
-- Aplicar shader na UI
modules.game_interface.applyUIShader("glow")

-- Remover shader
modules.game_interface.removeUIShader()
```

#### 📁 Arquivos Relacionados
- **Shaders:** `data/shaders/`
- **Cliente:** `modules/game_interface/`

---

### 🏪 Sistema Market Andando

**Status:** ✅ Completo | **Arquivo:** Sistema integrado

Permite acessar o market (loja do jogo) mesmo durante movimento, sem precisar parar.

#### 🏪 Características Principais
- **Acesso durante movimento**
- **Interface fluida**
- **Sem interrupções** na jogabilidade
- **Compatibilidade total**

#### 📋 Como Usar
```lua
-- Abre market automaticamente
player:openMarket()

-- Market fica acessível mesmo andando
```

---

### 🌈 Sistema Monstros Coloridos

**Status:** ✅ Completo | **Arquivo:** Sistema integrado

Sistema que permite monstros terem ataques com cores diferenciadas, criando variedade visual nos combates.

#### 🌈 Características Principais
- **Ataques coloridos** aleatórios
- **Visual diferenciado** por monstro
- **Efeitos dinâmicos**
- **Configurável por monstro**

#### 📋 API Lua (Servidor)
```lua
-- Definir cor do ataque
monster:setAttackColor("red")      -- Ataque vermelho
monster:setAttackColor("blue")     -- Ataque azul
monster:setAttackColor("random")   -- Aleatório

-- Cores disponíveis: red, blue, green, yellow, purple, orange, random
```

---

## 🏗️ Arquitetura Técnica

### 📂 Estrutura de Arquivos

```
Landcore-Client/
├── modules/
│   ├── game_sounds/          # Sistema de Som
│   ├── game_timer/           # Sistema de Timer
│   └── game_interface/       # Integrações gerais
├── data/
│   ├── sounds/               # Arquivos de áudio
│   └── images/landcore/      # Imagens customizadas
└── Sistemas do client landcore/
    ├── README.md
    ├── Sistema de Som - Tutorial Completo.md
    ├── Exemplos de Uso - Sistema de Som.md
    └── Checklist - Sistema de Som.md

Landcore-Server/
├── src/                     # Código C++ modificado
│   ├── creature.cpp         # Shield Bar, Progress Bar
│   ├── monster.cpp          # Monster Icons
│   ├── luascript.cpp        # APIs Lua
│   └── protocolgame.cpp     # Protocolo timer
├── data/
│   ├── talkactions/scripts/ # Comandos
│   └── scripts/             # Scripts customizados
└── sistemas landcore/       # Documentação detalhada
    ├── PROGRESSBAR_SISTEMA.md
    ├── SHIELDBAR_SISTEMA.md
    ├── MONSTER_ICONS_README.md
    ├── STUNTARGET_SISTEMA.md
    ├── SHADER_UI_SISTEMA.md
    ├── ABRIR MARKET ANDANDO.md
    └── Monstros coloridos random atk.md
```

### 🔄 Protocolos de Comunicação

- **Progress Bar**: Opcode integrado
- **Shield Bar**: Protocolo customizado
- **Monster Icons**: Renderização direta
- **Timer**: Workaround via mensagens de texto

### ⚡ Performance

Todos os sistemas foram otimizados para:
- **Baixo overhead** de CPU
- **Renderização eficiente**
- **Uso mínimo de memória**
- **Compatibilidade** com clientes padrão

---

## 🚀 Próximos Sistemas

- [ ] **Sistema de Interface Personalizada**
- [ ] **Sistema de Macros Avancadas**
- [ ] **Sistema de Logs Detalhados**
- [ ] **Sistema de Performance**
- [ ] **Sistema de Achievements Customizados**

---

## 📞 Suporte e Contribuição

Para dúvidas sobre implementação:
1. **Consulte a documentação específica** do sistema desejado
2. **Verifique exemplos práticos** nos arquivos de documentação
3. **Teste com comandos disponíveis** no jogo
4. **Verifique logs do console** para debug

**Documentação mantida pela equipe Landcore** 🏆

---

**Última atualização:** Janeiro 2026
**Versão da documentação:** 2.0
**Sistemas documentados:** 9 sistemas completos