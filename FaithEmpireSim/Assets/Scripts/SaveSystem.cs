using System.IO;
using UnityEngine;

namespace FaithEmpireSim
{
    public class SaveSystem : MonoBehaviour
    {
        private const string SaveName = "faith_empire_save.json";

        public void Save(GameState state)
        {
            string json = JsonUtility.ToJson(state.Data, true);
            string path = Path.Combine(Application.persistentDataPath, SaveName);
            File.WriteAllText(path, json);
            state.Log($"Game saved: {path}");
        }

        public bool Load(GameState state)
        {
            string path = Path.Combine(Application.persistentDataPath, SaveName);
            if (!File.Exists(path)) return false;
            state.Data = JsonUtility.FromJson<GameStateData>(File.ReadAllText(path));
            state.Log("Game loaded.");
            return true;
        }
    }
}
