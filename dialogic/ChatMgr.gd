extends Node

const INTERRUPT_IF_BUSY = "0"
const QUEUE_IF_BUSY = "1"
const SKIP_IF_BUSY = "2"

const SAVE_ITEMS = ["chat_queue", "cur_speaker", "cur_line_timer", "chat_lock", "cur_priority", "cur_replay_after"]
const SAVE_PREFIX = "ChatM_"
func pre_save_game():
	Util.pre_save_game(self, SAVE_PREFIX, SAVE_ITEMS)

func post_load_game():
	Util.post_load_game(self, SAVE_PREFIX, SAVE_ITEMS)
	if is_chatting():
		send_chat_msg()

var chat_synonyms = {}

var chat_queue = []
var cur_speaker = ''
var cur_line_timer = 0
var chat_lock = {}
var cur_priority
var cur_replay_after

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
	chat_queue = []
	cur_speaker = ''
	cur_line_timer = 0
	find_chat_synonyms()

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
	cur_line_timer -= delta
	if cur_line_timer <= 0:
		chat_queue.pop_front()
		send_chat_msg()

func is_chatting():
	return chat_queue.size() > 0

func find_valid_chat(chat_id, party_members={"g":1, "e":1, "a":1}):
	var chat_options:Array
	if chat_lock.get(chat_id, 0) > OS.get_system_time_secs():
		return null
	if chat_synonyms.has(chat_id):
		chat_options = chat_synonyms[chat_id].duplicate()
	else:
		chat_options = [chat_id]
	chat_options.shuffle()
	while chat_options.size() > 0:
		var invalid = false
		var cur_option = chat_options.pop_back()
		var lines = load_file(cur_option)
		for line in lines:
			var chunks = line.split(":")
			if chunks[0].length() == 1 and !party_members.get(chunks[0], false):
				invalid = true
				break
		if !invalid:
			return cur_option
		
func load_file(chat_filename):
	if !chat_filename.begins_with("res:"):
		chat_filename = "res://data/chat/"+chat_filename+".txt"
	var lines = Util.read_lines(chat_filename, [])
	cur_priority = QUEUE_IF_BUSY
	cur_replay_after = -1
	while lines.size() > 0 and lines[0].begins_with("!"):
		process_config_line(lines[0])
		lines.remove(0)
	return lines

func process_config_line(line):
	var chunks = line.split(":")
	match chunks[0]:
		"!priority": 
			cur_priority = chunks[1]
		"!replay_after": 
			cur_replay_after = float(chunks[1])
		_: 
			printerr("Unexpected chat config line: ", line)

func start_chat(chat_id):
	var chat_filename = find_valid_chat(chat_id, GameData.get_allies_in_party())
	if chat_filename == null:
		return
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
	set_process(true)
	var chunks = chat_queue[0].split(":")
	if chunks[0] == "pause":
		cur_line_timer = float(chunks[1])
	elif chunks[0] == "replay_after":
		chat_lock[chunks[1]] = OS.get_system_time_secs()+float(chunks[2])
	else:
		cur_speaker = chunks[0]
		cur_line_timer = calculate_line_timer()	
		EventBus.emit_signal("chat_msg", chat_queue[0])

func calculate_line_timer():
	return 2.0

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
