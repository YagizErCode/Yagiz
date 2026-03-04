using UnityEngine;

namespace FaithEmpireSim
{
    public class CharacterSystem : MonoBehaviour
    {
        private static readonly string[] Traits = { "Zealous", "Scholar", "Cruel", "Merciful", "Trader", "Warlike", "Ascetic" };
        public void GenerateCharacters(GameState state)
        {
            int charId = 0;
            foreach (var kingdom in state.Data.kingdoms)
            {
                var c = new CharacterData
                {
                    id = $"char_{charId}",
                    name = $"Ruler {charId + 1}",
                    dynasty = $"Dynasty {Random.Range(1, 500)}",
                    learning = Random.Range(1, 21),
                    martial = Random.Range(1, 21),
                    intrigue = Random.Range(1, 21),
                    diplomacy = Random.Range(1, 21)
                };
                c.traits.Add(Traits[Random.Range(0, Traits.Length)]);
                state.Data.characters.Add(c);
                kingdom.rulerCharacterId = charId;
                charId++;
            }

            state.Data.characters.Add(new CharacterData
            {
                id = "player_prophet",
                name = "Prophet",
                dynasty = "Founder",
                learning = 14,
                martial = 8,
                intrigue = 10,
                diplomacy = 12,
                traits = { "Inspired", "Charismatic" }
            });
        }
    }
}
