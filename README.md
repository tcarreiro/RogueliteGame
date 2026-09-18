# RogueliteGame

RogueliteGame é um protótipo de jogo roguelite em desenvolvimento no Godot 4, com arquitetura voltada para conteúdo modular, progressão por fatores, eventos, equipamentos e runs compostas por registro de dados e sistemas reutilizáveis.

O projeto combina GDScript como base principal do motor e Lua para conteúdo extensível/moddable, com foco em um design onde novos fatores, eventos e efeitos podem ser adicionados por mods sem reescrever a lógica central do jogo.

## Visão geral

O núcleo do projeto é gerenciado por um conjunto de autoloads e managers:

- GameManager: inicializa os registries e o ciclo principal do jogo
- RunManager: gerencia a vida útil de uma run, eventos, fatores e equipamentos
- FactorRegistry: registra e instancia fatores do jogo
- EventRegistry: registra e instancia eventos do jogo
- EquipmentRegistry: cria e carrega equipamentos
- RunEffectRegistry: carrega efeitos de run
- SaveManager: responsável por persistência / salvar e carregar estado
- SceneMap: usado para mapear cenas do projeto

A aplicação inicia em `project.godot`, com o projeto configurado como Godot 4.8 e com plugins de extensão para GDSS e Lua.

## Stack e tecnologia

- Godot 4.8
- GDScript
- Lua
- Godot plugin ecosystem:
  - `gdss`
  - `lua-gdextension`
  - `lua-modder`

## Estrutura do projeto

```text
RogueliteGame/
├── addons/                    # Plugins e extensões do Godot
├── Backend/
│   ├── Managers/
│   │   ├── Game/
│   │   │   └── GameManager.gd
│   │   ├── Runs/
│   │   │   └── RunManager.gd
│   │   └── ...
│   └── ModdableContent/      # Conteúdo modular do jogo
├── mods/
│   └── base/
│       └── manifest.json
├── project.godot             # Configuração principal do projeto
├── .gitignore
├── .gitattributes
├── LICENSE                   # MIT
└── README.md
