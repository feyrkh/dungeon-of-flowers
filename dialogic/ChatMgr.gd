extends Node

const STEPS_BETWEEN_AMBIENT_CHAT = 10

const INTERRUPT_IF_BUSY = "0"
const QUEUE_IF_BUSY = "1"
const SKIP_IF_BUSY = "2"
var CHAT_DIR

const SAVE_ITEMS = ["chat_queue", "cur_speaker", "cur_line_timer", "chat_lock", 
	"cur_priority", "cur_replay_after", "ambient_chats", "steps_since_last_chat",
	"disabled_chats"]
const SAVE_PREFIX = "ChatM_"
func pre_save_game():
	Util.pre_save_game(self, SAVE_PREFIX, SAVE_ITEMS)

func post_load_game():
	Util.post_load_game(self, SAVE_PREFIX, SAVE_ITEMS)
	if is_chatting():
		send_chat_msg()

var chat_synonyms = {}

var chat_queue = []  # speech lines and commands that are currently queued for display
var cur_speaker = '' # nametag (like 'e') of character who is speaking the current line
var cur_line_timer = 0 # how many seconds the currently displayed line will remain displayed
var chat_lock = {} # map of chat ids to number of seconds before the chat can be played
var cur_priority
var cur_replay_after
var ambient_chats = []
var steps_since_last_chat = 0
var disabled_chats = {}

var nicknames = {
	"e": {
		"g": ["Grias", "Sir Grias"],
		"a": ["Arum", "Mr. The Titan"],
	},
	"g": {
		"e": ["Chin", "Echs"],
		"a": ["Arum", "Arrie"],
	},
	"a": {
		"e": ["echinacea", "chin-chin"],
		"g": ["grias", "gri-gri"],
	}
}

const interrupt_lines = {
	"e": ["Hold a moment, {p}.", "Apologies {p}, please allow me to interrupt."],
	"a": ["hey {p}, shut up for a second!", "hsst! hold up, {p}!"],
	"g": ["Pardon, {p}...", "Hold that thought {p}..."],
}

const self_interrupt_lines = {
	"e": ["...just a tick, something important came up."],
	"a": ["...whoa, hold up."],
	"g": ["...wait, what's that?"],
}

const self_resume_lines = {
	"e": ["Now, where was I?", "Resuming our former conversation..."],
	"a": ["anyway, like ARUM THE TITAN was saying...", "what was ARUM talking about? oh yeah!"],
	"g": ["Anyway...", "As I was saying..."],
}

const resume_lines = {
	"e": ["If you are quite finished, {n}? I believe I was saying..."],
	"a": ["as ARUM was saying before being so rudely interrupted...", "...k. anyway..."],
	"g": ["Was that all, {n}?", "Thanks, {n}. As I was saying before.."],
}

func _ready():
	EventBus.connect("start_chat", self, "start_chat")
	EventBus.connect("pre_save_game", self, "pre_save_game")
	EventBus.connect("post_load_game", self, "post_load_game")
	CombatMgr.connect("combat_start", self, "on_combat_start")
	CombatMgr.connect("combat_end", self, "on_combat_end")
	CombatMgr.connect("enemy_follower_dead", self, "on_enemy_dead")
	QuestMgr.connect("cutscene_start", self, "on_cutscene_start")
	QuestMgr.connect("cutscene_end", self, "on_cutscene_end")
	chat_queue = []
	cur_speaker = ''
	cur_line_timer = 0
	CHAT_DIR = Directory.new()
	CHAT_DIR.open("res://data/chat/")
	find_chat_synonyms()

func on_tile_move_complete():
	if is_chatting():
		return
	steps_since_last_chat += 1
	if steps_since_last_chat > STEPS_BETWEEN_AMBIENT_CHAT:
		var ambient_chat
		if randf() > 0.7:
			if ambient_chats.size() > 0:
				ambient_chat = find_valid_chat(ambient_chats[0])
				if ambient_chat != null:
					ambient_chats.remove(0)
				else:
					ambient_chats.shuffle()
		if ambient_chat != null:
			start_chat(ambient_chat)
		else:
			start_chat("idle")

