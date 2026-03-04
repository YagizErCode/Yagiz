using UnityEngine;
using UnityEngine.EventSystems;

namespace FaithEmpireSim
{
    public class SelectionController : MonoBehaviour
    {
        private Camera _cam;
        private GameState _state;
        private ArmySystem _armySystem;

        private Vector3 _lastPan;

        public void Initialize(GameState state, ArmySystem armySystem)
        {
            _state = state;
            _armySystem = armySystem;
            _cam = Camera.main;
        }

        private void Update()
        {
            HandleSelection();
            HandleCameraTouch();
        }

        private void HandleSelection()
        {
            if (Input.GetMouseButtonDown(0))
            {
                if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject()) return;
                Ray ray = _cam.ScreenPointToRay(Input.mousePosition);
                if (Physics.Raycast(ray, out RaycastHit hit, 500f))
                {
                    var city = hit.collider.GetComponent<CityMarker>();
                    if (city != null)
                    {
                        _state.Data.selectedCityId = city.CityId;
                        if (_state.Data.selectedArmyId >= 0)
                            _armySystem.SetArmyTarget(_state.Data.selectedArmyId, city.CityId);
                        return;
                    }

                    var army = hit.collider.GetComponent<ArmyMarker>();
                    if (army != null)
                    {
                        _state.Data.selectedArmyId = army.ArmyId;
                    }
                }
            }
        }

        private void HandleCameraTouch()
        {
            if (Input.touchCount == 1)
            {
                var t = Input.GetTouch(0);
                if (t.phase == TouchPhase.Began) _lastPan = t.position;
                if (t.phase == TouchPhase.Moved)
                {
                    Vector2 delta = t.position - (Vector2)_lastPan;
                    _cam.transform.Translate(new Vector3(-delta.x, 0f, -delta.y) * 0.02f, Space.World);
                    _lastPan = t.position;
                }
            }
            else if (Input.touchCount >= 2)
            {
                var t0 = Input.GetTouch(0);
                var t1 = Input.GetTouch(1);
                float prevDist = (t0.position - t0.deltaPosition - (t1.position - t1.deltaPosition)).magnitude;
                float currDist = (t0.position - t1.position).magnitude;
                float delta = currDist - prevDist;
                _cam.transform.position += _cam.transform.forward * delta * 0.02f;
            }

            if (Input.GetMouseButtonDown(1)) _lastPan = Input.mousePosition;
            if (Input.GetMouseButton(1))
            {
                Vector3 delta = Input.mousePosition - _lastPan;
                _cam.transform.Translate(new Vector3(-delta.x, 0f, -delta.y) * 0.02f, Space.World);
                _lastPan = Input.mousePosition;
            }
            float scroll = Input.mouseScrollDelta.y;
            if (Mathf.Abs(scroll) > 0.001f) _cam.transform.position += _cam.transform.forward * scroll * 2f;
        }
    }
}
