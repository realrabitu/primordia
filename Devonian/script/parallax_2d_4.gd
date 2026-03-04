extends Parallax2D

@onready var parallax_layer: ParallaxLayer = $ParallaxLayer
@onready var parallax_layer_2: ParallaxLayer = $ParallaxLayer2
@onready var parallax_layer_3: ParallaxLayer = $ParallaxLayer3
@onready var parallax_layer_4: ParallaxLayer = $ParallaxLayer4
@onready var parallax_layer_5: ParallaxLayer = $ParallaxLayer5

var scroll_speed:=70

func _process(delta: float) -> void:
	scroll_offset.x -= scroll_speed * delta
