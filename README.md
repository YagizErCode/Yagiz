# Faith Empire Sim

A 3D strategy/simulation game combining CK-style religion/politics, Civ-style city building, and Plague Inc-style spread mechanics. Built with Godot 4.2+ for Android.

## How to Open in Godot

1. Download and install **Godot 4.2+** (standard or .NET version) from https://godotengine.org/download
2. Open Godot and click **Import**
3. Navigate to this project folder and select `project.godot`
4. Click **Import & Edit**
5. The project will open. Press **F5** (or the Play button) to run

## How to Export Android APK (Step-by-Step)

### Prerequisites
1. Install **Android Studio** and accept SDK licenses
2. In Android Studio, install:
   - Android SDK Platform 33 (or newer)
   - Android SDK Build-Tools
   - Android NDK (if using C++ modules)
3. Install **OpenJDK 17** (Godot 4.2+ requirement)
4. Create a debug keystore (if you don't have one):
   ```bash
   keytool -keyalg RSA -genkeypair -alias androiddebugkey \
     -keypass android -keystore debug.keystore \
     -storepass android -dname "CN=Android Debug,O=Android,C=US" \
     -validity 9999 -deststoretype pkcs12
   ```

### Configure Godot for Android Export
1. In Godot: **Editor > Editor Settings > Export > Android**
2. Set the paths:
   - **Android SDK Path**: e.g., `~/Android/Sdk`
   - **Debug Keystore**: path to your `debug.keystore`
   - **Debug Keystore User**: `androiddebugkey`
   - **Debug Keystore Password**: `android`
3. Download the **Android export templates**: **Editor > Manage Export Templates > Download**

### Export the APK
1. Go to **Project > Export**
2. The "Android" preset should already be configured (see `export_presets.cfg`)
3. Verify settings:
   - Package name: `com.fantasyfaith.sim`
   - Min SDK: 24
   - Architecture: arm64-v8a
   - Screen orientation: Landscape
4. Click **Export Project** and choose a filename (e.g., `FaithEmpireSim.apk`)
5. If prompted about debug/release, choose **Debug** for testing
6. Transfer the APK to your Android device and install

### Running on Samsung S24+
- The game uses Forward Mobile renderer with vertex-colored terrain
- No heavy shaders or post-processing — runs smoothly at 60fps
- Touch controls: tap to select, drag to pan, pinch to zoom

## Mobile Controls

| Action | Gesture |
|--------|---------|
| Pan camera | Drag with one finger |
| Zoom | Pinch with two fingers |
| Select city/army | Tap |
| Deselect | Tap empty terrain |
| UI buttons | Tap directly on button |

## Game Overview

### Starting the Game
1. **Start Menu**: Configure your religion
   - Set religion name
   - Adjust belief axes (tolerance, militarism, knowledge, etc.)
   - Toggle doctrines (pacifism, holy war, inquisitions, etc.)
   - Choose birthplace region
   - Set world seed
2. Click **BEGIN YOUR FAITH** to start

### Core Gameplay
- **Faith Spread**: Your religion spreads city-to-city via trade routes
- **City Building**: Build temples, schools, forts, cathedrals, and trade hubs in dominated cities
- **Armies**: Raise armies from dominated cities, move them, and siege enemy cities
- **Diplomacy**: Form pacts (NAP, Trade, Tribute) or declare Holy Wars
- **Events**: Random events pause the game and require player choice (200+ events, 10+ chains)
- **Sects/Heresy**: Low authority may cause schisms, creating competing sects

### UI Layout
- **Left panel**: Global stats (gold, authority, legitimacy, spread rate, turn)
- **Top buttons**: Diplomacy, Sects, Chronicle
- **Right panel**: City or Army details (appears on selection)
- **Bottom center**: Speed controls (Pause, x1, x2, x3, Next Turn)
- **Event modal**: Full-screen popup for events (game pauses)

## Events JSON

Events are stored in `Resources/Events/events_pack.json`.

### Regenerating Events
```bash
python3 Tools/generate_events.py
```
This produces 220 deterministic events (seeded) including 10+ event chains.

### Adding New Events
Add entries to the JSON with this schema:
```json
{
  "id": "unique_id",
  "title": "Event Title",
  "description": "What happened...",
  "choices": [
    {
      "text": "Choice text",
      "effects": {"authority": 10, "gold": -50},
      "next_event_id": "optional_chain_id"
    }
  ],
  "conditions": {"min_turn": 5, "min_faith_spread": 10},
  "weight": 10,
  "cooldown": 5
}
```

### Available Effects
- `authority`, `legitimacy`, `gold`, `spread_rate` — modify player religion stats
- `tolerance`, `militarism`, `knowledge`, `ritual`, `commerce`, `austerity`, `charity` — modify doctrine axes
- `stability_all`, `heresy_all`, `education_all`, `security_all` — modify all cities

### Conditions
- `min_turn` — minimum game turn
- `min_faith_spread` — minimum spread percentage
- `min_authority`, `max_authority` — authority range
- `min_gold` — minimum gold
- `has_doctrine` — requires specific doctrine enabled

## Project Structure

```
├── project.godot              # Godot project config
├── export_presets.cfg         # Android export preset
├── icon.svg                   # App icon
├── README.md                  # This file
├── Scenes/
│   ├── Main.tscn              # Main game scene
│   └── StartMenu.tscn         # Religion creation menu
├── Scripts/
│   ├── GameState.gd           # Autoloaded global state (data models)
│   ├── GameRoot.gd            # Main scene bootstrap
│   ├── WorldGenerator.gd      # Procedural map, cities, kingdoms
│   ├── CameraController.gd    # Touch camera (pan/zoom)
│   ├── SelectionController.gd # Tap-to-select raycasting
│   ├── ReligionSystem.gd      # Faith spread, heresy, sects
│   ├── CitySystem.gd          # Buildings, economy, population
│   ├── ArmySystem.gd          # Army movement and sieges
│   ├── DiplomacySystem.gd     # Pacts and wars between kingdoms
│   ├── CharacterSystem.gd     # Rulers, dynasties, traits
│   ├── EventSystem.gd         # JSON event loading and processing
│   ├── SimulationLoop.gd      # Main tick/turn loop
│   ├── UIController.gd        # UI panel management
│   ├── SaveSystem.gd          # JSON save/load
│   └── StartMenu.gd           # Start screen logic
├── Resources/
│   └── Events/
│       └── events_pack.json   # 220 events with 10+ chains
└── Tools/
    ├── generate_events.py     # Python event generator
    └── generate_events.gd     # GDScript stub (use Python)
```

## Technical Notes

- **Rendering**: Forward Mobile, vertex colors on terrain mesh, no textures
- **Terrain**: 200x150 grid with noise-based heightmap, step=2 for performance
- **Cities**: 150-250 placed via Poisson sampling on suitable biomes
- **Trade network**: 2-5 nearest neighbors per city
- **Simulation**: Tick-based (2s interval at x1), affected by speed multiplier
- **Events**: Pause simulation via `is_event_modal_open` flag
- **Deterministic**: World and events use seeded RNG (visible in UI)
- **No paid assets**: All geometry uses primitive meshes (cylinders, cones, boxes)
