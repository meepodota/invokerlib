# InvokerLib

[![Version](https://img.shields.io/badge/version-1.1%20beta-111111?style=flat-square&labelColor=000000&color=ffffff)](#)
[![Theme](https://img.shields.io/badge/theme-absolute%20monochrome-111111?style=flat-square&labelColor=000000&color=a1a1aa)](#)
[![Env](https://img.shields.io/badge/env-executor%20%C2%B7%20CoreGui-111111?style=flat-square&labelColor=000000&color=ffffff)](#)
[![Lang](https://img.shields.io/badge/lang-luau%20%C2%B7%20lua5.1-111111?style=flat-square&labelColor=000000&color=a1a1aa)](#)

Премиальная UI-библиотека для Roblox **executor-среды** (CoreGui). Абсолютный монохром, бруталистский острый корпус, векторные глифы без зависимости от шрифтов, инверсия вместо цвета и сдержанная, но живая анимация. Один файл — ноль зависимостей — ноль `require`.

> Документация написана под актуальную beta-сборку. Весь интерфейс либы — на английском; проза ниже — на русском.

---

## Содержание

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Design Philosophy](#design-philosophy)
- [Window Anatomy](#window-anatomy)
- [Window & Tabs](#window--tabs)
- [Sections](#sections)
- [Elements](#elements)
- [Notifications & Dialogs](#notifications--dialogs)
- [Persistence & Theming](#persistence--theming)
- [Patterns & Recipes](#patterns--recipes)
- [Compatibility](#compatibility)
- [Full Example](#full-example)

---

## Overview

InvokerLib строит окно поверх `game.CoreGui` и возвращает объект `Window`, через который ты создаёшь табы, секции и элементы управления. Каждый элемент, хранящий значение, регистрируется во внутреннем реестре — это даёт бесплатные `SaveConfig` / `LoadConfig` и метод `:Set(...)` для программного управления.

**Что внутри из коробки:**

| Группа | Компоненты |
|---|---|
| Контейнеры | `Window`, `Tab`, `Section` |
| Ввод | `Toggle`, `Slider`, `Dropdown` (single + multi), `Keybind`, `Textbox`, `ColorPicker` |
| Действия | `Button` (quiet / `Primary`), `Confirm` (модалка) |
| Информация | `Label`, `Paragraph`, `Divider`, `ProgressBar`, `Notify` |
| Система | `SaveConfig`, `LoadConfig`, `SetTheme`, hotkey toggle, tooltip, badge |

---

## Installation

Одна строка. `loadstring` компилирует сырьё с GitHub и возвращает таблицу-библиотеку.

```lua
local InvokerLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/meepodota/invokerlib/refs/heads/main/beta/v1/mainlibbeta.lua"))()
```

> **Note:** GitHub raw кэширует ответы ~5 минут. Если после пуша правок старая версия не подхватывается — добавь любой query-параметр (`..mainlibbeta.lua?t=123`) или подожди.

Если `loadstring` молча возвращает `nil` (старый/мобильный executor без полного парсера), используй диагностический загрузчик — он вытащит реальную ошибку компиляции наружу вместо глухого `attempt to call a nil value`:

```lua
local URL = "https://raw.githubusercontent.com/meepodota/invokerlib/refs/heads/main/beta/v1/mainlibbeta.lua"
local src = game:HttpGet(URL)
local chunk, err = loadstring(src)
if type(chunk) ~= "function" then error("[InvokerLib] compile error:\n" .. tostring(err)) end
local ok, InvokerLib = pcall(chunk)
if not ok or type(InvokerLib) ~= "table" then error("[InvokerLib] runtime error:\n" .. tostring(InvokerLib)) end
```

---

## Quick Start

Минимальный рабочий скрипт — окно, таб, секция, toggle и уведомление:

```lua
local InvokerLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/meepodota/invokerlib/refs/heads/main/beta/v1/mainlibbeta.lua"))()

local Window = InvokerLib:CreateWindow({
    Title = "MyHub",
    Subtitle = "v1.0 · private",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab({ Name = "Main" })
local General = Main:CreateSection("General")

General:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Callback = function(state)
        Window:Notify({
            Title = "Feature",
            Content = state and "Enabled" or "Disabled",
            Type = state and "Success" or "Info",
        })
    end,
})
```

Запусти — окно появится по центру с пружинной анимацией. `RightShift` скрывает/показывает его.

---

## Design Philosophy

Понимание визуального языка помогает предсказуемо кастомизировать либу через `SetTheme`.

- **Абсолютный монохром.** Ни одного цветного пикселя, кроме превью в `ColorPicker` (там цвет функционален). Вся иерархия построена на оттенках серого `#121212 → #1E1E1E → #2A2A2E` и контрасте белого `#FFFFFF`.
- **Инверсия вместо акцента.** Активное состояние = максимальный контраст: белый трек с чёрным ползунком (toggle ON), белый фон с чёрным текстом (`Primary`-кнопка, `Confirm`, hover на close). Это сильнейший возможный сигнал без единого hue.
- **Острый корпус.** Главный `MainFrame` не скруглён — это намеренный брутализм. Глубину дают 1px hairline-рамка и верхняя световая кромка (`InsetHighlight`), а не `UICorner`.
- **Векторные глифы.** Стрелки, галочки, кресты и минус нарисованы повёрнутыми `Frame`-линиями (`MakeIcon`), а не юникод-символами — поэтому **никогда** не превращаются в пустые квадратики (tofu) на платформах без нужных глифов в шрифте.
- **Hairline как «пульс».** Тонкая граница каждого элемента светлеет при наведении, а слева вырастает 2px белая полоска (`HoverBar`) — тактильный отклик без цвета.
- **Типографика-иерархия.** `GothamBlack` (лого) / `GothamBold` UPPERCASE (заголовки секций) / `Gotham` (тело) / моноширинный `Code` (все числовые значения, индексы, подстрочник). Сильный разрыв размеров и начертаний вместо плоской статики.
- **Живой фон.** Два бледных амбиентных пятна медленно пульсируют, четырёхсторонняя виньетка добавляет объём, при открытии проходит boot-scan-линия, у лого и карточки игрока — статус-точки с расходящимся ping-пульсом.

---

## Window Anatomy

```
┌──────────────────────────────────────────────────────────────┐  ← hairline border (no corner)
│  INVOKERLIB            ●  │  Home  /  Overview            –  ×  │  ← inset highlight (top)
│  v1.1 · Beta Release      │ ─────────────────────────────────── │
│  ─────────────────────    │                                     │
│  // NAVIGATION            │   ■  GENERAL                    01  │  ← section header + index
│  ┌ Main              │    │   ┌ Enable Feature          [●──] │  ← toggle (inverted when ON)
│  │ Visuals            │    │   ┌ FOV Radius          120 px    │  ← slider (mono dot)
│  │ Misc               │    │   ┌ Target Part        Head   ⌄   │  ← dropdown (vector chevron)
│  └ Settings           │    │   ┌ Aim Key              [ Q ]    │  ← keybind (mono glyph)
│                         │    │                                     │
│  ┌──────────────────┐  │    │   ┌ Save Config  (Primary = white)  │
│  │ ◉  Signed in as  │  │    │                                     │
│  │    PlayerName    │  │    │                                     │
│  └──────────────────┘  │    │                                     │
└──────────────────────────────────────────────────────────────┘
        sidebar 192px              content (ambient haze + vignette)
```

---

## Window & Tabs

### `InvokerLib:CreateWindow(config)`

Создаёт `ScreenGui` в `CoreGui` и возвращает объект `Window`. Повторный вызов уничтожает предыдущее окно `InvokerLib`.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Title` | string | `"InvokerLib"` | Крупный заголовок в сайдбаре (`GothamBlack`). |
| `Subtitle` | string | `"v1.1 · Beta Release"` | Мелкая моноширинная строка под заголовком. |
| `Size` | UDim2 | `780 × 520` | Размер развёрнутого окна. |
| `ToggleKey` | Enum.KeyCode | `RightShift` | Хоткей скрытия/показа окна. |

> Поля `Icon` из старых версий игнорируются — иконка у лого и у табов удалена намеренно.

**Возвращает:** `Window`.

### `Window:CreateTab(config)`

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Tab"` | Текст таба в сайдбаре. |

Первый созданный таб выбирается автоматически. Смена таба — fade-then-slide без нахлёста страниц.

**Возвращает:** `Tab`.

### `Tab:SetBadge(visible, color)`

Маленькая точка-индикатор справа от текста таба (например, «есть обновления» / «ошибка»).

```lua
SettingsTab:SetBadge(true)                       -- белый по умолчанию
SettingsTab:SetBadge(true, Color3.fromRGB(255,255,255))
SettingsTab:SetBadge(false)                      -- скрыть
```

---

## Sections

### `Tab:CreateSection(name)`

Группирует элементы в карточку с uppercase-заголовком, квадратным маркером слева и моноширинным индексом (`01`, `02`…) справа. Секции проявляются по очереди (staggered reveal).

**Возвращает:** `Section` — объект, на котором вызываются все `Create*`-методы элементов.

---

## Elements

Все элементы принимают `config`-таблицу. Поле `Description` (где указано) включает tooltip при наведении. Элементы, хранящие значение, возвращают объект с методом `:Set(...)` и регистрируются для `SaveConfig`/`LoadConfig` по ключу `Name`.

> **Важно:** `Name` должен быть уникален в пределах окна — это ключ в реестре конфигов.

### `Section:CreateToggle(config)`

Инвертируемый переключатель: OFF = тёмный трек + серый круг, ON = **белый трек + чёрный круг**.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Toggle"` | Метка + ключ конфига. |
| `Default` | bool | `false` | Начальное состояние. |
| `Callback` | function(bool) | noop | Вызывается при переключении. |
| `Description` | string | — | Tooltip. |

**Возвращает:** `Toggle` → `:Set(value: boolean)`.

```lua
local t = General:CreateToggle({
    Name = "Auto Farm",
    Default = true,
    Description = "Automatically collects resources",
    Callback = function(on) print("farm:", on) end,
})
t:Set(false) -- программно выключить
```

### `Section:CreateButton(config)`

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Button"` | Текст кнопки. |
| `Callback` | function | noop | Действие по клику. |
| `Primary` | bool | `false` | `true` = инвертированная (белый фон / чёрный текст) — для главных действий. |
| `Description` | string | — | Tooltip. |

Тихая кнопка (`Primary = false`) при наведении получает бегущий диагональный блик (shine-sweep).

```lua
General:CreateButton({
    Name = "Rejoin Server",
    Callback = function() game.TeleportService:Teleport(game.PlaceId) end,
})
```

### `Section:CreateSlider(config)`

Моноширинное значение справа, белый ползунок с тёмным inset-кольцом, пульс размера при захвате.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Slider"` | Метка + ключ конфига. |
| `Min` | number | `0` | Нижняя граница. |
| `Max` | number | `100` | Верхняя граница. |
| `Step` | number | `1` | Шаг округления. |
| `Suffix` | string | `""` | Суффикс значения (`" px"`, `" s"`, `"°"`). |
| `Default` | number | `Min` | Начальное значение. |
| `Callback` | function(number) | noop | Вызывается при изменении. |
| `Description` | string | — | Tooltip. |

**Возвращает:** `Slider` → `:Set(value: number)`.

```lua
Visuals:CreateSlider({
    Name = "FOV Changer", Min = 70, Max = 120, Step = 1,
    Suffix = "°", Default = 90,
    Callback = function(v) workspace.Camera.FieldOfView = v end,
})
```

### `Section:CreateDropdown(config)`

Поддерживает одиночный и множественный выбор. Стрелка — векторный шеврон, вращается на 180° при раскрытии. Список опций скроллится (ограничение высоты).

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Dropdown"` | Метка + ключ конфига. |
| `Options` | {string} | 3 дефолтных | Список вариантов. |
| `MultiSelect` | bool | `false` | Множественный выбор с чекбоксами. |
| `Default` | string | `Options[1]` | Начальный выбор (single). |
| `Callback` | function | noop | Single → `string`; multi → `{string}`. |
| `Description` | string | — | Tooltip. |

**Возвращает:** `Dropdown` → `:Set(value)`, поля `.Value` (single) / `.Values` (multi).

```lua
-- single
Combat:CreateDropdown({
    Name = "Target Part",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Callback = function(part) print("aim:", part) end,
})

-- multi
Combat:CreateDropdown({
    Name = "ESP Layers",
    Options = { "Box", "Name", "Health", "Tracer", "Chams" },
    MultiSelect = true,
    Callback = function(list) print("layers:", #list) end,
})
```

### `Section:CreateKeybind(config)`

Моноширинная клавиша; при прослушивании рамка мигает белым. Нажатие сохранённой клавиши (вне фокуса ввода) вызывает `Callback`.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Keybind"` | Метка. |
| `Default` | Enum.KeyCode | `Enum.KeyCode.E` | Стартовая клавиша. |
| `Callback` | function | noop | Срабатывает по нажатию бинда. |
| `Description` | string | — | Tooltip. |

**Возвращает:** `Keybind` → `:Set(key: Enum.KeyCode)`.

### `Section:CreateTextbox(config)`

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Textbox"` | Метка + ключ конфига. |
| `Placeholder` | string | `"Type something..."` | Текст-заглушка. |
| `Callback` | function(text, enterPressed) | noop | `enterPressed` = true при вводе через Enter. |
| `Description` | string | — | Tooltip. |

**Возвращает:** `Textbox` → `:Set(value: string)`. Рамка поля светлеет до белого при фокусе.

### `Section:CreateColorPicker(config)`

Единственная хроматическая поверхность либы — превью текущего цвета. Три канала R/G/B (ползунки 0–255) + квадрат превью.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"ColorPicker"` | Метка. |
| `Default` | Color3 | серый `#A1A1AA` | Начальный цвет. |
| `Callback` | function(Color3) | noop | Вызывается при изменении любого канала. |

**Возвращает:** `ColorPicker` → `:Set(color: Color3)`.

### `Section:CreateLabel(text)`

Однострочный приглушённый текст. **Возвращает:** `Label` → `:Set(newText)`.

### `Section:CreateParagraph(config)`

Блок с заголовком и переносимым телом на тёмной подложке.

| Поле | Тип | Дефолт |
|---|---|---|
| `Title` | string | `"Title"` |
| `Content` | string | `"Content"` |

**Возвращает:** `Paragraph` → `:Set({ Title, Content })`.

### `Section:CreateDivider(label?)`

Тонкая горизонтальная линия. Если передан `label` — текст по центру между двумя линиями (uppercase, моноширинный).

```lua
General:CreateDivider()            -- просто линия
General:CreateDivider("danger")    -- линия  DANGER  линия
```

### `Section:CreateProgressBar(config)`

Неинтерактивный индикатор заполнения.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Name` | string | `"Progress"` | Метка. |
| `Max` | number | `100` | Верхняя граница. |
| `Value` | number | `0` | Текущее значение. |
| `Suffix` | string | `""` | Суффикс (`"%"`, `" fps"`). |

**Возвращает:** `ProgressBar` → `:Set(value: number)` (плавный tween заполнения).

```lua
local fps = Stats:CreateProgressBar({ Name = "FPS", Max = 240, Value = 0, Suffix = " fps" })
RunService.Heartbeat:Connect(function() fps:Set(math.floor(1 / RunService.RenderStepped:Wait())) end)
```

---

## Notifications & Dialogs

### `Window:Notify(config)`

Минималистичный тост справа вверху: hairline-рамка, векторный глиф-маркер слева, таймер-линия сверху (сжимается за `Duration`), кнопка закрытия появляется при наведении. Стек через вертикальный layout.

| Поле | Тип | Дефолт | Описание |
|---|---|---|---|
| `Title` | string | `"Notification"` | Заголовок. |
| `Content` | string | `""` | Тело. |
| `Duration` | number | `3.5` | Секунды до автозакрытия. |
| `Type` | string | `"Info"` | `Info` / `Success` / `Warning` / `Error`. |

`Error` рендерится инвертированным (белый маркер с тёмным крестом) — единственный «тревожный» сигнал в монохроме.

```lua
Window:Notify({ Title = "Saved",  Content = "Config written to disk", Type = "Success" })
Window:Notify({ Title = "Denied", Content = "Anti-cheet blocked request", Type = "Error", Duration = 5 })
```

### `Window:Confirm(config)`

Модальная карточка поверх окна с полупрозрачным оверлеем. Кнопка `Confirm` — инвертированная (Primary), `Cancel` — тихая. Появление пружинное.

| Поле | Тип | Дефолт |
|---|---|---|
| `Title` | string | `"Confirm"` |
| `Message` | string | `"Are you sure?"` |
| `OnConfirm` | function | noop |
| `OnCancel` | function | noop |

```lua
Window:Confirm({
    Title = "Unload",
    Message = "This will destroy the interface. Continue?",
    OnConfirm = function() game.CoreGui:FindFirstChild("InvokerLib"):Destroy() end,
})
```

---

## Persistence & Theming

### `Window:SaveConfig(name)` / `Window:LoadConfig(name)`

Сериализует значения всех зарегистрированных элементов (toggle/slider/dropdown/textbox/colorpicker) в JSON и пишет в `invoker_<name>.cfg` через `writefile`. `LoadConfig` читает `readfile` и применяет значения через внутренние `:Set`.

```lua
General:CreateButton({ Name = "Save",  Callback = function() Window:SaveConfig("main")  end })
General:CreateButton({ Name = "Load",  Callback = function() Window:LoadConfig("main")  end })
```

> `LoadConfig` молча выходит, если файла нет (`isfile`-проверка). `ColorPicker` и multi-dropdown сохраняются как Color3 / таблица соответственно.

### `InvokerLib:SetTheme(table)`

Меняет цвета **на лету** для всех уже созданных инстансов, отслеживаемых через внутренний реестр `_ThemeRefs`. Передай только нужные ключи.

**Полная таблица ключей (монохром по умолчанию):**

| Ключ | Hex | Назначение |
|---|---|---|
| `Background` | `#121212` | Корпус окна + сайдбар |
| `Sidebar` | `#121212` | Фон сайдбара |
| `Panel` | `#161616` | Контентная область |
| `Element` | `#1E1E1E` | Карточки секций / player-card |
| `ElementHover` | `#262626` | — |
| `Surface` | `#1A1A1A` | Строки элементов (toggle/slider/…) |
| `Accent` | `#FFFFFF` | Главный акцент / инверсия |
| `AccentDim` | `#A1A1AA` | Приглушённый акцент (значения, плейсхолдеры) |
| `Invert` | `#121212` | Текст на белом (Primary/Confirm) |
| `Text` | `#F5F5F5` | Основной текст |
| `TextDark` | `#82828A` | Вторичный текст |
| `TextMuted` | `#525258` | Метки, индексы, подстрочник |
| `Hairline` | `#2A2A2E` | Границы в покое |
| `HairlineHi` | `#4A4A50` | Границы при hover |
| `Divider` | `#26262A` | Линии разделителей |
| `Border` | `#2A2A2E` | — |

```lua
-- пример: чуть теплее серого, не ломая монохром
InvokerLib:SetTheme({
    Accent    = Color3.fromRGB(245, 245, 245),
    AccentDim = Color3.fromRGB(150, 150, 150),
    Panel     = Color3.fromRGB(20, 20, 20),
})
```

> `Success` / `Warning` / `Error` в монохроме тоже серые/белые — либа не вводит цвет через тему уведомлений; «тревога» передаётся инверсией.

---

## Patterns & Recipes

### Деструктивное действие: Primary + Confirm

Главное действие делаешь инвертированным, но защищаешь модалкой — классический паттерн «яркая кнопка → подтверждение».

```lua
Danger:CreateButton({
    Name = "Reset All Settings",
    Primary = true,
    Callback = function()
        Window:Confirm({
            Title = "Reset",
            Message = "Every value returns to default. This cannot be undone.",
            OnConfirm = function()
                Window:LoadConfig("factory") -- или ручные :Set
                Window:Notify({ Title = "Reset", Content = "Defaults restored", Type = "Warning" })
            end,
        })
    end,
})
```

### Автосохранение при выходе

```lua
game:BindToClose(function() Window:SaveConfig("autosave") end)
task.spawn(function() Window:LoadConfig("autosave") end)
```

### Обработка MultiSelect

`Callback` multi-дропдауна получает таблицу — проверяй вхождение через `table.find`:

```lua
local layers = {}
Visuals:CreateDropdown({
    Name = "ESP Layers", MultiSelect = true,
    Options = { "Box", "Name", "Health" },
    Callback = function(list) layers = list end,
})
-- где-то в рендере:
if table.find(layers, "Box") then drawBox(plr) end
```

### Живой ProgressBar

Не дёргай `:Set` каждый кадр без нужды — округляй и сравнивай, чтобы не плодить твины:

```lua
local last = -1
RunService.Heartbeat:Connect(function()
    local v = math.floor(1 / RunService.RenderStepped:Wait())
    if v ~= last then last = v; fpsBar:Set(v) end
end)
```

### Скрыть окно по хоткею

Дефолт — `RightShift`. Меняется через `ToggleKey` в `CreateWindow`. Видимость также доступна напрямую: `MainFrame.Visible` (но проще хоткей).

---

## Compatibility

| Требование | Деталь |
|---|---|
| Среда | Executor с доступом к `game.CoreGui` (Synapse, Wave, Fluxus, Solara, Delta и др.) |
| Парсер | Чистый Lua 5.1 / Luau — **без** type-аннотаций и без `+=`, компилируется везде |
| Файлы | `writefile` / `readfile` / `isfile` нужны только для `SaveConfig`/`LoadConfig` |
| Сеть | `game:HttpGet` только для `loadstring`-установки |
| Запрещено | Нет `require`, `ModuleScript`, `RemoteEvent`, внешних asset'ов для иконок |

Если executor режет `CoreGui` — либа не запустится (это принципиально: UI рисуется поверх игры). Все фоновые циклы (амбиент-дымки, ping-точки) обрываются по проверке `Parent` после уничтожения окна — утечек нет.

---

## Full Example

Полный скрипт, демонстрирующий **каждый** компонент и паттерн. UI-тексты на английском (как и сама либа).

```lua
local InvokerLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/meepodota/invokerlib/refs/heads/main/beta/v1/mainlibbeta.lua"))()

local Window = InvokerLib:CreateWindow({
    Title = "InvokerHub",
    Subtitle = "v1.1 · Beta Release",
    Size = UDim2.new(0, 800, 0, 540),
    ToggleKey = Enum.KeyCode.RightShift,
})

-- ═══════════════════ COMBAT ═══════════════════
local Combat = Window:CreateTab({ Name = "Combat" })

local Aim = Combat:CreateSection("Aimbot")

Aim:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Description = "Master switch for silent aim",
    Callback = function(on)
        Window:Notify({ Title = "Aimbot", Content = on and "Engaged" or "Disengaged", Type = on and "Success" or "Info" })
    end,
})

Aim:CreateSlider({
    Name = "FOV Radius", Min = 10, Max = 500, Step = 5, Suffix = " px", Default = 120,
    Callback = function() end,
})

Aim:CreateSlider({
    Name = "Smoothing", Min = 1, Max = 20, Step = 1, Suffix = " ms", Default = 6,
    Callback = function() end,
})

Aim:CreateDropdown({
    Name = "Target Part",
    Options = { "Head", "Torso", "HumanoidRootPart", "Closest Limb" },
    Default = "Head",
    Callback = function() end,
})

Aim:CreateKeybind({
    Name = "Aim Key", Default = Enum.KeyCode.Q,
    Callback = function() Window:Notify({ Title = "Aimbot", Content = "Key held", Type = "Info", Duration = 1 }) end,
})

local Trigger = Combat:CreateSection("Triggerbot")

Trigger:CreateToggle({ Name = "Enable Triggerbot", Default = false, Callback = function() end })
Trigger:CreateSlider({ Name = "Fire Delay", Min = 0, Max = 500, Step = 10, Suffix = " ms", Default = 80, Callback = function() end })
Trigger:CreateDivider("hitboxes")
Trigger:CreateDropdown({
    Name = "Hitbox Override", MultiSelect = true,
    Options = { "Default", "Expanded", "Sphere", "Box" },
    Callback = function(list) print("hitboxes:", #list) end,
})

-- ═══════════════════ VISUALS ═══════════════════
local Visuals = Window:CreateTab({ Name = "Visuals" })

local ESP = Visuals:CreateSection("ESP")

ESP:CreateToggle({ Name = "Box", Default = true, Description = "2D bounding boxes", Callback = function() end })
ESP:CreateToggle({ Name = "Name Tags", Default = true, Callback = function() end })
ESP:CreateToggle({ Name = "Health Bar", Default = false, Callback = function() end })
ESP:CreateColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(161, 161, 170), Callback = function() end })
ESP:CreateColorPicker({ Name = "Team Color", Default = Color3.fromRGB(245, 245, 245), Callback = function() end })

local World = Visuals:CreateSection("World")

World:CreateToggle({ Name = "Fullbright", Default = false, Callback = function() end })
World:CreateSlider({ Name = "Camera FOV", Min = 70, Max = 120, Step = 1, Suffix = "°", Default = 70, Callback = function() end })
World:CreateProgressBar({ Name = "Render FPS", Max = 240, Value = 144, Suffix = " fps" })
World:CreateDivider()
World:CreateParagraph({
    Title = "Client-side only",
    Content = "All visuals render locally. No server round-trips, no remotes fired.",
})

-- ═══════════════════ MISC ═══════════════════
local Misc = Window:CreateTab({ Name = "Misc" })

local Net = Misc:CreateSection("Network")

Net:CreateTextbox({
    Name = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...",
    Description = "Logging endpoint",
    Callback = function(text, enter)
        if enter then Window:Notify({ Title = "Webhook", Content = "Stored", Type = "Success", Duration = 2 }) end
    end,
})

Net:CreateDropdown({
    Name = "Theme Preset", Options = { "Mono", "Graphite", "Paper", "Slate" }, Default = "Mono",
    Callback = function() Window:Notify({ Title = "Theme", Content = "Preset applied", Type = "Info", Duration = 2 }) end,
})

local Config = Misc:CreateSection("Configuration")

Config:CreateButton({ Name = "Save Config", Callback = function()
    Window:SaveConfig("default")
    Window:Notify({ Title = "Config", Content = "Saved to invoker_default.cfg", Type = "Success" })
end })

Config:CreateButton({ Name = "Load Config", Callback = function()
    Window:LoadConfig("default")
    Window:Notify({ Title = "Config", Content = "Loaded from disk", Type = "Success" })
end })

Config:CreateButton({
    Name = "Factory Reset", Primary = true,
    Callback = function()
        Window:Confirm({
            Title = "Factory Reset",
            Message = "All values return to defaults. This cannot be undone.",
            OnConfirm = function() Window:Notify({ Title = "Reset", Content = "Defaults restored", Type = "Warning" }) end,
        })
    end,
})

local About = Misc:CreateSection("About")
About:CreateLabel("InvokerLib v1.1 beta")
About:CreateLabel("Absolute monochrome build")
About:CreateParagraph({
    Title = "Changelog",
    Content = "• Sharp unrounded shell\n• Vector glyphs (no tofu)\n• Inverted primary actions\n• Ambient haze + vignette\n• Boot scan-line + status pings",
})

-- ═══════════════════ SETTINGS ═══════════════════
local Settings = Window:CreateTab({ Name = "Settings" })
Settings:SetBadge(true)

local UI = Settings:CreateSection("Interface")
UI:CreateToggle({ Name = "Blur Background", Default = true, Callback = function() end })
UI:CreateSlider({ Name = "UI Scale", Min = 80, Max = 120, Step = 5, Suffix = "%", Default = 100, Callback = function() end })
UI:CreateKeybind({ Name = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function() end })
UI:CreateDivider("danger")
UI:CreateButton({
    Name = "Unload Interface", Primary = true,
    Callback = function()
        Window:Confirm({
            Title = "Unload",
            Message = "Destroy the interface and stop the script?",
            OnConfirm = function() game.CoreGui:FindFirstChild("InvokerLib"):Destroy() end,
        })
    end,
})

-- ═══════════════════ BOOT ═══════════════════
task.delay(0.6, function()
    Window:Notify({
        Title = "InvokerHub",
        Content = "Loaded. Press RightShift to toggle.",
        Type = "Success",
        Duration = 4,
    })
end)
```

---

*InvokerLib — crafted, not templated.*
