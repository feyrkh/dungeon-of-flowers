extends Node

const INTERRUPT_IF_BUSY = "0"
const QUEUE_IF_BUSY = "1"
const SKIP_IF_BUSY = "2"

var chat_queue = []
var cur_speaker = ''
var cur_line_timer = 0

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

var interrupt_lines = {
	"e": ["Hold a moment, {p}.", "Apologies {p}, please allow me to interrupt."],
	"a": ["hey {p}, shut up for a second!", "hsst! hold up, {p}!"],
	"g": ["Pardon, {p}...", "Hold that thought {p}..."],
}

var self_interrupt_lines = {
	"e": ["...just a tick, something important came up."],
	"a": ["...whoa, hold up."],
	"g": ["...wait, what's that?"],
}

var self_resume_lines = {
	"e": ["Now, where was I?", "Resuming our former conversation..."],
	"a": ["anyway, like ARUM THE TITAN was saying...", "what was ARUM talking about? oh yeah!"],
	"g": ["Anyway...", "As I was saying..."],
}

var resume_lines = {
	"e": ["If you are quite finished, {n}? I believe I was saying..."],
	"a": ["as ARUM was saying before being so rudely interrupted...", "...k. anyway..."],
	"g": ["Was that all, {n}?", "Thanks, {n}. As I was saying. before.."],
}

func _ready():
	EventBus.connect("start_chat", self, "start_chat")

func _process(delta):
	cur_line_timer -= delta
	if cur_line_timer <= 0:
		chat_queue.pop_front()
		send_chat_msg()

func start_chat(chat_filename, priority):
	chat_filename = "res://data/chat/"+chat_filename+".txt"
	set_process(true)
	var lines = Util.read_lines(chat_filename, [])
	if lines.size() == 0:
		return
	if chat_queue.size() == 0:
		append_file(lines)
	elif priority == SKIP_IF_BUSY:
		return
	elif priority == QUEUE_IF_BUSY:
		append_line("pause:4")
		append_file(lines)
	elif priority == INTERRUPT_IF_BUSY:
		var next_speaker = lines[0].split(":")[0]
		while next_speaker == 'pause':
			lines.remove(0)
			if lines.size() == 0:
				return
			next_speaker = lines[0].split(":")[0]
		prepend_line(resume_line(cur_speaker, next_speaker))
		prepend_file(lines)
		prepend_line(interrupt_line(cur_speaker, next_speaker))
		send_chat_msg()
	if chat_queue.size() > 0 and cur_line_timer <= 0:
		cur_line_timer = calculate_line_timer()
	send_chat_msg()

func send_chat_msg():
	if chat_queue.size() == 0:
		set_process(false)
		EventBus.emit_signal("chat_msg", "")
		return
	var chunks = chat_queue[0].split(":")
	if chunks[0] == "pause":
		cur_line_timer = float(chunks[1])
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
	var vals = {"p":interrupted_nickname(interrupt_speaker, prev_speaker), "n":interrupted_nickname(prev_speaker, interrupt_speaker)}
	if prev_speaker == interrupt_speaker:
		var lines = self_interrupt_lines[interrupt_speaker]
		return interrupt_speaker+":"+lines[randi()%lines.size()]
	else:
		var lines = interrupt_lines[interrupt_speaker]
		return interrupt_speaker+":"+lines[randi()%lines.size()]%vals

func resume_line(prev_speaker, interrupt_speaker):
	var vals = {"p":interrupted_nickname(interrupt_speaker, prev_speaker), "n":interrupted_nickname(prev_speaker, interrupt_speaker)}
	if prev_speaker == interrupt_speaker:
		var lines = self_resume_lines[prev_speaker]
		return interrupt_speaker+":"+lines[randi()%lines.size()]
	else:
		var lines = resume_lines[prev_speaker]
		return interrupt_speaker+":"+lines[randi()%lines.size()]%vals

func interrupted_nickname(prev_speaker, interrupt_speaker):
	var prev_name = nicknames.get(interrupt_speaker, {}).get(prev_speaker, ["Hey"])
	prev_name = prev_name[randi()%prev_name.size()]
