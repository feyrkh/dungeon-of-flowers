extends Node

signal uncovered_map_tile(map_x, map_y, tile_type)
signal update_minimap() # redraw dirty quadrants
signal new_player_location(map_x, map_y, rot_deg)
