extends DisableMovementTile

onready var TileMetadata = find_node("TileMetadata", true, false)

func _ready():
	TileMetadata.find_node("CollisionShape").disabled = true
