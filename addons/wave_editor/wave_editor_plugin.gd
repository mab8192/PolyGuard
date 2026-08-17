@tool
extends EditorPlugin

var editor_view: Control
var bottom_btn: Button

func _enter_tree() -> void:
	var WaveEditorScript = load("res://addons/wave_editor/wave_editor.gd")
	if WaveEditorScript:
		editor_view = WaveEditorScript.new()
		editor_view.custom_minimum_size = Vector2(0, 320)
		bottom_btn = add_control_to_bottom_panel(editor_view, "Wave Editor")
	
	add_tool_menu_item("Open Wave Editor", _on_open_wave_editor)

func _exit_tree() -> void:
	remove_tool_menu_item("Open Wave Editor")
	if editor_view:
		remove_control_from_bottom_panel(editor_view)
		editor_view.queue_free()
		editor_view = null

func _on_open_wave_editor() -> void:
	if editor_view and bottom_btn:
		make_bottom_panel_item_visible(editor_view)
