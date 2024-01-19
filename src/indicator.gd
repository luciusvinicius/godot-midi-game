extends Sprite2D

var _spawner_ref
var _projectile_duration
var _projectile_channel
var menu_bullet


func set_vars(spawn_ref, new_duration: int, channel : int, is_menu:bool):
	_spawner_ref = spawn_ref
	_projectile_duration = new_duration
	_projectile_channel = channel
	menu_bullet = is_menu


func _on_animation_player_animation_finished(_anim_name:StringName):
	if _spawner_ref:
		_spawner_ref.shoot(_projectile_duration, _projectile_channel, menu_bullet)
		queue_free()
