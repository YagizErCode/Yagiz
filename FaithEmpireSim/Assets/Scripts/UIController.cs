using System;
using System.Text;
using UnityEngine;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;
using EventSystem = UnityEngine.EventSystems.EventSystem;

namespace FaithEmpireSim
{
    public class UIController : MonoBehaviour
    {
        private GameState _state;
        private CitySystem _citySystem;
        private ArmySystem _armySystem;
        private DiplomacySystem _diplomacySystem;
        private SimulationLoop _simulation;

        private Text _globalText;
        private Text _cityText;
        private Text _armyText;
        private Text _logText;
        private Text _sectText;
        private GameObject _eventModal;
        private Text _eventTitle;
        private Text _eventDesc;
        private VerticalLayoutGroup _eventChoiceList;
        private GameObject _startModal;

        public void Initialize(GameState state, CitySystem citySystem, ArmySystem armySystem, DiplomacySystem diplomacySystem, SimulationLoop simulation)
        {
            _state = state;
            _citySystem = citySystem;
            _armySystem = armySystem;
            _diplomacySystem = diplomacySystem;
            _simulation = simulation;
            EnsureEventSystem();
            BuildUI();
            ShowStartModal();
        }

        private void EnsureEventSystem()
        {
            if (FindObjectOfType<EventSystem>() != null) return;
            var es = new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
            DontDestroyOnLoad(es);
        }

        private Font GetFont() => Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        private void BuildUI()
        {
            var canvasGO = new GameObject("UICanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasGO.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasGO.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);

            _globalText = CreatePanelText(canvasGO.transform, "GlobalPanel", new Vector2(300, 1030), new Vector2(10, -10), TextAnchor.UpperLeft);
            _cityText = CreatePanelText(canvasGO.transform, "CityPanel", new Vector2(360, 520), new Vector2(10, -370), TextAnchor.UpperLeft);
            _armyText = CreatePanelText(canvasGO.transform, "ArmyPanel", new Vector2(360, 300), new Vector2(10, -900), TextAnchor.UpperLeft);
            _sectText = CreatePanelText(canvasGO.transform, "SectPanel", new Vector2(300, 220), new Vector2(1620, -10), TextAnchor.UpperLeft);
            _logText = CreatePanelText(canvasGO.transform, "LogPanel", new Vector2(1240, 220), new Vector2(340, -850), TextAnchor.UpperLeft);

            CreateSpeedControls(canvasGO.transform);
            CreateCityButtons(canvasGO.transform);
            CreateDiplomacyPanel(canvasGO.transform);
            CreateEventModal(canvasGO.transform);
        }

        private Text CreatePanelText(Transform parent, string name, Vector2 size, Vector2 anchoredPos, TextAnchor anchor)
        {
            var panel = new GameObject(name, typeof(Image));
            panel.transform.SetParent(parent, false);
            var rect = panel.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0, 1);
            rect.anchorMax = new Vector2(0, 1);
            rect.pivot = new Vector2(0, 1);
            rect.sizeDelta = size;
            rect.anchoredPosition = anchoredPos;
            panel.GetComponent<Image>().color = new Color(0f, 0f, 0f, 0.4f);

            var txtGO = new GameObject("Text", typeof(Text));
            txtGO.transform.SetParent(panel.transform, false);
            var txt = txtGO.GetComponent<Text>();
            txt.font = GetFont();
            txt.fontSize = 20;
            txt.alignment = anchor;
            txt.color = Color.white;
            var txtRect = txt.GetComponent<RectTransform>();
            txtRect.anchorMin = Vector2.zero;
            txtRect.anchorMax = Vector2.one;
            txtRect.offsetMin = new Vector2(10, 10);
            txtRect.offsetMax = new Vector2(-10, -10);
            return txt;
        }

        private void CreateSpeedControls(Transform parent)
        {
            CreateButton(parent, "Pause", new Vector2(340, -10), () => _state.Data.isPaused = true);
            CreateButton(parent, "x1", new Vector2(460, -10), () => { _state.Data.gameSpeed = 1f; _state.Data.isPaused = false; });
            CreateButton(parent, "x2", new Vector2(560, -10), () => { _state.Data.gameSpeed = 2f; _state.Data.isPaused = false; });
            CreateButton(parent, "x3", new Vector2(660, -10), () => { _state.Data.gameSpeed = 3f; _state.Data.isPaused = false; });
            CreateButton(parent, "Next Turn", new Vector2(760, -10), () => _simulation.NextTurn(), 140);
        }

        private void CreateCityButtons(Transform parent)
        {
            CreateButton(parent, "Raise Army", new Vector2(340, -110), () => _armySystem.RaiseArmy(_state.Data.selectedCityId), 150);
            CreateButton(parent, "Temple", new Vector2(500, -110), () => QueueBuild("temple"));
            CreateButton(parent, "School", new Vector2(610, -110), () => QueueBuild("school"));
            CreateButton(parent, "Fort", new Vector2(720, -110), () => QueueBuild("fort"));
            CreateButton(parent, "Cathedral", new Vector2(830, -110), () => QueueBuild("cathedral"), 130);
            CreateButton(parent, "TradeHub", new Vector2(970, -110), () => QueueBuild("tradeHub"), 130);
            CreateButton(parent, "Holy City", new Vector2(1120, -110), DeclareHolyCity, 130);
        }

