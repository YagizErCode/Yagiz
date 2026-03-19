using System.Collections.Generic;
using UnityEngine;

namespace FaithEmpireSim
{
    public class WorldGenerator : MonoBehaviour
    {
        public int width = 192;
        public int height = 192;
        public float noiseScale = 0.03f;
        public float heightScale = 12f;
        public MeshFilter mapMeshFilter;
        public MeshRenderer mapRenderer;

        private float[,] _heightMap;
        private string[,] _biomeMap;

        public void Generate(GameState state)
        {
            var mapRoot = new GameObject("MapMesh");
            mapRoot.transform.SetParent(transform);
            mapMeshFilter = mapRoot.AddComponent<MeshFilter>();
            mapRenderer = mapRoot.AddComponent<MeshRenderer>();
            mapRenderer.sharedMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));

            _heightMap = new float[width, height];
            _biomeMap = new string[width, height];

            var verts = new Vector3[width * height];
            var uvs = new Vector2[verts.Length];
            var colors = new Color[verts.Length];
            var tris = new List<int>(width * height * 6);

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    float nx = x * noiseScale;
                    float ny = y * noiseScale;
                    float h1 = Mathf.PerlinNoise(nx, ny);
                    float h2 = Mathf.PerlinNoise(nx * 0.5f + 100f, ny * 0.5f + 100f);
                    float elev = (h1 * 0.65f + h2 * 0.35f);
                    _heightMap[x, y] = elev;
                    string biome = ResolveBiome(elev, y / (float)height);
                    _biomeMap[x, y] = biome;

