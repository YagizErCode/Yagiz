using UnityEngine;

namespace FaithEmpireSim
{
    public class SimulationLoop : MonoBehaviour
    {
        private GameState _state;
        private CitySystem _citySystem;
        private ReligionSystem _religionSystem;
        private ArmySystem _armySystem;
        private DiplomacySystem _diplomacySystem;
        private EventSystemJSON _eventSystem;

        private float _dayTimer;

        public void Initialize(GameState state, CitySystem citySystem, ReligionSystem religionSystem, ArmySystem armySystem, DiplomacySystem diplomacySystem, EventSystemJSON eventSystem)
        {
            _state = state;
            _citySystem = citySystem;
            _religionSystem = religionSystem;
            _armySystem = armySystem;
            _diplomacySystem = diplomacySystem;
            _eventSystem = eventSystem;
        }

        private void Update()
        {
            if (_state == null || _state.Data.isPaused) return;

            float dt = Time.deltaTime * Mathf.Max(0.1f, _state.Data.gameSpeed);
            _religionSystem.TickSpread();
            _armySystem.TickArmies(dt, _state.Data.faith.doctrine);

            _dayTimer += dt;
            if (_dayTimer >= 1f)
            {
                _dayTimer = 0f;
                _state.Data.day++;
                _citySystem.TickEconomy();
                _citySystem.ResolveBuildings();
                _diplomacySystem.TickDiplomacy();
                _eventSystem.TryTriggerPeriodicEvent();
            }
        }

        public void NextTurn()
        {
            _state.Data.day++;
            _citySystem.TickEconomy();
            _citySystem.ResolveBuildings();
            _diplomacySystem.TickDiplomacy();
            _eventSystem.TryTriggerPeriodicEvent();
        }
    }
}
