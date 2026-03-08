@tool
extends EditorScript
## Run from Editor > Run Script to regenerate events_pack.json.
## Alternatively, the Python script Tools/generate_events.py does the same.

func _run() -> void:
	print("Use 'python3 Tools/generate_events.py' to regenerate events.")
	print("The Python generator is deterministic (seeded) and produces 200+ events with 10+ chains.")
	print("Events are output to res://Resources/Events/events_pack.json")
