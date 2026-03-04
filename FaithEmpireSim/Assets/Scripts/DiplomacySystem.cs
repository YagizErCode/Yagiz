using UnityEngine;

namespace FaithEmpireSim
{
    public class DiplomacySystem : MonoBehaviour
    {
        private GameState _state;

        public void Initialize(GameState state) => _state = state;

        public void TickDiplomacy()
        {
            foreach (var kingdom in _state.Data.kingdoms)
            {
                kingdom.relations = Mathf.Clamp(kingdom.relations + Random.Range(-0.01f, 0.01f), -1f, 1f);
                kingdom.treasury += Random.Range(0.2f, 1.8f);
            }
        }

        public void ProposePact(string pactType)
        {
            _state.Log($"Diplomacy action: {pactType} proposed.");
            if (pactType == "Trade") _state.Data.gold += 30f;
            if (pactType == "Tribute") _state.Data.gold += 60f;
            if (pactType == "HolyWar") _state.Data.faith.authority += 2f;
        }
    }
}
