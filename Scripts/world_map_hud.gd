extends CanvasLayer

@onready var stage_label = $TopHUD/StageLabel

func _ready():
	clear_info()

func update_stage_info(stage_name: String):
	if stage_label:
		stage_label.text = stage_name

func clear_info():
	if stage_label:
		stage_label.text = ""
