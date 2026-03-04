using UnityEngine;

namespace FaithEmpireSim
{
    public class ArmySystem : MonoBehaviour
    {
        private GameState _state;
        private int _nextArmyId;

        public void Initialize(GameState state)
        {
            _state = state;
            _nextArmyId = 0;
        }

        public void RaiseArmy(int cityId)
        {
            var city = _state.GetCity(cityId);
            if (city == null || _state.Data.gold < 40f || city.dominance < 0.2f) return;

            _state.Data.gold -= 40f;
            var army = new ArmyData
            {
                id = _nextArmyId++,
                kingdomId = city.kingdomId,
                sourceCityId = cityId,
                targetCityId = cityId,
                position = city.worldPos + Vector3.up * 0.8f,
                strength = city.population * 0.0006f + 20f
            };
            _state.Data.armies.Add(army);

            var marker = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            marker.name = $"ArmyMarker_{army.id}";
            marker.transform.position = army.position;
            marker.transform.localScale = new Vector3(0.5f, 0.6f, 0.5f);
            marker.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            marker.GetComponent<Renderer>().sharedMaterial.color = Color.red;
            marker.AddComponent<ArmyMarker>().ArmyId = army.id;
            Destroy(marker.GetComponent<Collider>());
            marker.AddComponent<CapsuleCollider>().radius = 0.4f;

            _state.Log($"Army raised at {city.name}.");
        }

        public void SetArmyTarget(int armyId, int cityId)
        {
            var army = _state.GetArmy(armyId);
            if (army == null) return;
            army.targetCityId = cityId;
            army.isSieging = false;
        }

        public void TickArmies(float dt, DoctrineAxes doctrine)
        {
            foreach (var army in _state.Data.armies)
            {
                var target = _state.GetCity(army.targetCityId);
                if (target == null) continue;

                Vector3 dest = target.worldPos + Vector3.up * 0.8f;
                float speed = 4.5f + (doctrine.militarism * 3f);
                army.position = Vector3.MoveTowards(army.position, dest, speed * dt);

                var marker = GameObject.Find($"ArmyMarker_{army.id}");
                if (marker != null) marker.transform.position = army.position;

                if (Vector3.Distance(army.position, dest) < 0.2f)
                {
                    if (target.kingdomId != army.kingdomId)
                    {
                        army.isSieging = true;
                        float siegeRate = 0.01f + army.strength * 0.0002f + (doctrine.holyWar ? 0.006f : 0f);
                        army.siegeProgress += siegeRate * dt;
                        target.stability = Mathf.Clamp01(target.stability - 0.002f * dt);
                        if (army.siegeProgress >= 1f)
                        {
                            target.kingdomId = army.kingdomId;
                            target.dominance = Mathf.Clamp01(target.dominance + 0.2f);
                            target.faithShare = Mathf.Clamp01(target.faithShare + 0.15f);
                            army.siegeProgress = 0f;
                            army.isSieging = false;
                            _state.Log($"{target.name} captured by Kingdom {army.kingdomId + 1}.");
                        }
                    }
                }
            }
        }
    }

    public class ArmyMarker : MonoBehaviour
    {
        public int ArmyId;
    }
}