                    int i = y * width + x;
                    verts[i] = new Vector3(x, elev * heightScale, y);
                    uvs[i] = new Vector2(x / (float)width, y / (float)height);
                    colors[i] = BiomeColor(biome);
                }
            }

            for (int y = 0; y < height - 1; y++)
            {
                for (int x = 0; x < width - 1; x++)
                {
                    int i = y * width + x;
                    tris.Add(i); tris.Add(i + width); tris.Add(i + 1);
                    tris.Add(i + 1); tris.Add(i + width); tris.Add(i + width + 1);
                }
            }

            Mesh mesh = new Mesh { indexFormat = UnityEngine.Rendering.IndexFormat.UInt32 };
            mesh.vertices = verts;
            mesh.colors = colors;
            mesh.uv = uvs;
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mapMeshFilter.sharedMesh = mesh;

            var collider = mapRoot.AddComponent<MeshCollider>();
            collider.sharedMesh = mesh;

            GenerateCitiesAndKingdoms(state);
            GenerateRivers();
            GenerateResourceNodes();
        }

        private void GenerateCitiesAndKingdoms(GameState state)
        {
            int cityCount = Random.Range(150, 251);
            int kingdomCount = Random.Range(6, 13);

            for (int i = 0; i < kingdomCount; i++)
            {
                state.Data.kingdoms.Add(new KingdomData
                {
                    id = i,
                    name = $"Kingdom {i + 1}",
                    color = Color.HSVToRGB(i / (float)kingdomCount, 0.75f, 1f),
                    militaryPower = Random.Range(30f, 90f),
                    treasury = Random.Range(150f, 450f)
                });
            }

            int placed = 0;
            int guard = 0;
            while (placed < cityCount && guard < cityCount * 20)
            {
                guard++;
                int x = Random.Range(4, width - 4);
                int y = Random.Range(4, height - 4);
                float h = _heightMap[x, y];
                var biome = _biomeMap[x, y];
                if (h < 0.28f || h > 0.88f || biome == "mountains" || biome == "ocean") continue;

                bool nearWater = false;
                for (int dy = -3; dy <= 3; dy++)
                for (int dx = -3; dx <= 3; dx++)
                {
                    int px = Mathf.Clamp(x + dx, 0, width - 1);
                    int py = Mathf.Clamp(y + dy, 0, height - 1);
                    if (_biomeMap[px, py] == "coast" || _biomeMap[px, py] == "ocean") nearWater = true;
                }

                if (!nearWater && biome != "plains" && biome != "savanna") continue;

                Vector3 pos = new Vector3(x, _heightMap[x, y] * heightScale + 0.5f, y);
                if (state.Data.cities.Exists(c => Vector3.Distance(c.worldPos, pos) < 5f)) continue;

                int kingdom = Random.Range(0, kingdomCount);
                var city = new CityData
                {
                    id = placed,
                    name = $"City {placed + 1}",
                    kingdomId = kingdom,
                    worldPos = pos,
                    biome = biome,
                    population = Random.Range(4000f, 65000f),
                    wealth = Random.Range(20f, 180f),
                    development = Random.Range(0.15f, 0.85f),
                    education = Random.Range(0.1f, 0.9f),
                    stability = Random.Range(0.3f, 0.95f),
                    security = Random.Range(0.2f, 0.9f),
                    cultureId = Random.Range(0, 16),
                    faithShare = Random.Range(0.01f, 0.2f),
                    heresyShare = 0f,
                    dominance = Random.Range(0.05f, 0.35f)
                };
                state.Data.cities.Add(city);
                state.Data.kingdoms[kingdom].cityIds.Add(city.id);

                var marker = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                marker.name = $"CityMarker_{city.id}";
                marker.transform.position = city.worldPos;
                marker.transform.localScale = Vector3.one * 0.9f;
                marker.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
                marker.GetComponent<Renderer>().sharedMaterial.color = Color.Lerp(Color.gray, Color.cyan, city.faithShare);
                marker.AddComponent<CityMarker>().CityId = city.id;
                Destroy(marker.GetComponent<Collider>());
                marker.AddComponent<SphereCollider>().radius = 0.6f;
                placed++;
            }

            foreach (var city in state.Data.cities)
            {
                int links = Random.Range(2, 6);
                for (int i = 0; i < links; i++)
                {
                    var target = state.Data.cities[Random.Range(0, state.Data.cities.Count)];
                    if (target.id == city.id) continue;
                    if (Vector3.Distance(target.worldPos, city.worldPos) > 45f) continue;

                    int tradeId = state.Data.tradeLinks.Count;
                    state.Data.tradeLinks.Add(new TradeLink { fromCityId = city.id, toCityId = target.id, strength = Random.Range(0.4f, 1.4f) });
                    city.tradeLinks.Add(tradeId);
                }
            }
        }

        private void GenerateRivers()
        {
            for (int r = 0; r < 18; r++)
            {
                var riverObj = new GameObject($"River_{r}");
                var lr = riverObj.AddComponent<LineRenderer>();
                lr.material = new Material(Shader.Find("Universal Render Pipeline/Unlit"));
                lr.material.color = new Color(0.2f, 0.45f, 1f, 0.85f);
                lr.widthMultiplier = 0.3f;
                lr.positionCount = 20;

                Vector3 p = new Vector3(Random.Range(0, width), heightScale * 0.9f, Random.Range(0, height));
                for (int i = 0; i < 20; i++)
                {
                    p.x = Mathf.Clamp(p.x + Random.Range(-3, 4), 0, width - 1);
                    p.z = Mathf.Clamp(p.z + Random.Range(-3, 4), 0, height - 1);
                    float h = _heightMap[(int)p.x, (int)p.z] * heightScale + 0.15f;
                    p.y = h;
                    lr.SetPosition(i, p);
                }
            }
        }

        private void GenerateResourceNodes()
        {
            string[] resourceTypes = { "food", "wood", "iron", "gold", "mana" };
            for (int i = 0; i < 350; i++)
            {
                int x = Random.Range(0, width);
                int y = Random.Range(0, height);
                if (_heightMap[x, y] < 0.25f) continue;
                var node = GameObject.CreatePrimitive(PrimitiveType.Cube);
                node.name = $"Res_{resourceTypes[Random.Range(0, resourceTypes.Length)]}_{i}";
                node.transform.position = new Vector3(x, _heightMap[x, y] * heightScale + 0.3f, y);
                node.transform.localScale = new Vector3(0.35f, 0.35f, 0.35f);
                var renderer = node.GetComponent<Renderer>();
                renderer.sharedMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
                renderer.sharedMaterial.color = new Color(0.95f, 0.85f, 0.35f);
                Destroy(node.GetComponent<Collider>());
            }
        }

        public string GetBiomeAt(Vector3 world)
        {
            int x = Mathf.Clamp(Mathf.RoundToInt(world.x), 0, width - 1);
            int y = Mathf.Clamp(Mathf.RoundToInt(world.z), 0, height - 1);
            return _biomeMap[x, y];
        }

        private string ResolveBiome(float h, float lat)
        {
            if (h < 0.24f) return "ocean";
            if (h < 0.28f) return "coast";
            if (h > 0.84f) return "mountains";
            if (lat < 0.1f || lat > 0.9f) return "tundra";
            if (lat < 0.2f || lat > 0.8f) return h > 0.55f ? "taiga" : "plains";
            if (lat > 0.38f && lat < 0.62f)
            {
                if (h < 0.4f) return "desert";
                if (h < 0.58f) return "savanna";
                return "jungle";
            }
            return "plains";
        }

        private Color BiomeColor(string biome)
        {
            return biome switch
            {
                "ocean" => new Color(0.05f, 0.18f, 0.45f),
                "coast" => new Color(0.2f, 0.38f, 0.6f),
                "tundra" => new Color(0.75f, 0.8f, 0.86f),
                "taiga" => new Color(0.3f, 0.5f, 0.35f),
                "plains" => new Color(0.35f, 0.65f, 0.25f),
                "desert" => new Color(0.85f, 0.76f, 0.4f),
                "savanna" => new Color(0.65f, 0.6f, 0.25f),
                "jungle" => new Color(0.1f, 0.45f, 0.15f),
                "mountains" => new Color(0.45f, 0.45f, 0.45f),
                _ => Color.magenta
            };
        }
    }

    public class CityMarker : MonoBehaviour
    {
        public int CityId;
    }
}
