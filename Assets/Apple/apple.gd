extends RigidBody3D

const MIN_HIT_FORCE = 0.01


func _on_body_entered(body: Node) -> void:
	print(linear_velocity.length())
	if !$AudioStreamPlayer3D.playing:
		if linear_velocity.length() > MIN_HIT_FORCE:
			$AudioStreamPlayer3D.play()
