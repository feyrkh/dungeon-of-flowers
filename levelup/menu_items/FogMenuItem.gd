extends Label

func setup(fog_level):
	# fog_level = chaos1 - chaos4
	match fog_level:
		"chaos1":
			EventBus.emit_signal("grias_component_description", "A confused swirl of undirected energies, which are preventing Grias from focusing.\n\nDirecting a bit of focused energy here will impose order and possibly reveal energetic cores.")
		"chaos2":
			EventBus.emit_signal("grias_component_description", "A chaotic swirl of undirected energies, which are preventing Grias from focusing.\n\nDirecting a concentrated bit of energy here will impose order and possibly reveal energetic cores.")
		"chaos3":
			EventBus.emit_signal("grias_component_description", "A frenzied swirl of undirected energies, which are preventing Grias from focusing.\n\nDirecting a powerfully concentrated bit of energy here will impose order and possibly reveal energetic cores.")
		"chaos4":
			EventBus.emit_signal("grias_component_description", "An anarchic swirl of undirected energies, which are preventing Grias from focusing.\n\nDirecting an overwhelming amount of focused energy here will impose order and possibly reveal energetic cores.")
		"outside":
			EventBus.emit_signal("grias_component_description", "The outer boundary of Grias' body. Her internal energies can't penetrate this.")
		_:
			EventBus.emit_signal("grias_component_description", "Outside of Grias' body. Her internal energies can't reach here.")
