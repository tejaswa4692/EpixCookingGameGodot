extends RigidBody3D

const MIN_HIT_FORCE = 0.3

func _on_body_entered(_body):
	if !$AudioStreamPlayer3D.playing:
		if linear_velocity.length() > MIN_HIT_FORCE:
			$AudioStreamPlayer3D.play()
