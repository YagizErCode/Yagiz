using System;
using System.Collections.Generic;
using UnityEngine;

namespace FaithEmpireSim
{
    [Serializable]
    public class DoctrineAxes
    {
        [Range(0f, 1f)] public float tolerance = 0.5f;
        [Range(0f, 1f)] public float militarism = 0.5f;
        [Range(0f, 1f)] public float knowledge = 0.5f;
        [Range(0f, 1f)] public float ritual = 0.5f;
        [Range(0f, 1f)] public float commerce = 0.5f;
        [Range(0f, 1f)] public float austerity = 0.5f;
        [Range(0f, 1f)] public float charity = 0.5f;

        public bool pacifism;
        public bool holyWar;
        public bool ritualizedSex;
        public bool mandatoryWar;
    }

    [Serializable]
    public class CharacterData
    {
        public string id;
        public string name;
        public string dynasty;
        public int learning;
        public int martial;
        public int intrigue;
        public int diplomacy;
        public List<string> traits = new List<string>();
    }

    [Serializable]
    public class KingdomData
    {
        public int id;
        public string name;
        public Color color;
        public int rulerCharacterId;
        public List<int> cityIds = new List<int>();
        public float relations;
        public float militaryPower;
        public float treasury;
    }

    [Serializable]
    public class TradeLink
    {
        public int fromCityId;
        public int toCityId;
        public float strength;
    }

    [Serializable]
    public class CityData
    {
        public int id;
        public string name;
        public int kingdomId;
        public Vector3 worldPos;
        public string biome;
        public float population;
        public float wealth;
        public float development;
        public float education;
        public float stability;
        public float security;
        public int cultureId;
        public float faithShare;
        public float heresyShare;
        public float dominance;
        public bool isHolyCity;
        public List<string> buildQueue = new List<string>();
        public List<int> tradeLinks = new List<int>();
    }

    [Serializable]
    public class ArmyData
    {
        public int id;
        public int kingdomId;
        public int sourceCityId;
        public int targetCityId;
        public Vector3 position;
        public float strength;
        public bool isSieging;
        public float siegeProgress;
    }

    [Serializable]
    public class SectData
    {
        public int id;
        public string name;
        public DoctrineAxes doctrine;
        public float authority;
    }

    [Serializable]
    public class FaithData
    {
        public string name = "New Faith";
        public DoctrineAxes doctrine = new DoctrineAxes();
        public float legitimacy = 50f;
        public float authority = 50f;
        public float unrest = 5f;
        public int birthplaceCityId = -1;
        public List<SectData> sects = new List<SectData>();
    }

    [Serializable]
    public class GameStateData
    {
        public int day;
        public float gameSpeed = 1f;
        public bool isPaused;
        public bool modalOpen;
        public float gold = 500f;
        public float spreadRate = 1f;
        public FaithData faith = new FaithData();
        public List<CityData> cities = new List<CityData>();
        public List<KingdomData> kingdoms = new List<KingdomData>();
        public List<TradeLink> tradeLinks = new List<TradeLink>();
        public List<ArmyData> armies = new List<ArmyData>();
        public List<CharacterData> characters = new List<CharacterData>();
        public List<string> chronicle = new List<string>();
        public int selectedCityId = -1;
        public int selectedArmyId = -1;
    }

    public class GameState : MonoBehaviour
    {
        public GameStateData Data = new GameStateData();

        public CityData GetCity(int id) => Data.cities.Find(c => c.id == id);
        public ArmyData GetArmy(int id) => Data.armies.Find(a => a.id == id);
        public KingdomData GetKingdom(int id) => Data.kingdoms.Find(k => k.id == id);

        public void Log(string text)
        {
            Data.chronicle.Add($"Day {Data.day}: {text}");
            if (Data.chronicle.Count > 300)
            {
                Data.chronicle.RemoveAt(0);
            }
        }
    }
}
