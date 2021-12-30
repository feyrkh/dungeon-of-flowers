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
signal damage_all_allies(damage) # for stuff like party-wide trap damage
signal check_explore_gameover()

# party chat
signal start_chat(chat_filename)
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

# Grias levelup screen
signal grias_pre_save_levelup()
signal grias_post_load_levelup()
signal grias_exit_component_mode()
signal grias_generate_energy(core_node)
signal grias_compress_energy(spark)
signal grias_component_description(text)
signal grias_component_menu_text(text)
signal grias_component_cost(cost_map)
signal grias_component_refund(cost_map)
signal grias_destroy_node(node, map_coords, refund_map)
signal grias_component_change(change_type, cost_map, args)
signal grias_component_hide_main_arrow()
signal grias_levelup_clear_fog(map_position, fog_color)
signal grias_levelup_fail_clear_fog(map_position, fog_color)
signal grias_levelup_major_component_upgrade(fog_color)
signal grias_levelup_component_input_capture(component)
signal grias_levelup_component_input_release()
signal grias_reset_focus_power_cache()
signal grias_apply_levelup_bonuses()
