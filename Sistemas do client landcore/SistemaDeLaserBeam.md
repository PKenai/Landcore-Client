# Sistema- [x] **New Request: Beam Cancellation**
  - [x] Add `removeBeamsBySource` to C++ Map class
  - [x] Update Client Network handler (action: remove)
  - [x] Update Server Library (removeBeam function)
 Landcore Client.

## 🌟 Visão Geral

O sistema foi reimplementado para **não depender de Shaders**, utilizando renderização geométrica pura em C++ (`drawqueue.cpp`). Isso garante:
- Compatibilidade total (funciona em qualquer placa de vídeo).
- Aparência visual de alta qualidade ("Divine/Arcane Look").
- Performance otimizada.

---

## 🔧 Como Funciona (Técnica)

O efeito visual é composto por 3 elementos principais renderizados em ordem:

### 1. Corpo com Multi-Layer Glow (Suavização)
Em vez de desenhar um único retângulo (que ficaria com bordas duras), desenhamos **5 camadas sobrepostas** para o núcleo e **5 camadas** para a aura.

- **Fórmula de Fade**: Usamos um decaimento quadrático (`alpha *= alpha`) para criar um gradiente de luz natural.
- **Largura Variável**: As camadas externas são mais largas e transparentes; as internas são mais finas e opacas.
- **Resultado**: Um "tubo" de luz com bordas extremamente suaves, parecendo um shader de blur.

### 2. Pontas Arredondadas (True Half-Circles)
As extremidades do beam não são retas. Desenhamos **semicírculos reais** usando geometria de "leque de triângulos" (Triangle Fan).

- **Geometria**: 16 segmentos triangulares por ponta para curvatura perfeita.
- **Orientação**: Os semicírculos giram acompanhando a direção do beam (funcionam em qualquer ângulo).
- **Sem Gaps**: As pontas são posicionadas exatamente onde o corpo termina (`bodyStart` e `bodyEnd`), garantindo conexão perfeita.

### 3. Partículas de Energia (Energy Leak)
Pequenas partículas douradas são geradas e "vazam" do feixe principal.

- **Comportamento**: Movem-se lentamente ao longo do beam e oscilam lateralmente (onda senoidal).
- **Visual**: Círculos minúsculos (1.5px) que desaparecem com o tempo (fade out).
- **Controle**: Máximo de 20 partículas ativas para não poluir a tela.

---

## 🎨 Como Aplicar / Usar NO CÓDIGO

O sistema já está integrado na classe `Beam` e `DrawQueue`.

### Parâmetros Principais (`beam.h` / `beam.cpp`)
Você pode ajustar o visual alterando estas constantes ou variáveis:

| Parâmetro | Onde | Descrição |
| :--- | :--- | :--- |
| `m_color` | `Beam::setColor` | Cor principal da aura (o núcleo é sempre branco). |
| `m_time` | `Beam::update` | Controla a animação da onda e pulsação. |
| `thickness` | `DrawQueue::addBeam` | Espessura total do feixe. |

### Ajuste Fino de Renderização (`drawqueue.cpp`)

Se quiser alterar o visual do efeito, procure por `DrawQueueItemBeam::draw`:

1. **Ajuste de Cores/Intensidade**:
   ```cpp
   // Exemplo: Aumentar brilho da aura
   intensity = 0.7f + wave * 0.3f; // Base 0.7 + oscilação
   ```

2. **Ajuste das Pontas**:
   ```cpp
   // Exemplo: Pontas mais/menos arredondadas
   float capSize = m_thickness * 0.5f - 5.0f; // Ajuste de overlap
   ```

3. **Partículas**:
   A cor agora é customizável via Lua (`setParticleColor`), mas o padrão é dourado (`255, 230, 153`) definido no construtor de `Beam`.

---

## 📜 Uso em Lua (Spells/Scripts)

Você pode controlar totalmente a aparência do beam através de scripts Lua (ex: `spells.lua` ou scripts de creature).

### Exemplo de Script

```lua
local beam = Beam.create()
beam:setDuration(1000)
beam:setThickness(12)

-- Configurar cor do NEON (Aura)
-- Ex: Ciano Vibrante
beam:setColor({r=0, g=255, b=255, a=255}) 

-- Configurar cor das PARTÍCULAS
-- Ex: Roxo Brilhante
beam:setParticleColor({r=255, g=0, b=255, a=255})

-- Definir Origem e Alvo
beam:setSourceCreature(player)
beam:setTargetCreature(target)

-- Adicionar ao mapa
g_map.addBeam(beam)
```

### Funções Disponíveis
| Função | Descrição |
| :--- | :--- |
| `setColor(color)` | Define a cor do brilho externo (aura). O núcleo é sempre branco. |
| `setParticleColor(color)` | Define a cor das partículas que saem do beam. |
| `setThickness(int)` | Define a espessura. Padrão: 10. |
| `setDuration(ms)` | Define tempo de duração em milissegundos. |

---

## 🚀 Resumo da Implementação

1. **`DrawQueueItemBeam`**: Classe responsável por desenhar.
2. **`addBeam`**: Função chamada pelo `MapView` para adicionar o beam à fila de desenho.
3. **`drawHalfCircle`**: Função auxiliar (lambda interna) que desenha as pontas perfeitas.

| `setDuration(ms)` | Define tempo de duração em milissegundos. |

---

## 🌍 Visibilidade para Todos (Multiplayer - Método Correto)

O sistema agora utiliza **Extended Opcodes** para garantir que todos vejam o efeito de forma limpa e otimizada.

### No Servidor (Lua)
Use a função global `sendBeam` (já incluída na lib `beam_lib.lua`):

```lua
-- Exemplo em uma Spell ou Action:
-- sendBeam(fromPos, toPos, duration, thickness, color, particleColor)

local from = player:getPosition()
local to = target:getPosition()

-- Beam Ciano com Partículas Roxas
sendBeam(from, to, 1000, 12, {r=0, g=255, b=255, a=255}, {r=255, g=0, b=255, a=255})
```

A função `sendBeam` envia automaticamente o pacote apenas para os jogadores que estão vendo a tela, economizando banda.

### No Client
Não é necessário mais configurar nada. O módulo `game_beam` recebe o pacote e desenha automaticamente.

---
