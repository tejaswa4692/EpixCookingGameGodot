class_name Player extends CharacterBody3D

@export_range(1, 35, 1) var speed: float = 5 # m/s
@export_range(10, 400, 1) var acceleration: float = 20 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false
var iscraftingmenuopened: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity


var isanythingpickedup: bool = false
var pickedveggie := []

@onready var grabpoint: Marker3D = $Camera/GrabPoint
@onready var ray: RayCast3D = $Camera/RayCast3D
@onready var camera: Camera3D = $Camera
@onready var everyray: RayCast3D = $Camera/everythingray
@onready var invscene: Control = $Camera/Control/Inventory

func _ready() -> void:
	Global.canmove = true
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed(&"exit"): get_tree().quit()
	if Input.is_action_just_pressed("grab"):
		if ray.is_colliding():
			var collder = ray.get_collider()
			if !isanythingpickedup and (collder.is_in_group("veggie") or collder.is_in_group("edibles") or collder.is_in_group("pickableobjects")): #This is thingy picking logic
				var objectsinrange  = ray.get_collider()
				pickupobj(objectsinrange) #veggiepicking logic
		else:
			if isanythingpickedup:
				if len(pickedveggie) > 0:
					throwobject(pickedveggie[0])
	if Input.is_action_just_pressed("stash"):
		if isanythingpickedup:
			if len(pickedveggie) > 0:
				stash(pickedveggie[0])
				populateitemlist()
		
		if everyray.is_colliding():
			var collider = everyray.get_collider()
			if collider.is_in_group("triggerableobject"):
				collider.trigger()
	if Input.is_action_just_pressed("inventory"):
		inventorylogic()

func stash(item):    #RESPONSIBLE TO MAKE ITEMS GO IN INVENTORY LIST
	if len(Global.Inventory) <= 5:
		Global.Inventory.append(item.get_groups()[0])
		ray.remove_exception(item)
		item.queue_free()
		isanythingpickedup = false
		pickedveggie.pop_at(0)

func inventorylogic():  #RUNS WEHN INVENTORY OPEN BUTTON IS PRESSED
	invscene.visible = !invscene.visible
	if invscene.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.canmove = false
		populateitemlist()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Global.canmove = true
		
		

func populateitemlist() -> void:  #RUNS EVERYTIME YOU EITHER STASH OR OPEN INVENTORY IT FILLS THE INVENTORY WITH STUFF
	$Camera/Control/Inventory/ItemList.clear()
	
	for i in Global.Inventory:
		var path := "res://Assets/%s/%s.png" % [i, i] #REPLACE WITH i LATER
		var icon := load(path) as Texture2D
		$Camera/Control/Inventory/ItemList.add_item(i.replace("_", " "), icon)
	$Camera/Control/Inventory/ItemList.deselect_all()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"jump"): jumping = true
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

func pickupobj(pickedupobject: RigidBody3D) -> void:
	ray.add_exception(pickedupobject)
	isanythingpickedup = true
	pickedupobject.freeze = true
	pickedupobject.reparent(grabpoint)
	pickedveggie.append(pickedupobject)
	pickedupobject.global_position = grabpoint.global_position

func throwobject(item) -> void:
	ray.remove_exception(item)
	var location = (item.global_position - global_position).normalized()
	item.freeze = false
	isanythingpickedup = false
	item.reparent(get_tree().current_scene)
	item.global_position += location
	pickedveggie.pop_at(0)

func throwbjectwhenselectedfrominventory(item) -> void:
	
	get_tree().current_scene.add_child(item)
	item.global_position = grabpoint.global_position
	

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	if Global.canmove:
		camera.rotation.y -= look_dir.x * camera_sens * sens_mod
		camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if joypad_dir.length() > 0:
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod)
		look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	if Global.canmove:
		move_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backwards")
		var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
		var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
		walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
		return walk_vel
	else:
		move_dir = Vector2.ZERO
		var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
		var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
		walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
		return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() or is_on_ceiling_only() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func inventoryitemspawninhand(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if !isanythingpickedup:
		var name = $Camera/Control/Inventory/ItemList.get_item_text(index)
		print(name)
		var itempath = $Camera/Control/Inventory/ItemList.get_item_text(index)
		itempath = itempath.replace(" ", "_")
		
		for i in range(len(Global.Inventory)):
			if Global.Inventory[i] == itempath:
				Global.Inventory.pop_at(i)
				break
		
		
		populateitemlist()
		
		itempath = "res://Assets/%s/%s.tscn" % [itempath, itempath]
		var itemtospawn = load(itempath) as PackedScene
		var instance: Node = itemtospawn.instantiate()
		throwbjectwhenselectedfrominventory(instance)
		$Camera/Control/Inventory/ItemList.deselect_all()
		$Camera/Control/Inventory/ItemList.release_focus() #DO NOT REMOVE VERY IMPROTATANT (The theme makes it so that all focused items are invisible but still there)
