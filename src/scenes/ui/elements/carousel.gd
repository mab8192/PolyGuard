class_name Carousel extends Control

signal item_selected(item: Variant)

@onready var left_button: Button = %LeftButton
@onready var items_container: MarginContainer = %ItemsContainer
@onready var right_button: Button = %RightButton

const ITEM_SCENE = preload("res://src/scenes/ui/elements/carousel_item.tscn")

var _index: int = 0
var _items: Array[CarouselItem] = []

## Set the carousel items. Dictionary should have keys "image" and "text"
func set_items(items: Array[Dictionary]) -> void:
	for item in items_container.get_children():
		item.queue_free()
	
	for item in items:
		var new_item = _create_item(item)
		_items.append(new_item)
	
	_show_selected_item()

func _ready() -> void:
	left_button.pressed.connect(_on_left_pressed)
	right_button.pressed.connect(_on_right_pressed)
	
	for item in items_container.get_children():
		if item is CarouselItem:
			_items.append(item)

	_show_selected_item()

func _on_left_pressed() -> void:
	if _items.is_empty(): return
	_index -= 1
	_index = clamp(_index, 0, _items.size() - 1)
	_show_selected_item()

func _on_right_pressed() -> void:
	if _items.is_empty(): return
	_index += 1 
	_index = clamp(_index, 0, _items.size() - 1)
	_show_selected_item()

func _show_selected_item() -> void:
	for i in range(_items.size()):
		if i == _index:
			_items[i].show()
		else:
			_items[i].hide()

func _create_item(data: Dictionary) -> CarouselItem:
	var item = ITEM_SCENE.instantiate() as CarouselItem
	item.texture = data["image"]
	item.text = data["text"]
	item.payload = data["payload"]
	item.pressed.connect(_on_item_pressed)
	
	items_container.add_child(item)

	return item

func _on_item_pressed(payload: Variant) -> void:
	item_selected.emit(payload)
