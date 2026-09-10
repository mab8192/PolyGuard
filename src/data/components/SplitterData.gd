class_name SplitterData extends Resource

@export var number_of_copies: int = 2 ## Number of smaller child entities spawned upon death
@export var max_splits: int = 1 ## Maximum recursion split depth allowed for spawned children
@export var health_multiplier: float = 0.5 ## Multiplier applied to child entity max health relative to parent
@export var armor_multiplier: float = 0.5 ## Multiplier applied to child entity armor relative to parent
@export var magic_resistance_multiplier: float = 0.5 ## Multiplier applied to child entity magic resistance relative to parent
@export var lives_penalty_override: int = 1 ## What to set the lives penalty to for the split copies
@export var energy_reward_override: int = 5 ## Bounty paid when a child copy is killed (parent keeps its own bounty)

var depth: int = 0 ## Current split generation depth of this specific entity instance
