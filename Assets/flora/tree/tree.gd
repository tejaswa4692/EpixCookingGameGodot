extends StaticBody3D

@export var apil = preload("res://Assets/Apple/Apple.tscn")


func trigger():
	$ApilContainer.rotation.y = randi_range(0, 360)
	for i in $ApilContainer.get_children():
		var apilinstance = apil.instantiate()
		apilinstance.global_position = i.global_position
		get_parent().add_child(apilinstance)
