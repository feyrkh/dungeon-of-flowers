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

# map editing
signal map_tile_changed(layer, x, y, tile_id)

# exploration
signal uncovered_map_tile(map_x, map_y, tile_type)
signal update_minimap() # redraw dirty quadrants
signal hide_minimap()
signal show_minimap()
signal new_player_location(map_x, map_y, rot_deg)
signal player_start_move()
signal player_start_turn()
signal player_finish_move()
signal player_finish_turn()
signal update_interactable(interactables_list)
signal refresh_interactables()
signal refresh_perspective_sprites(global_facing)

# party chat
signal start_chat(chat_filename, priority) # priority: what happens to this chat if another chat is already running; "ignore", "queue", "override"
signal chat_msg(msg)


# pollen spawn/spread
signal spawn_pollen(coords)
signal enemy_levelup()

# combat
signal cancel_submenu()
signal select_submenu_item(submenu, move_data)
signal ally_status_updated(ally_data)
signal show_tutorial(tip_name, pause)
signal hide_tutorial()
signal acquire_item(item_name, amount)

# pause menu
signal game_paused
signal game_unpaused
signal disable_pause_menu
signal enable_pause_menu

# UI control scheme
signal control_scheme_changed(platform)
