extends Control

# Références aux boutons de catégorie et au bouton d'option
@onready var category_buttons = [
	%Category1,
	%Category2,
	%Category3,
	%Category4,
	%Category5
]
@onready var option_button: OptionButton = %OptionButton
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer  # Référence au nœud AudioStreamPlayer existant

var training : bool = false  # Mode d'entraînement ou de jeu

# Dictionnaire des catégories et des mots associés
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

var selected_category = ""  # Catégorie sélectionnée
var current_word_index = 0  # Index du mot actuel
var score = 0  # Score du joueur
var shuffled_words = []  # Liste des mots mélangés

func _ready():
	# Connecte les boutons de catégorie aux fonctions
	for i in range(category_buttons.size()):
		category_buttons[i].pressed.connect(_on_category_selected.bind(categories.keys()[i]))
	option_button.add_item("Jeu", 0)
	option_button.add_item("Entrainement", 1)

# Fonction appelée lorsqu'une catégorie est sélectionnée
func _on_category_selected(category):
	selected_category = category
	shuffled_words = categories[selected_category].duplicate()
	shuffled_words.shuffle()
	current_word_index = 0
	score = 0
	update_score()
	if !training:
		start_game()
	else:
		%Training.show()

# Démarre le jeu
func start_game():
	%Game.show()
	current_word_index = 0
	score = 0
	total_words_proposed = 0  # Réinitialise le nombre total de mots proposés
	shuffled_words = categories[selected_category].duplicate()
	shuffled_words.shuffle()
	update_score()
	next_word()

func _on_restart_button_pressed():
	start_game()
	%EndGame.hide()

func _on_menu_button_pressed():
	%Game.hide()
	%EndGame.hide()


var repeat_count = 1  # Nombre de répétitions pour chaque mot
var repeat_index = 0  # Compteur de répétitions pour le mot actuel
var total_words_proposed = 0  # Nombre total de mots proposés

# Passe au mot suivant
func next_word():
	if current_word_index < shuffled_words.size():
		var word = shuffled_words[current_word_index]
		if repeat_index < repeat_count:
			play_audio(word)
			display_options(word)
			repeat_index += 1
		else:
			repeat_index = 0
			current_word_index += 1
			next_word()
	else:
		end_game()

# Joue l'audio pour le mot donné
func play_audio(word):
	var audio_path = "res://audio/%s.mp3" % word
	var audio_stream = load(audio_path)
	
	if audio_stream:
		audio_player.stop()  # Arrête l'audio en cours
		audio_player.stream = audio_stream
		audio_player.play()
	else:
		print("Erreur : Fichier audio non trouvé pour le mot %s" % word)

# Affiche les options pour le mot correct
func display_options(correct_word):
	var options = %Options
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	var words = categories[selected_category].duplicate()
	words.erase(correct_word)
	words.shuffle()
	var shuffled_words = words.slice(0, 3)
	shuffled_words.append(correct_word)
	shuffled_words.shuffle()

	for word in shuffled_words:
		var button = Button.new()
		button.icon = load("res://images/%s.png" % word)
		button.custom_minimum_size = Vector2(100, 100)
		button.expand_icon = true
		button.pressed.connect(_on_option_selected.bind(word, correct_word))
		options.add_child(button)

	# Ajouter le bouton de replay
	var replay_button = Button.new()
	replay_button.icon = load("res://icons/play.png")
	replay_button.pressed.connect(play_audio.bind(correct_word))
	options.add_child(replay_button)

# Fonction appelée lorsqu'une option est sélectionnée
func _on_option_selected(selected_word, correct_word):
	if selected_word == correct_word:
		score += 1
		%AudioStreamPlayer.stream = load("res://sounds/correct.ogg")
		%AudioStreamPlayer.play()
	else:
		%AudioStreamPlayer.stream = load("res://sounds/incorrect.ogg")
		%AudioStreamPlayer.play()
	
	total_words_proposed += 1  # Incrémente le nombre total de mots proposés ici
	await get_tree().create_timer(1).timeout
	update_score()
	next_word()

# Met à jour le score affiché
func update_score():
	%Score.text = "Score : %d/%d" % [score, total_words_proposed]

# Termine le jeu
func end_game():
	%EndGame.show()
	%endLbl.text = "Jeu terminé ! Votre score est : %d/%d" % [score, total_words_proposed]


# Gère la sélection du mode de jeu
func _on_option_button_item_selected(index: int) -> void:
	if index == 0:
		training = false
	elif index == 1:
		training = true
