using UnityEngine;

namespace FaithEmpireSim
{
    public class CitySystem : MonoBehaviour
    {
        private GameState _state;

        public void Initialize(GameState state) => _state = state;

        public void TickEconomy()
        {
            foreach (var city in _state.Data.cities)
            {
                city.wealth += city.population * 0.00001f * city.development;
                city.population += city.population * (0.0004f + city.development * 0.0003f - city.heresyShare * 0.0002f);
                city.stability = Mathf.Clamp01(city.stability + (city.security - city.heresyShare) * 0.0008f);
                city.development = Mathf.Clamp01(city.development + city.education * 0.0004f);
                city.dominance = Mathf.Clamp01(city.dominance + city.faithShare * 0.0005f - city.heresyShare * 0.0004f);
            }

            float income = 0f;
            foreach (var c in _state.Data.cities)
                income += c.wealth * Mathf.Max(0.05f, c.dominance) * 0.001f;
            _state.Data.gold += income;
        }

        public void QueueBuilding(int cityId, string building)
        {
            var city = _state.GetCity(cityId);
            if (city == null) return;
            city.buildQueue.Add(building);
            _state.Log($"{building} queued in {city.name}.");
        }

        public void ResolveBuildings()
        {
            foreach (var city in _state.Data.cities)
            {
                if (city.buildQueue.Count == 0) continue;
                string b = city.buildQueue[0];
                city.buildQueue.RemoveAt(0);
                ApplyBuilding(city, b);
            }
        }

        private void ApplyBuilding(CityData city, string building)
        {
            switch (building)
            {
                case "temple": city.dominance = Mathf.Clamp01(city.dominance + 0.08f); city.faithShare = Mathf.Clamp01(city.faithShare + 0.07f); break;
                case "school": city.education = Mathf.Clamp01(city.education + 0.1f); city.development = Mathf.Clamp01(city.development + 0.04f); break;
                case "fort": city.security = Mathf.Clamp01(city.security + 0.12f); city.stability = Mathf.Clamp01(city.stability + 0.04f); break;
                case "cathedral": city.dominance = Mathf.Clamp01(city.dominance + 0.16f); city.faithShare = Mathf.Clamp01(city.faithShare + 0.12f); break;
                case "tradeHub": city.wealth += 24f; city.development = Mathf.Clamp01(city.development + 0.06f); break;
            }
            _state.Log($"{city.name} completed {building}.");
        }
    }
}
