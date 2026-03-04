# Faith Empire Sim (Unity Android)

Unity 2022.3 LTS mobile strategy/simulation prototype with procedural world generation, religion simulation, events, armies/sieges, diplomacy, city building, sects/schisms, and CK-lite rulers.

## Project Layout
- `Assets/Scripts/` core gameplay systems.
- `Assets/Resources/Events/events_pack.json` event database (200 events, 10+ chains).
- `Assets/Scenes/Main.unity` main scene.
- `Packages/manifest.json` package dependencies (URP, Input System, UGUI).
- `ProjectSettings/` Android-oriented project settings.

## Open in Unity Hub
1. Install **Unity 2022.3 LTS** (2022.3.40f1 recommended) with Android Build Support + SDK/NDK + OpenJDK.
2. In Unity Hub, **Add project from disk** and select this folder.
3. Open `Assets/Scenes/Main.unity`.

## Build Android APK (step-by-step)
1. `File > Build Settings...`
2. Platform: **Android** → click **Switch Platform**.
3. Confirm `Assets/Scenes/Main.unity` is in Scenes In Build.
4. `Edit > Project Settings > Player`:
   - Package Name: `com.fantasyfaith.sim`
   - Minimum API Level: **24** or higher
   - Scripting Backend: **IL2CPP**
   - Target Architectures: **ARM64** only
   - Internet Access: **Require = No / None**
   - Orientation: **Landscape Left/Right**
5. `Edit > Project Settings > Input System Package`:
   - Active Input Handling: **Input System Package (New)**
6. URP setup (if prompted after first open):
   - `Assets > Create > Rendering > URP Asset (with Universal Renderer)`
   - Assign URP asset in `Project Settings > Graphics` and `Quality`.
7. Build:
   - `File > Build Settings > Build` and output `.apk`.

## Mobile Controls
- **Tap** city marker: select city.
- **Tap** army marker: select army.
- If army selected, tap city to set target and siege.
- **Drag** on world: pan camera.
- **Pinch**: zoom.
- UI buttons:
  - Speed: Pause / x1 / x2 / x3 / Next Turn
  - City actions: Raise Army, Temple, School, Fort, Cathedral, TradeHub, Holy City
  - Diplomacy: NAP, Trade Pact, Tribute, Holy War

## Start Screen
On launch, a founding modal pauses simulation:
- Choose birthplace (random placement button)
- Toggle initial doctrines (Pacifism, HolyWar, MandatoryWar)
- Start campaign

## Events JSON
- File: `Assets/Resources/Events/events_pack.json`
- Schema per event:
```json
{
  "id": "ev_001",
  "title": "Title",
  "description": "Desc",
  "choices": [
    {"text":"Option A","effects": {"gold": 10, "authority": 2}, "nextEventId":"optional_chain_id"}
  ],
  "conditions": [{"key":"authority","min":0,"max":100}],
  "weight": 1.0,
  "cooldown": 5
}
```

## Add New Events
1. Open `Assets/Resources/Events/events_pack.json`.
2. Append a new event object to `events` array.
3. To create chains, set a choice `nextEventId` to another event's `id`.
4. Keep unique IDs and valid JSON syntax.

## Android UI Clickability Notes
- Runtime bootstrap ensures a Unity `EventSystem` exists.
- Uses `InputSystemUIInputModule` for new Input System UI on Android.
- Event modal pauses simulation (`isPaused=true` and `modalOpen=true`) until a choice is selected.

