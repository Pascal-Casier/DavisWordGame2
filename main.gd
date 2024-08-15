extends Control

@onready var category_1: Button = %Category1
@onready var category_2: Button = %Category2
@onready var category_3: Button = %Category3
@onready var category_4: Button = %Category4
@onready var category_5: Button = %Category5
@onready var option_button: OptionButton = %OptionButton

var training : bool = false

var categories = {
	"ecole": ["cahier", "cartable", "chaise", "ciseaux", "colle", "crayon", "gomme", "pinceau", "regle", "table", "tableau", "taille"],
	"corps": ["tête", "bras", "jambe", "pied"],
	"animaux": ["chat", "chien", "oiseau", "poisson"],
	"fruits": ["pomme", "banane", "orange", "raisin"],
	"couleurs": ["rouge", "bleu", "vert", "jaune", "orange", "violet", "rose", "noir", "blanc", "marron", "gris"],
	"chiffres": ["un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix"],
	"legumes": ["carotte", "tomate", "pomme de terre", "concombre", "brocoli", "chou", "poivron", "courgette", "épinard", "oignon"],
	"vetements": ["chapeau", "chemise", "pantalon", "robe", "jupe", "chaussures", "chaussettes", "manteau", "gants", "écharpe"],
	"maison": ["table", "chaise", "lit", "lampe", "livre", "fenêtre", "porte", "télévision", "réfrigérateur", "four"],
	"transports": ["voiture", "bus", "train", "avion", "bateau", "vélo", "moto", "camion", "hélicoptère", "tramway"],
	"jours": ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
}

var selected_category = ""
var current_word_index = 0
var score = 0
var shuffled_words = []

func _ready():
	# Connect buttons to functions
	category_1.pressed.connect(_on_category_selected.bind("ecole"))
	category_2.pressed.connect(_on_category_selected.bind("corps"))
	category_3.pressed.connect(_on_category_selected.bind("animaux"))
	category_4.pressed.connect(_on_category_selected.bind("fruits"))
	category_5.pressed.connect(_on_category_selected.bind("couleurs"))
	#$VBoxContainer/EcoleButton.connect("pressed", self, "_on_category_selected", ["ecole"])
	#$VBoxContainer/CorpsButton.connect("pressed", self, "_on_category_selected", ["corps"])
	# Connect other category buttons similarly...
	option_button.add_item("Jeu", 0)
	option_button.add_item("entrainement", 1)

func _on_category_selected(category):
	selected_category = category
	shuffled_words = categories[selected_category].duplicate()
	shuffled_words.shuffle()
	current_word_index = 0
	score = 0
	update_score()
	if !training:
		next_word()
		start_game()
	else:
		%Training.show()

func start_game():
	#%GridContainer.hide()
	%Game.show()
	current_word_index = 0
	score = 0
	shuffled_words = categories[selected_category].duplicate()
	shuffled_words.shuffle()
	update_score()
	next_word()

###################TEST#######################
var repeat_count = 2  # Nombre de répétitions pour chaque mot
var repeat_index = 0  # Compteur de répétitions pour le mot actuel
var total_words_proposed = 0  # Nombre total de mots proposés

func next_word():
	
	if current_word_index < shuffled_words.size():
		var word = shuffled_words[current_word_index]
		if repeat_index < repeat_count:
			play_audio(word)
			display_options(word)
			repeat_index += 1
			total_words_proposed += 1
		else:
			repeat_index = 0  # Réinitialise le compteur de répétitions
			current_word_index += 1  # Passe au mot suivant
			total_words_proposed += 1  # Incrémente le nombre total de mots proposés
			next_word()  # Appelle la fonction pour le mot suivant
	else:
		end_game()
		total_words_proposed = 0
		
##################TEST######################
#
#func next_word():
	#if current_word_index < shuffled_words.size():
		#var word = shuffled_words[current_word_index]
		#play_audio(word)
		#display_options(word)
		#current_word_index += 1
	#else:
		#end_game()

func play_audio(word):
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://audio/%s.mp3" % word)
	add_child(audio)
	audio.play()

func display_options(correct_word):
	var options = %Options
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	var words = categories[selected_category].duplicate()
	words.erase(correct_word)
	words.shuffle()
	#var shuffled_words = words.slice(0, 3)
	shuffled_words = words.slice(0, 3)
	shuffled_words.append(correct_word)
	shuffled_words.shuffle()

	for word in shuffled_words:
		var button = Button.new()
		button.icon = load("res://images/%s.png" % word)
		button.custom_minimum_size = Vector2(100, 100)
		button.expand_icon = true
		button.pressed.connect(_on_option_selected.bind(word, correct_word))
		#button.connect("pressed", self, "_on_option_selected", [word, correct_word])
		options.add_child(button)

	# Add replay button
	var replay_button = Button.new()
	replay_button.icon = load("res://icons/play.png")
	replay_button.pressed.connect(play_audio.bind(correct_word))
	#replay_button.connect("pressed", self, "play_audio", [correct_word])
	options.add_child(replay_button)

func _on_option_selected(selected_word, correct_word):
	if selected_word == correct_word:
		score += 1
		%AudioStreamPlayer.stream = load("res://sounds/correct.ogg")
		%AudioStreamPlayer.play()
	else:
		%AudioStreamPlayer.stream = load("res://sounds/incorrect.ogg")
		%AudioStreamPlayer.play()
	await get_tree().create_timer(1).timeout
	update_score()
	next_word()

func update_score():
	#var total_questions = shuffled_words.size()
	#var percentage = (score / total_questions) * 100
	#%Score.text = "Score : %d/%d (%.2f%%)" % [score, total_questions, percentage]
	%Score.text = "Score : %d/%d" % [score, total_words_proposed]

func end_game():
	%EndGame.show()
	%endLbl.text = "Jeu terminé ! Votre score est : %d/%d" % [score, total_words_proposed]


func _on_restart_button_pressed():
	start_game()
	%EndGame.hide()

func _on_menu_button_pressed():
	%Game.hide()
	%EndGame.hide()


func _on_option_button_item_selected(index: int) -> void:
	if index == 0:
		training = false
	elif index == 1:
		training = true