func on_combat_start():
	EventBus.emit_signal("chat_msg", "")
	set_process(false)
	if chat_queue.size() > 0 and chat_queue[0].find(":") == 1:
		prepend_line(resume_line(cur_speaker, cur_speaker))
		prepend_line("pause:5")

func on_cutscene_start(_cutscene_name):
	EventBus.emit_signal("chat_msg", null) # make chat msgs disappear
	set_process(false)
	if chat_queue.size() > 0 and chat_queue[0].find(":") == 1:
		prepend_line(resume_line(cur_speaker, cur_speaker))
		prepend_line("pause:5")
	steps_since_last_chat = 0

func on_combat_end():
	set_process(true)

func on_cutscene_end(_cutscene_name):
	set_process(true)

func on_enemy_dead(enemy:Enemy):
	var kill_count = GameData.get_state("kills_"+enemy.data.label, 0)
	var chat_id = "kill_"+enemy.data.label+"_"+str(kill_count)
	add_ambient_chat(chat_id)

func add_ambient_chat(chat_id):
	if CHAT_DIR.file_exists(chat_id+".txt"):
		ambient_chats.append(chat_id)
		ambient_chats.shuffle()
	if chat_synonyms.has(chat_id):
		ambient_chats.append_array(chat_synonyms[chat_id])
		ambient_chats.shuffle()

func find_chat_synonyms():
	chat_synonyms = {}
	var dir = Directory.new()
	dir.open("res://data/chat")
	dir.list_dir_begin(true, true)
	var regex = RegEx.new()
	regex.compile("^((.+)-\\d+)\\.txt$")
	var filename = dir.get_next()
	while filename != "":
		var m = regex.search(filename)
		if m != null:
			var id = m.get_string(2)
			var synonym = m.get_string(1)
			if id != "":
				if !chat_synonyms.has(id):
					chat_synonyms[id] = []
				chat_synonyms[id].append(synonym)
		filename = dir.get_next()

func _process(delta):
	if CombatMgr.is_in_combat:
		set_process(false)
		return
	cur_line_timer -= delta
	if cur_line_timer <= 0:
		chat_queue.pop_front()
		send_chat_msg()

func is_chatting():
	return chat_queue.size() > 0

func find_valid_chat(chat_id, party_members={"g":1, "e":1, "a":1}):
	var chat_options:Array
	if chat_lock.get(chat_id, 0) > GameData.game_time:
		return null
	if chat_synonyms.has(chat_id):
		chat_options = chat_synonyms[chat_id].duplicate()
	else:
		chat_options = [chat_id]
	chat_options.shuffle()
	while chat_options.size() > 0:
		var invalid = false
		var cur_option = chat_options.pop_back()
		if disabled_chats.has(cur_option):
			invalid = true
			continue
		if chat_lock.get(cur_option, 0) > GameData.game_time:
			return null
		var lines = load_file(cur_option)
		for line in lines:
			var chunks = line.split(":")
			if chunks[0].length() == 1 and !party_members.get(chunks[0], false):
				invalid = true
				break
		if !invalid:
			return cur_option
		
func load_file(chat_id):
	var chat_filename = chat_id
	if !chat_filename.begins_with("res:"):
		chat_filename = "res://data/chat/"+chat_id+".txt"
	var lines = Util.read_lines(chat_filename, [])
	cur_priority = QUEUE_IF_BUSY
	cur_replay_after = -1
	while lines.size() > 0 and lines[0].begins_with("!"):
		process_config_line(lines[0], chat_id)
		lines.remove(0)
	return lines

func process_config_line(line, cur_file_name):
	var chunks = line.split(":")
	match chunks[0]:
		"!priority": 
			cur_priority = chunks[1]
		"!replay_after": # !replay_after:<delay in seconds>   ex: !replay_after:300
			cur_replay_after = float(chunks[1])
		"!no_repeat":
			disabled_chats[cur_file_name] = true
		"!ambient": # !ambient:<chat_id>[:<delay in seconds>]   ex: "!ambient:poetry1:300" or "!ambient:poetry1"
			if ambient_chats.find(chunks[1]) < 0:
				ambient_chats.append(chunks[1])
				if chunks.size() > 2:
					chat_lock[chunks[1]] = float(chunks[2]) + GameData.game_time
		_: 
			printerr("Unexpected chat config line: ", line)