        private void CreateDiplomacyPanel(Transform parent)
        {
            CreateButton(parent, "NAP", new Vector2(1450, -300), () => _diplomacySystem.ProposePact("NAP"));
            CreateButton(parent, "Trade Pact", new Vector2(1550, -300), () => _diplomacySystem.ProposePact("Trade"), 120);
            CreateButton(parent, "Tribute", new Vector2(1680, -300), () => _diplomacySystem.ProposePact("Tribute"), 120);
            CreateButton(parent, "Holy War", new Vector2(1810, -300), () => _diplomacySystem.ProposePact("HolyWar"), 120);
        }

        private Button CreateButton(Transform parent, string text, Vector2 pos, Action onClick, float width = 90f)
        {
            var go = new GameObject(text + "Btn", typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0, 1);
            rect.anchorMax = new Vector2(0, 1);
            rect.pivot = new Vector2(0, 1);
            rect.sizeDelta = new Vector2(width, 40);
            rect.anchoredPosition = pos;
            go.GetComponent<Image>().color = new Color(0.15f, 0.15f, 0.22f, 0.9f);
            var btn = go.GetComponent<Button>();
            btn.onClick.AddListener(() => onClick?.Invoke());

            var labelGO = new GameObject("Label", typeof(Text));
            labelGO.transform.SetParent(go.transform, false);
            var label = labelGO.GetComponent<Text>();
            label.font = GetFont();
            label.text = text;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            var labelRect = label.GetComponent<RectTransform>();
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;
            return btn;
        }

        private void QueueBuild(string building)
        {
            if (_state.Data.selectedCityId < 0) return;
            _citySystem.QueueBuilding(_state.Data.selectedCityId, building);
        }

        private void DeclareHolyCity()
        {
            if (_state.Data.selectedCityId < 0) return;
            var city = _state.GetCity(_state.Data.selectedCityId);
            if (city != null && city.dominance >= 0.5f)
            {
                city.isHolyCity = true;
                _state.Data.faith.authority += 5f;
                _state.Log($"{city.name} declared a holy city. Pilgrimages increase authority.");
            }
        }

        private void CreateEventModal(Transform parent)
        {
            _eventModal = new GameObject("EventModal", typeof(Image));
            _eventModal.transform.SetParent(parent, false);
            var rect = _eventModal.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.2f, 0.2f);
            rect.anchorMax = new Vector2(0.8f, 0.8f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            _eventModal.GetComponent<Image>().color = new Color(0f, 0f, 0f, 0.85f);

            _eventTitle = CreateModalText(_eventModal.transform, "Title", 34, new Vector2(20, -20), new Vector2(-20, -90));
            _eventDesc = CreateModalText(_eventModal.transform, "Desc", 24, new Vector2(20, -100), new Vector2(-20, -280));

            var listGo = new GameObject("Choices", typeof(RectTransform), typeof(VerticalLayoutGroup));
            listGo.transform.SetParent(_eventModal.transform, false);
            var listRect = listGo.GetComponent<RectTransform>();
            listRect.anchorMin = new Vector2(0, 0);
            listRect.anchorMax = new Vector2(1, 0);
            listRect.pivot = new Vector2(0.5f, 0);
            listRect.anchoredPosition = new Vector2(0, 20);
            listRect.sizeDelta = new Vector2(-40, 220);
            _eventChoiceList = listGo.GetComponent<VerticalLayoutGroup>();
            _eventChoiceList.spacing = 8f;
            _eventChoiceList.padding = new RectOffset(20, 20, 8, 8);
            _eventChoiceList.childControlHeight = false;
            _eventChoiceList.childForceExpandHeight = false;

            _eventModal.SetActive(false);
        }

        private Text CreateModalText(Transform parent, string name, int fontSize, Vector2 minOffset, Vector2 maxOffset)
        {
            var go = new GameObject(name, typeof(Text));
            go.transform.SetParent(parent, false);
            var t = go.GetComponent<Text>();
            t.font = GetFont();
            t.fontSize = fontSize;
            t.alignment = TextAnchor.UpperLeft;
            t.color = Color.white;
            var rt = t.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0, 1);
            rt.anchorMax = new Vector2(1, 1);
            rt.pivot = new Vector2(0.5f, 1);
            rt.offsetMin = minOffset;
            rt.offsetMax = maxOffset;
            return t;
        }

