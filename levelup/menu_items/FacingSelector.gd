extends IconSelector


func setup(unused_1=[], unused_2=[], unused_3=[], cur_selected=0):
	.setup([null, null, null, null], [], [], cur_selected)

func select_next(dir=1):
	var child_count = Selections.get_child_count()
	selected_icon = Util.wrap_range(selected_icon+dir, child_count)
	update_arrow_pos()

func start_selecting():
	ComponentMenuArrow.visible = true
	select_next(0)

func update_options(cost_map, icon_id, is_selected):
	.update_options(cost_map, icon_id, is_selected)
	if is_selected:
		selected_icon = icon_id
