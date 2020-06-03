extends Node

# Port must be open in router settings
const PORT = 27015
const MAX_PLAYERS = 32

# Check your IP and change it here
var ip = "localhost"

# Preload a character and controllers
# Character is controlled by AI or a player
# A puppet controller represents other players on the network
onready var character_scene = preload("res://scenes/character.tscn")
onready var player_scene = preload("res://scenes/player.tscn")
onready var peer_scene = preload("res://scenes/peer.tscn")

func _ready():
	# Connect menu button events
	var _host_pressed = $display/menu/host.connect("pressed", self, "_on_host_pressed")
	var _connect_pressed = $display/menu/connect.connect("pressed", self, "_on_connect_pressed")
	var _quit_pressed = $display/menu/quit.connect("pressed", self, "_on_quit_pressed")
	
# When a Host button is pressed
func _on_host_pressed():
	# Connect network events
	var _peer_connected = get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	var _peer_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	# Set up an ENet instance
	var network = NetworkedMultiplayerENet.new()
	network.create_server(PORT, MAX_PLAYERS)
	get_tree().set_network_peer(network)
	# Create our player, 1 is a reference for a host/server
	create_player(1, false)
	# Hide a menu
	$display/menu.visible = false
	$display/output.text = ""

# When Connect button is pressed
func _on_connect_pressed():
	# Connect network events
	var _peer_connected = get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	var _peer_disconnected = get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	var _connected_to_server = get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	var _connection_failed = get_tree().connect("connection_failed", self, "_on_connection_failed")
	var _server_disconnected = get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	# Set up an ENet instance
	var network = NetworkedMultiplayerENet.new()
	network.create_client(ip, PORT)
	get_tree().set_network_peer(network)

func _on_quit_pressed():
	get_tree().quit()

func _on_peer_connected(id):
	create_player(id, true)

func _on_peer_disconnected(id):
	remove_player(id)

func _on_connected_to_server():
	var id = get_tree().get_network_unique_id()
	$display/output.text = "Connected! ID: " + str(id)
	# Hide a menu
	$display/menu.visible = false
	# Create a player
	create_player(id, false)

func _on_connection_failed():
	get_tree().set_network_peer(null)
	$display/output.text = "Connection failed"

func _on_server_disconnected():
	# If server disconnects just reload the game
	var _reloaded = get_tree().reload_current_scene()
	$display/output.text = "Server disconnected"

func create_player(id, is_peer):
	# Create a character with a player or a peer controller attached
	var controller : Controller
	if is_peer:
		controller = peer_scene.instance()
	else:
		controller = player_scene.instance()
	var character = character_scene.instance()
	character.add_child(controller)
	controller.name = "controller"
	# Set the character's name to a given network id for synchronization
	character.name = str(id)
	$characters.add_child(character)
	character.global_transform.origin = random_point(40, 20)
	controller.get_node("camera").current = !is_peer

func remove_player(id):
	var characters = $characters.get_children()
	for n in characters:
		if int(n.name) == id:
			n.get_node("controller").queue_free()
			n.queue_free()

func random_point(radius, height):
	randomize()
	return Vector3(rand_range(-radius, radius), height, rand_range(-radius, radius))
