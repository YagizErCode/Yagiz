using System;
using System.Collections.Generic;
using UnityEngine;

namespace FaithEmpireSim
{
    [Serializable] public class EventChoice { public string text; public EventEffect effects; public string nextEventId; }
    [Serializable] public class EventCondition { public string key; public float min; public float max; }
    [Serializable] public class EventEffect
    {
        public float gold;
        public float authority;
        public float legitimacy;
        public float unrest;
        public float cityStability;
        public float cityFaith;
    }
    [Serializable] public class GameEventData
    {
        public string id;
        public string title;
        public string description;
        public List<EventChoice> choices;
        public List<EventCondition> conditions;
        public float weight = 1f;
        public int cooldown = 5;
    }
    [Serializable] public class EventPack { public List<GameEventData> events; }

    public class EventSystemJSON : MonoBehaviour
    {
        private GameState _state;
        private UIController _ui;
        private readonly Dictionary<string, int> _lastDayTriggered = new Dictionary<string, int>();
        private List<GameEventData> _events = new List<GameEventData>();

        public void Initialize(GameState state, UIController ui)
        {
            _state = state;
            _ui = ui;
            LoadEvents();
        }

        private void LoadEvents()
        {
            TextAsset ta = Resources.Load<TextAsset>("Events/events_pack");
            if (ta == null)
            {
                Debug.LogError("events_pack.json missing in Resources/Events.");
                return;
            }
            EventPack pack = JsonUtility.FromJson<EventPack>(ta.text);
            _events = pack?.events ?? new List<GameEventData>();
            Debug.Log($"Loaded {_events.Count} events.");
        }

        public void TryTriggerPeriodicEvent()
        {
            if (_events.Count == 0 || _state.Data.modalOpen) return;
            if (UnityEngine.Random.value > 0.12f) return;

            var candidates = new List<GameEventData>();
            foreach (var ev in _events)
            {
                if (_lastDayTriggered.TryGetValue(ev.id, out int day) && _state.Data.day - day < ev.cooldown) continue;
                if (CheckConditions(ev.conditions)) candidates.Add(ev);
            }
            if (candidates.Count == 0) return;

            float total = 0f;
            foreach (var c in candidates) total += Mathf.Max(0.01f, c.weight);
            float pick = UnityEngine.Random.value * total;
            foreach (var c in candidates)
            {
                pick -= Mathf.Max(0.01f, c.weight);
                if (pick <= 0f)
                {
                    ShowEvent(c);
                    return;
                }
            }
        }

        private bool CheckConditions(List<EventCondition> conditions)
        {
            if (conditions == null || conditions.Count == 0) return true;
            foreach (var c in conditions)
            {
                float value = c.key switch
                {
                    "authority" => _state.Data.faith.authority,
                    "legitimacy" => _state.Data.faith.legitimacy,
                    "gold" => _state.Data.gold,
                    _ => 50f
                };
                if (value < c.min || value > c.max) return false;
            }
            return true;
        }

        private void ShowEvent(GameEventData data)
        {
            _state.Data.modalOpen = true;
            _state.Data.isPaused = true;
            _lastDayTriggered[data.id] = _state.Data.day;
            _ui.ShowEventModal(data, choice => ResolveChoice(data, choice));
        }

        private void ResolveChoice(GameEventData ev, EventChoice choice)
        {
            ApplyEffect(choice.effects);
            _state.Log($"Event: {ev.title} -> {choice.text}");
            _state.Data.modalOpen = false;
            _state.Data.isPaused = false;

            if (!string.IsNullOrWhiteSpace(choice.nextEventId))
            {
                var next = _events.Find(e => e.id == choice.nextEventId);
                if (next != null) ShowEvent(next);
            }
        }

        private void ApplyEffect(EventEffect effect)
        {
            if (effect == null) return;
            _state.Data.gold += effect.gold;
            _state.Data.faith.authority = Mathf.Clamp(_state.Data.faith.authority + effect.authority, 0f, 100f);
            _state.Data.faith.legitimacy = Mathf.Clamp(_state.Data.faith.legitimacy + effect.legitimacy, 0f, 100f);
            _state.Data.faith.unrest = Mathf.Clamp(_state.Data.faith.unrest + effect.unrest, 0f, 100f);

            if (_state.Data.selectedCityId >= 0)
            {
                var city = _state.GetCity(_state.Data.selectedCityId);
                if (city != null)
                {
                    city.stability = Mathf.Clamp01(city.stability + effect.cityStability);
                    city.faithShare = Mathf.Clamp01(city.faithShare + effect.cityFaith);
                }
            }
        }
    }
}
