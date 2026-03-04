using UnityEngine;

namespace FaithEmpireSim
{
    public class ReligionSystem : MonoBehaviour
    {
        private GameState _state;
        private int _nextSectId = 1;

        public void Initialize(GameState state)
        {
            _state = state;
        }

        public void TickSpread()
        {
            var data = _state.Data;
            float doctrineBoost = 1f + (data.faith.doctrine.ritual + data.faith.doctrine.charity + data.faith.doctrine.commerce) * 0.3f;
            float zealPressure = data.faith.doctrine.militarism - data.faith.doctrine.tolerance;

            foreach (var city in data.cities)
            {
                float incoming = 0f;
                foreach (int linkId in city.tradeLinks)
                {
                    var link = data.tradeLinks[linkId];
                    var source = _state.GetCity(link.fromCityId == city.id ? link.toCityId : link.fromCityId);
                    if (source == null) continue;
                    float distance = Vector3.Distance(source.worldPos, city.worldPos);
                    float cultureFactor = 1f - Mathf.Abs(source.cultureId - city.cultureId) / 16f;
                    incoming += source.faithShare * 0.02f * link.strength * cultureFactor * Mathf.Clamp01(1f - distance / 80f);
                }

                float resistance = city.education * 0.18f + city.security * 0.14f + Mathf.Max(0f, zealPressure) * 0.1f;
                float push = (incoming + city.dominance * 0.015f) * doctrineBoost;
                city.faithShare = Mathf.Clamp01(city.faithShare + (push - resistance * 0.01f) * Time.deltaTime * data.gameSpeed);

                float heresyRise = Mathf.Max(0f, (0.6f - city.stability) + (45f - data.faith.authority) * 0.01f) * 0.003f;
                city.heresyShare = Mathf.Clamp01(city.heresyShare + heresyRise * data.gameSpeed * Time.deltaTime - city.security * 0.0015f);
            }

            if (Random.value < 0.0025f + Mathf.Max(0f, 40f - data.faith.authority) * 0.00006f)
            {
                TrySchism();
            }

            data.spreadRate = doctrineBoost;
            data.faith.authority = Mathf.Clamp(data.faith.authority + (AverageFaithShare() * 0.25f - AverageHeresyShare() * 0.4f) * Time.deltaTime * data.gameSpeed, 0f, 100f);
            data.faith.legitimacy = Mathf.Clamp(data.faith.legitimacy + (data.faith.authority * 0.01f - data.faith.unrest * 0.015f) * Time.deltaTime * data.gameSpeed, 0f, 100f);
        }

        public float AverageFaithShare()
        {
            if (_state.Data.cities.Count == 0) return 0f;
            float sum = 0f;
            foreach (var c in _state.Data.cities) sum += c.faithShare;
            return sum / _state.Data.cities.Count;
        }

        public float AverageHeresyShare()
        {
            if (_state.Data.cities.Count == 0) return 0f;
            float sum = 0f;
            foreach (var c in _state.Data.cities) sum += c.heresyShare;
            return sum / _state.Data.cities.Count;
        }

        private void TrySchism()
        {
            var data = _state.Data;
            if (data.faith.sects.Count > 8) return;

            var sect = new SectData
            {
                id = _nextSectId++,
                name = $"Sect {_nextSectId}",
                authority = Random.Range(20f, 60f),
                doctrine = new DoctrineAxes
                {
                    tolerance = Mathf.Clamp01(data.faith.doctrine.tolerance + Random.Range(-0.2f, 0.2f)),
                    militarism = Mathf.Clamp01(data.faith.doctrine.militarism + Random.Range(-0.2f, 0.2f)),
                    knowledge = Mathf.Clamp01(data.faith.doctrine.knowledge + Random.Range(-0.2f, 0.2f)),
                    ritual = Mathf.Clamp01(data.faith.doctrine.ritual + Random.Range(-0.2f, 0.2f)),
                    commerce = Mathf.Clamp01(data.faith.doctrine.commerce + Random.Range(-0.2f, 0.2f)),
                    austerity = Mathf.Clamp01(data.faith.doctrine.austerity + Random.Range(-0.2f, 0.2f)),
                    charity = Mathf.Clamp01(data.faith.doctrine.charity + Random.Range(-0.2f, 0.2f)),
                    holyWar = Random.value > 0.5f,
                    pacifism = Random.value > 0.5f
                }
            };
            data.faith.sects.Add(sect);

            int converts = 0;
            foreach (var city in data.cities)
            {
                if (Random.value < city.heresyShare * 0.3f)
                {
                    city.dominance *= 0.8f;
                    city.heresyShare = Mathf.Clamp01(city.heresyShare + 0.15f);
                    converts++;
                }
            }
            _state.Log($"Schism! {sect.name} emerged and influenced {converts} cities.");
        }
    }
}
