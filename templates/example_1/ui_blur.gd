extends ColorRect

var blurValue = 0.0
var tween: Tween

func _on_visibility_changed() -> void :
    material.set_shader_parameter("lod", 0.0)
    if tween:
        if tween.is_valid():
            tween.kill()
    tween = get_tree().create_tween()
    tween.tween_property(material, "shader_parameter/lod", 1.25, 0.5)