func start_chat(chat_id):
	var chat_filename = find_valid_chat(chat_id, GameData.get_allies_in_party())
	if chat_filename == null:
		return
	steps_since_last_chat = 0
	set_process(true)
	var lines = load_file(chat_filename)
	if lines.size() == 0:
		return
	if chat_queue.size() == 0:
		append_file(lines)
		if cur_replay_after > 0:
			append_line("replay_after:"+chat_id+":"+str(cur_replay_after))
	elif cur_priority == SKIP_IF_BUSY:
		return
	elif cur_priority == INTERRUPT_IF_BUSY:
		var next_speaker = lines[0].split(":")[0]
		while next_speaker == 'pause':
			lines.remove(0)
			if lines.size() == 0:
				return
			next_speaker = lines[0].split(":")[0]
		if cur_replay_after > 0:
			prepend_line("replay_after:"+str(cur_replay_after))
		prepend_line(resume_line(cur_speaker, next_speaker))
		prepend_file(lines)
		prepend_line(interrupt_line(cur_speaker, next_speaker))
		send_chat_msg()
	else:
		append_line("pause:4")
		append_file(lines)
		if cur_replay_after > 0:
			append_line("replay_after:"+chat_id+":"+str(cur_replay_after))
	if chat_queue.size() > 0 and cur_line_timer <= 0:
		cur_line_timer = calculate_line_timer()
	send_chat_msg()

func send_chat_msg():
	if chat_queue.size() == 0:
		set_process(false)
		EventBus.emit_signal("chat_msg", "")
		return
	steps_since_last_chat = 0
	set_process(true)
	var chunks = chat_queue[0].split(":")
	if chunks[0] == "pause":
		cur_line_timer = float(chunks[1])
	elif chunks[0] == "replay_after":
		chat_lock[chunks[1]] = GameData.game_time+float(chunks[2])
	else:
		cur_speaker = chunks[0]
		cur_line_timer = calculate_line_timer()	
		EventBus.emit_signal("chat_msg", chat_queue[0])

func calculate_line_timer():
	if chat_queue.size() <= 0:
		return 1.0
	var num_words = chat_queue[0].count(' ')
	return GameData.get_setting("ChatM_min_chat_time", 2.0) + num_words * GameData.get_setting("ChatM_chat_time_per_word", 0.3)

func append_file(lines):
	for line in lines:
		if line != "":
			append_line(line)

func prepend_file(lines):
	lines.invert()
	for line in lines:
		if line != "":
			prepend_line(line)

func append_line(line):
	chat_queue.append(line)

func prepend_line(line):
	chat_queue.push_front(line)

func interrupt_line(prev_speaker, interrupt_speaker):
	var vals = {"n":interrupted_nickname(interrupt_speaker, prev_speaker), "p":interrupted_nickname(prev_speaker, interrupt_speaker)}
	if prev_speaker == interrupt_speaker:
		var lines = self_interrupt_lines[interrupt_speaker]
		return interrupt_speaker+":"+lines[randi()%lines.size()]
	else:
		var lines = interrupt_lines[interrupt_speaker]
		var line = interrupt_speaker+":"+lines[randi()%lines.size()]
		line = line.replace("{p}", vals.get("p"))
		line = line.replace("{n}", vals.get("n"))
		return line

func resume_line(prev_speaker, interrupt_speaker):
	var vals = {"n":interrupted_nickname(interrupt_speaker, prev_speaker), "p":interrupted_nickname(prev_speaker, interrupt_speaker)}
	if prev_speaker == interrupt_speaker:
		var lines = self_resume_lines[prev_speaker]
		return prev_speaker+":"+lines[randi()%lines.size()]
	else:
		var lines = resume_lines[prev_speaker]
		var line = prev_speaker+":"+lines[randi()%lines.size()]
		line = line.replace("{p}", vals.get("p"))
		line = line.replace("{n}", vals.get("n"))
		return line

func interrupted_nickname(prev_speaker, interrupt_speaker):
	var prev_name = nicknames.get(interrupt_speaker, {}).get(prev_speaker, ["Hey"])
	prev_name = prev_name[randi()%prev_name.size()]
	return prev_name
