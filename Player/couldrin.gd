extends StaticBody3D

var ingredients: Array = []
@onready var label = $Label3D
@onready var soup = $Soup
var counted_ingredients: Dictionary = {}

@onready var crafting_menu = $CraftingMenu
@onready var itemlist = $CraftingMenu/ItemList

var iscraftingmenuopened: bool = false

var recipes = {
	"Bread": { "Wheat": 2 },
	"Fruit Bread": { "Wheat": 2, "Apple": 1},
	"Cake":  { "Wheat": 3, "Egg": 1 },
}


func _ready() -> void:
	crafting_menu.hide()
	$Soup.hide()

func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("craft"):
		openclosecraftingmenu()

func _on_area_body_entered(body: Node3D) -> void: 
	if body.is_in_group("veggie"):
		$Soup.show()
		ingredients.append(body.get_groups()[0])
		body.queue_free()
		label.text += str(" ", body.get_groups()[0], ",")

func labelprintingfromingredients(ing : Array) -> void:
	label.text = ""
	for i in ing:
		label.text = i + ", "

func count_ingredients(list: Array) -> Dictionary:
	var counts: Dictionary = {}
	for item in list:
		counts[item] = counts.get(item, 0) + 1
	return counts

func craftablestuff(ingredient_list: Array) -> Dictionary:
	var counts: Dictionary = count_ingredients(ingredient_list)
	var output: Dictionary = {}
	
	for product in recipes:
		var recipe: Dictionary = recipes[product]
		var max_possible := -1
		var can_craft := true
		
		for ing in recipe:
			var available: int = counts.get(ing, 0)
			var required: int = recipe[ing]
			
			if available < required:
				can_craft = false
				break
			
			var possible := available / required
			max_possible = possible if max_possible == -1 else mini(max_possible, possible)
			
		if can_craft and max_possible > 0:
			output[product] = max_possible
	
	return output

func openclosecraftingmenu() -> void:
	if iscraftingmenuopened:
		crafting_menu.hide()
		iscraftingmenuopened = false
		Global.canmove = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	else: 
		crafting_menu.show()
		iscraftingmenuopened = true
		Global.canmove = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		handleitemlist()

func handleitemlist() -> void:
	var craftables = craftablestuff(ingredients).keys()
	for i in itemlist.item_count:
		
		if itemlist.get_item_text(i) in craftables:
			
			itemlist.set_item_disabled(i, false)
		else:
			itemlist.set_item_disabled(i, true)

func yeetitem(itemdescription: String):
	var propername = itemdescription.replace(" ", "_")
	var path := "res://Assets/%s/%s.tscn" % [propername, propername]
	print(path)
	if not ResourceLoader.exists(path):
		push_error("Scene not found: " + path)
		return
	
	var scene := load(path) as PackedScene
	var instance := scene.instantiate() as RigidBody3D
	instance.global_transform = $Marker3D.global_transform
	get_tree().current_scene.add_child(instance)

func _craft(index: int, _at_position: Vector2, _mouse_button_index: int) -> void: #This function is connected to itemlsist items
	var nameofitemcrafted = itemlist.get_item_text(index)
	print(nameofitemcrafted)
	var ingredientsrequiredforit: Dictionary = recipes[nameofitemcrafted]
	var ingredientkey = ingredientsrequiredforit.keys()
	var ingredientval = ingredientsrequiredforit.values()
	
	for i in len(ingredientkey): # For which ingredient this loop is running
		for j in ingredientval[i]: # how many times does the ingredient exist in the dict
			for k in len(ingredients): #Logic for removing the said ingredient from ingredient list
				if ingredients[k] == ingredientkey[i]:
					ingredients.pop_at(k)
					break
	
	labelprintingfromingredients(ingredients)
	yeetitem(nameofitemcrafted)
	handleitemlist()
