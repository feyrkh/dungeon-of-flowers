extends Node

# exploration
signal uncovered_map_tile(map_x, map_y, tile_type)
signal update_minimap() # redraw dirty quadrants
signal new_player_location(map_x, map_y, rot_deg)
signal player_start_move()
signal player_start_turn()

# combat
signal cancel_submenu()
signal select_submenu_item(submenu, move_data)
signal ally_status_updated(ally_data)

# pause menu
signal game_paused
signal game_unpaused
signal disable_pause_menu
signal enable_pause_menu
