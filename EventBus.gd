extends Node

# save game handling
signal pre_new_game()
signal post_new_game()
signal finalize_new_game()
signal pre_save_game()
signal post_save_game()
signal pre_load_game()
signal post_load_game()
signal finalize_load_game()

# exploration
signal uncovered_map_tile(map_x, map_y, tile_type)
signal update_minimap() # redraw dirty quadrants
signal hide_minimap()
signal show_minimap()
signal new_player_location(map_x, map_y, rot_deg)
signal player_start_move()
signal player_start_turn()

# combat
signal cancel_submenu()
signal select_submenu_item(submenu, move_data)
signal ally_status_updated(ally_data)
signal show_tutorial(tip_name, pause)
signal hide_tutorial()

# pause menu
signal game_paused
signal game_unpaused
signal disable_pause_menu
signal enable_pause_menu

# UI control scheme
signal control_scheme_changed(platform)