        public void ShowEventModal(GameEventData ev, Action<EventChoice> onChoice)
        {
            _eventModal.SetActive(true);
            _eventTitle.text = ev.title;
            _eventDesc.text = ev.description;

            for (int i = _eventChoiceList.transform.childCount - 1; i >= 0; i--)
                Destroy(_eventChoiceList.transform.GetChild(i).gameObject);

            foreach (var choice in ev.choices)
            {
                var btn = CreateButton(_eventChoiceList.transform, choice.text, Vector2.zero, () =>
                {
                    _eventModal.SetActive(false);
                    onChoice?.Invoke(choice);
                }, 640);
                var rect = btn.GetComponent<RectTransform>();
                rect.sizeDelta = new Vector2(640, 52);
            }
        }

        private void ShowStartModal()
        {
            _state.Data.isPaused = true;
            _startModal = new GameObject("StartModal", typeof(Image));
            _startModal.transform.SetParent(GameObject.Find("UICanvas").transform, false);
            var image = _startModal.GetComponent<Image>();
            image.color = new Color(0f, 0f, 0f, 0.88f);
            var rt = _startModal.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.1f, 0.1f);
            rt.anchorMax = new Vector2(0.9f, 0.9f);
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;

            var title = CreateModalText(_startModal.transform, "StartTitle", 42, new Vector2(20, -20), new Vector2(-20, -100));
            title.text = "Faith Empire Sim - Founding";

            CreateButton(_startModal.transform, "Birthplace: Random", new Vector2(40, -130), SetRandomBirthplace, 240);
            CreateButton(_startModal.transform, "Doctrine: Pacifism", new Vector2(300, -130), () => _state.Data.faith.doctrine.pacifism = !_state.Data.faith.doctrine.pacifism, 260);
            CreateButton(_startModal.transform, "Doctrine: HolyWar", new Vector2(580, -130), () => _state.Data.faith.doctrine.holyWar = !_state.Data.faith.doctrine.holyWar, 260);
            CreateButton(_startModal.transform, "Doctrine: MandatoryWar", new Vector2(860, -130), () => _state.Data.faith.doctrine.mandatoryWar = !_state.Data.faith.doctrine.mandatoryWar, 300);
            CreateButton(_startModal.transform, "Start Campaign", new Vector2(40, -220), () =>
            {
                _state.Data.isPaused = false;
                _startModal.SetActive(false);
            }, 220);
        }

        private void SetRandomBirthplace()
        {
            if (_state.Data.cities.Count == 0) return;
            int idx = UnityEngine.Random.Range(0, _state.Data.cities.Count);
            _state.Data.faith.birthplaceCityId = _state.Data.cities[idx].id;
            _state.Data.cities[idx].faithShare = 0.8f;
            _state.Data.cities[idx].dominance = 0.7f;
            _state.Log($"Birthplace set: {_state.Data.cities[idx].name}");
        }

        public void Refresh()
        {
            var faith = _state.Data.faith;
            _globalText.text = $"Gold: {_state.Data.gold:0}\nLegitimacy: {faith.legitimacy:0.0}\nAuthority: {faith.authority:0.0}\nSpread: {_state.Data.spreadRate:0.00}\nDay: {_state.Data.day}\nDoctrines: {(faith.doctrine.pacifism ? "Pacifism " : "")}{(faith.doctrine.holyWar ? "HolyWar " : "")}{(faith.doctrine.mandatoryWar ? "MandatoryWar" : "")}";

            if (_state.Data.selectedCityId >= 0)
            {
                var city = _state.GetCity(_state.Data.selectedCityId);
                if (city != null)
                {
                    _cityText.text = $"City: {city.name}\nPop: {city.population:0}\nWealth: {city.wealth:0.0}\nDev: {city.development:0.00}\nEdu: {city.education:0.00}\nStability: {city.stability:0.00}\nSecurity: {city.security:0.00}\nFaith: {city.faithShare:P0}\nHeresy: {city.heresyShare:P0}\nDominance: {city.dominance:P0}\nBuildQueue: {string.Join(", ", city.buildQueue)}";
                }
            }
            else _cityText.text = "Tap a city marker to select city.";

            if (_state.Data.selectedArmyId >= 0)
            {
                var army = _state.GetArmy(_state.Data.selectedArmyId);
                if (army != null)
                    _armyText.text = $"Army #{army.id}\nStrength: {army.strength:0.0}\nTarget City: {army.targetCityId}\nSieging: {army.isSieging}\nSiege: {army.siegeProgress:P0}";
            }
            else _armyText.text = "Tap army marker to select army.";

            _sectText.text = $"Sects: {_state.Data.faith.sects.Count}\n";
            foreach (var sect in _state.Data.faith.sects)
                _sectText.text += $"- {sect.name} (Auth {sect.authority:0})\n";

            var sb = new StringBuilder();
            int start = Mathf.Max(0, _state.Data.chronicle.Count - 8);
            for (int i = start; i < _state.Data.chronicle.Count; i++) sb.AppendLine(_state.Data.chronicle[i]);
            _logText.text = sb.ToString();
        }
    }
}
