using UnityEngine;

namespace FaithEmpireSim
{
    public class GameRoot : MonoBehaviour
    {
        private GameState _state;
        private UIController _ui;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Bootstrap()
        {
            if (FindObjectOfType<GameRoot>() != null) return;
            new GameObject("GameRoot").AddComponent<GameRoot>();
        }

        private void Awake()
        {
            Screen.orientation = ScreenOrientation.LandscapeLeft;
            Application.targetFrameRate = 60;

            EnsureMainCamera();
            _state = gameObject.AddComponent<GameState>();

            var world = gameObject.AddComponent<WorldGenerator>();
            var citySystem = gameObject.AddComponent<CitySystem>();
            var religion = gameObject.AddComponent<ReligionSystem>();
            var army = gameObject.AddComponent<ArmySystem>();
            var diplomacy = gameObject.AddComponent<DiplomacySystem>();
            var characters = gameObject.AddComponent<CharacterSystem>();
            var save = gameObject.AddComponent<SaveSystem>();
            var sim = gameObject.AddComponent<SimulationLoop>();
            var eventsJson = gameObject.AddComponent<EventSystemJSON>();
            _ui = gameObject.AddComponent<UIController>();
            var select = gameObject.AddComponent<SelectionController>();

            world.Generate(_state);
            citySystem.Initialize(_state);
            religion.Initialize(_state);
            army.Initialize(_state);
            diplomacy.Initialize(_state);
            characters.GenerateCharacters(_state);

            _ui.Initialize(_state, citySystem, army, diplomacy, sim);
            eventsJson.Initialize(_state, _ui);
            sim.Initialize(_state, citySystem, religion, army, diplomacy, eventsJson);
            select.Initialize(_state, army);

            InvokeRepeating(nameof(UpdateMarkers), 0.25f, 0.25f);

            _state.Log("Game initialized.");
        }

        private void EnsureMainCamera()
        {
            if (Camera.main != null) return;
            var camObj = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            camObj.tag = "MainCamera";
            var cam = camObj.GetComponent<Camera>();
            cam.transform.position = new Vector3(90, 85, -20);
            cam.transform.rotation = Quaternion.Euler(55, 0, 0);
            cam.clearFlags = CameraClearFlags.Skybox;
            cam.farClipPlane = 800f;

            var light = new GameObject("Directional Light", typeof(Light));
            var l = light.GetComponent<Light>();
            l.type = LightType.Directional;
            l.intensity = 1f;
            light.transform.rotation = Quaternion.Euler(50, -40, 0);
        }

        private void Update()
        {
            _ui?.Refresh();
        }

        private void UpdateMarkers()
        {
            foreach (var city in _state.Data.cities)
            {
                var marker = GameObject.Find($"CityMarker_{city.id}");
                if (marker == null) continue;
                var renderer = marker.GetComponent<Renderer>();
                renderer.material.color = Color.Lerp(Color.gray, Color.yellow, city.faithShare);
                if (city.heresyShare > 0.4f) renderer.material.color = Color.Lerp(renderer.material.color, Color.magenta, city.heresyShare);
            }
        }
    }
}
