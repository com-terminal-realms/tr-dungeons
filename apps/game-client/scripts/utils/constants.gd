## Global constants for Terminal Realms: Dungeons
extends Node

# Player stats
const PLAYER_MAX_HEALTH: int = 100
const PLAYER_MOVE_SPEED: float = 5.0
const PLAYER_ATTACK_DAMAGE: int = 10
const PLAYER_ATTACK_COOLDOWN: float = 1.0
const PLAYER_ATTACK_RANGE: float = 2.0

# Enemy stats
const ENEMY_MAX_HEALTH: int = 50
const ENEMY_MOVE_SPEED: float = 3.0
const ENEMY_ATTACK_DAMAGE: int = 5
const ENEMY_ATTACK_COOLDOWN: float = 1.5
const ENEMY_DETECTION_RANGE: float = 10.0
const ENEMY_ATTACK_RANGE: float = 2.0

# Camera settings
const CAMERA_ANGLE: float = 45.0  # degrees from horizontal
const CAMERA_DISTANCE: float = 15.0  # units from player
const CAMERA_HEIGHT: float = 10.0  # units above ground
const ZOOM_MIN: float = 10.0
const ZOOM_MAX: float = 20.0
const FOLLOW_SPEED: float = 5.0  # smoothing factor
const ZOOM_SPEED: float = 2.0

# Physics
const GRAVITY: float = 9.8

# Grid
const GRID_SIZE: float = 0.5  # Snap-to-grid size for room pieces
