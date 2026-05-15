extends Node

const EVENT_PATHS := [
	"res://content/events/life_events.json",
	"res://content/events/investment_events.json",
	"res://content/events/relationship_events.json",
	"res://content/events/hidden_events.json",
]
const ASSETS_PATH := "res://content/assets.json"
const JOBS_PATH := "res://content/jobs.json"
const ITEMS_PATH := "res://content/items.json"
const ENDINGS_PATH := "res://content/endings.json"
const NEWS_PATH := "res://content/news_templates.json"
const META_PATH := "res://content/meta/default_meta.json"

var events: Array = []
var events_by_id: Dictionary = {}
var assets: Array = []
var assets_by_id: Dictionary = {}
var jobs: Array = []
var jobs_by_id: Dictionary = {}
var items: Array = []
var items_by_id: Dictionary = {}
var endings: Array = []
var endings_by_id: Dictionary = {}
var news_templates: Array = []
var default_meta: Dictionary = {}

func _ready():
	reload()

func reload():
	events.clear()
	events_by_id.clear()
	for path in EVENT_PATHS:
		for event in _load_array(path):
			events.append(event)
			events_by_id[event.get("id", "")] = event

	assets = _load_array(ASSETS_PATH)
	assets_by_id = _index_by_id(assets)
	jobs = _load_array(JOBS_PATH)
	jobs_by_id = _index_by_id(jobs)
	items = _load_array(ITEMS_PATH)
	items_by_id = _index_by_id(items)
	endings = _load_array(ENDINGS_PATH)
	endings_by_id = _index_by_id(endings)
	news_templates = _load_array(NEWS_PATH)
	default_meta = _load_dict(META_PATH)

func find_event(event_id):
	return events_by_id.get(event_id, {})

func get_all_events():
	return events

func get_events(category):
	if category.is_empty():
		return events
	var filtered: Array = []
	for event in events:
		if event.get("category", "") == category:
			filtered.append(event)
	return filtered

func get_assets_by_category(category):
	var filtered: Array = []
	for asset in assets:
		if asset.get("category", "") == category:
			filtered.append(asset)
	return filtered

func get_asset(asset_id):
	return assets_by_id.get(asset_id, {})

func get_job(job_id):
	return jobs_by_id.get(job_id, {})

func get_item(item_id):
	return items_by_id.get(item_id, {})

func get_ending(ending_id):
	return endings_by_id.get(ending_id, {})

func _index_by_id(rows):
	var indexed: Dictionary = {}
	for row in rows:
		indexed[row.get("id", "")] = row
	return indexed

func _load_array(path):
	var parsed = _parse_json(path)
	if parsed is Array:
		return parsed
	if parsed is Dictionary and parsed.has("items"):
		return parsed["items"]
	push_warning("Expected JSON array at %s" % path)
	return []

func _load_dict(path):
	var parsed = _parse_json(path)
	if parsed is Dictionary:
		return parsed
	push_warning("Expected JSON object at %s" % path)
	return {}

func _parse_json(path):
	if not FileAccess.file_exists(path):
		push_warning("Missing content file: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_warning("Invalid JSON file: %s" % path)
	return parsed
