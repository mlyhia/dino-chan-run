extends Node

var stump_scene = preload("res://scenes/stump.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var barrel_scene = preload("res://scenes/barrel.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var obstacle_types := [stump_scene, rock_scene, barrel_scene]
var obstacle : Array
var bird_heights := [150, 390]

#variabel game
const dino_Start_pos := Vector2i(0, 324)
const cam_start_pos := Vector2i(590, 324)
var difficulty 
const max_difficulty : int = 2
var score  : int
const score_modifier : int = 10
var high_score : int
var speed : float
const start_speed : float = 10.0
const max_speed : int = 25
const speed_modifier : int = 5000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs 


#dipanggil ketika node masuk pertama kali
func _ready():
	screen_size = get_window().size
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	$gameOver.get_node("Button").pressed.connect(new_game)
	new_game()
	
	
func new_game():
	#reset variabel
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	#hapus rintangan
	for obs in obstacle:
		obs.queue_free()
	obstacle.clear() 

	#reset nodenya
	$dino.position = dino_Start_pos
	$dino.velocity = Vector2i(0,0)
	$Camera2D.position = cam_start_pos
	#$Camera2D.make_current()
	$ground.position = Vector2i(0,0)
	
	$hud.get_node("start label").show()
	$gameOver.hide()
func _process(delta):
	if game_running:
		#kecepatan dan sesuaikan kesulitan
		speed = start_speed + score / speed_modifier
		if speed > max_speed:
			speed = max_speed
		adjust_difficulty()
		
		generate_obs()
		
		#gerakkan dino dan kamera
		$dino.position.x += speed
		$Camera2D.position.x += speed
		
		
		#update score
		score += speed
		show_score()
		#update posisi tanah
		if $Camera2D.position.x - $ground.position.x > screen_size.x * 1.5:
			$ground.position.x += screen_size.x
			
		for obs in obstacle:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$hud.get_node("start label").hide()
func generate_obs():
	#ground obs
	if obstacle.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs 
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height  - (obs_height * obs_scale.y / 2) + -70
			if obs_type == rock_scene:
				obs_y -= 70 # Naikkan 40 pixel, bisa disesuaikan
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		#spawn burung
		if difficulty == max_difficulty:
			if (randi() % 2) == 0:
				#generate rintangan burung
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)
		
func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacle.append(obs)
	
func remove_obs(obs):
	obs.queue_free()
	obstacle.erase(obs)
	
func hit_obs(body):
	if body.name == "dino":
		game_over()
	
func show_score():
	$hud.get_node("score Label").text = "SCORE: " + str(score / score_modifier)
	
func check_high_score():
	if score > high_score:
		high_score = score
		$hud.get_node("high score label").text = "HIGH SCORE: " + str(high_score / score_modifier)

func adjust_difficulty():
	difficulty = score / speed_modifier
	if difficulty > max_difficulty:
		difficulty = max_difficulty

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$gameOver.show()
