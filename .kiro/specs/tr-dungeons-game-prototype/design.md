# Design Document: TR-Dungeons Game Prototype

## Overview

The TR-Dungeons game prototype demonstrates a data-driven, automated approach to modernizing classic MUD games. The system extracts content from MajorMUD databases, stores it in PostgreSQL, generates GoDot scene files programmatically, and provides a 3D dungeon crawler experience with V Rising-style aesthetics.

The architecture follows a pipeline approach:
1. **Data Extraction**: MajorMUD Btrieve databases → CSV/JSON
2. **Data Storage**: PostgreSQL with schema-driven models
3. **Model Generation**: orb-schema-generator creates GDScript, Python, and TypeScript models
4. **Scene Generation**: Python script generates .tscn files from database data
5. **Game Runtime**: GoDot 4 renders 3D scenes with Synty assets
6. **Backend API**: AWS Lambda + API Gateway serve game data

This design prioritizes automation, version control, and minimal manual editor work.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        MajorMUD Source Data                      │
│                    (Btrieve Database Files)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Data Extraction Layer                         │
│              (Nightmare Redux / MMUD Explorer)                   │
│                    Outputs: CSV/JSON files                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PostgreSQL Database                         │
│         Tables: rooms, monsters, items, npcs, quests            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                ▼                         ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  orb-schema-generator    │  │   Scene Generator        │
│  - GDScript models       │  │   (Python Script)        │
│  - Python models         │  │   Reads DB → Writes      │
│  - TypeScript CDK        │  │   .tscn files            │
└──────────┬───────────────┘  └────────┬─────────────────┘
           │                           │
           ▼                           ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│   AWS Infrastructure     │  │   GoDot 4 Game Engine    │
│   - RDS PostgreSQL       │  │   - Loads .tscn scenes   │
│   - Lambda Functions     │  │   - Renders 3D with      │
│   - API Gateway          │  │     Synty assets         │
│   (Deployed via CDK)     │  │   - Player controls      │
└──────────┬───────────────┘  └────────┬─────────────────┘
           │                           │
           └───────────────┬───────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  Game Client    │
                  │  HTTP requests  │
                  │  to API Gateway │
                  └─────────────────┘
```

### Technology Stack

**Frontend (Game Client)**:
- GoDot 4.x (game engine)
- GDScript (primary language)
- Synty Studios POLYGON Dungeon Realms (3D assets)
- HTTPRequest node for API calls

**Backend (Game Server)**:
- AWS RDS PostgreSQL (game data storage)
- AWS Lambda (Python 3.11+, game logic)
- AWS API Gateway (REST endpoints)
- AWS CDK (Python, infrastructure as code)

**Development Tools**:
- orb-schema-generator (model generation)
- Nightmare Redux or MMUD Explorer (MajorMUD data extraction)
- Python 3.11+ (scene generator scripts)
- Git (version control)

**Deployment**:
- AWS ca-central-1 region
- GitHub Actions (CI/CD)
- Docker (Lambda container images)

## Components and Interfaces

### 1. Data Extraction Component

**Purpose**: Extract game data from MajorMUD Btrieve databases

**Tools**: Nightmare Redux or MMUD Explorer

**Inputs**:
- MajorMUD .DAT files (Btrieve format)
- Room database files
- Monster database files
- Item database files
- NPC database files

**Outputs**:
- `rooms.csv` - Room definitions
- `monsters.csv` - Monster definitions
- `items.csv` - Item definitions
- `npcs.csv` - NPC definitions

**CSV Schema Examples**:

```csv
# rooms.csv
room_id,name,description,room_type,level_range,exits
1,"Entrance Hall","A dimly lit stone hallway.","corridor",1-3,"north:2,east:3"
2,"Guard Room","Torches flicker on the walls.","chamber",1-3,"south:1,west:4"
```

```csv
# monsters.csv
monster_id,name,health,attack_damage,movement_speed,spawn_rooms
1,"Goblin Scout",30,5,3.5,"1,2,3"
2,"Skeleton Warrior",50,8,2.5,"4,5"
```

### 2. Database Schema Component

**Purpose**: Store game data in structured, queryable format

**Technology**: PostgreSQL 15+

**Schema Definition** (YAML for orb-schema-generator):

```yaml
# schemas/tables/Room.yml
name: Room
type: table
description: Dungeon room definition
fields:
  - name: room_id
    type: integer
    primary_key: true
  - name: name
    type: string
    max_length: 100
    required: true
  - name: description
    type: string
    max_length: 500
  - name: room_type
    type: string
    enum: [corridor, chamber, treasure, boss]
  - name: level_range
    type: string
  - name: exits
    type: json
    description: "Map of direction to room_id"
  - name: created_at
    type: timestamp
    default: now()
```

```yaml
# schemas/tables/Monster.yml
name: Monster
type: table
description: Enemy monster definition
fields:
  - name: monster_id
    type: integer
    primary_key: true
  - name: name
    type: string
    max_length: 100
    required: true
  - name: health
    type: integer
    required: true
  - name: attack_damage
    type: integer
    required: true
  - name: movement_speed
    type: float
    required: true
  - name: spawn_rooms
    type: json
    description: "Array of room_ids where this monster spawns"
```

**Relationships**:
- Rooms connect via `exits` JSON field
- Monsters reference rooms via `spawn_rooms` array
- Items can be in rooms or monster loot tables

### 3. Model Generation Component

**Purpose**: Generate type-safe data models from YAML schemas

**Tool**: orb-schema-generator

**Inputs**:
- YAML schema files in `schemas/tables/`

**Outputs**:

**GDScript Models** (for GoDot frontend):
```gdscript
# Generated: models/Room.gd
class_name Room
extends Resource

@export var room_id: int
@export var name: String
@export var description: String
@export var room_type: String
@export var level_range: String
@export var exits: Dictionary

func _init(data: Dictionary = {}):
    if data.has("roomId"):
        room_id = data["roomId"]
    if data.has("name"):
        name = data["name"]
    # ... etc

func to_dict() -> Dictionary:
    return {
        "roomId": room_id,
        "name": name,
        "description": description,
        "roomType": room_type,
        "levelRange": level_range,
        "exits": exits
    }

static func from_dict(data: Dictionary) -> Room:
    return Room.new(data)
```

**Python Models** (for Lambda backend):
```python
# Generated: models/room.py
from pydantic import BaseModel, Field
from typing import Dict, Optional
from datetime import datetime

class Room(BaseModel):
    room_id: int = Field(..., alias="roomId")
    name: str
    description: Optional[str] = None
    room_type: str = Field(..., alias="roomType")
    level_range: Optional[str] = Field(None, alias="levelRange")
    exits: Dict[str, int]
    created_at: Optional[datetime] = Field(None, alias="createdAt")
    
    class Config:
        populate_by_name = True
```

**TypeScript CDK** (for infrastructure):
```typescript
// Generated: cdk/constructs/RoomTable.ts
import * as cdk from 'aws-cdk-lib';
import * as rds from 'aws-cdk-lib/aws-rds';

export interface RoomTableProps {
  database: rds.DatabaseInstance;
}

export class RoomTable extends cdk.Construct {
  constructor(scope: cdk.Construct, id: string, props: RoomTableProps) {
    super(scope, id);
    // Table definition generated from schema
  }
}
```

### 4. Scene Generation Component

**Purpose**: Generate GoDot .tscn scene files from database data

**Technology**: Python 3.11+ script

**Inputs**:
- PostgreSQL database connection
- Asset mapping configuration (room_type → prefab paths)
- Synty asset paths

**Process**:
1. Query database for room data
2. For each room:
   - Create .tscn file structure
   - Map room_type to Asset_Pack prefabs
   - Place floor tiles, walls, corners
   - Add lighting nodes
   - Place monster spawn points
   - Configure collision shapes
3. Write .tscn text file

**Output Example**:
```
# Generated: scenes/rooms/room_001.tscn
[gd_scene load_steps=8 format=3]

[ext_resource type="PackedScene" path="res://assets/synty/floor_tile.tscn" id="1"]
[ext_resource type="PackedScene" path="res://assets/synty/wall_stone.tscn" id="2"]
[ext_resource type="Script" path="res://scripts/RoomController.gd" id="3"]

[node name="Room001" type="Node3D"]
script = ExtResource("3")
room_id = 1
room_name = "Entrance Hall"

[node name="Floor" type="Node3D" parent="."]

[node name="FloorTile001" parent="Floor" instance=ExtResource("1")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)

[node name="Walls" type="Node3D" parent="."]

[node name="WallNorth" parent="Walls" instance=ExtResource("2")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 5)

[node name="Lighting" type="Node3D" parent="."]

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="Lighting"]
transform = Transform3D(1, 0, 0, 0, -0.5, 0.866, 0, -0.866, -0.5, 0, 10, 0)
shadow_enabled = true

[node name="SpawnPoints" type="Node3D" parent="."]

[node name="MonsterSpawn001" type="Marker3D" parent="SpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0, 3)
```

**Asset Mapping Configuration**:
```yaml
# config/asset_mapping.yml
room_types:
  corridor:
    floor: "res://assets/synty/floor_stone_01.tscn"
    wall: "res://assets/synty/wall_stone_01.tscn"
    ceiling_height: 4.0
  chamber:
    floor: "res://assets/synty/floor_stone_02.tscn"
    wall: "res://assets/synty/wall_stone_02.tscn"
    ceiling_height: 5.0
  treasure:
    floor: "res://assets/synty/floor_ornate_01.tscn"
    wall: "res://assets/synty/wall_ornate_01.tscn"
    ceiling_height: 6.0
```

### 5. Game Engine Component

**Purpose**: Render 3D game world and handle player interaction

**Technology**: GoDot 4.x

**Architecture**: Single-scene application with dynamic room loading

**Memory Management Strategy**:
- Only the current room and adjacent rooms are loaded in memory
- Rooms are loaded/unloaded dynamically as the player moves
- This keeps memory usage low and allows for large dungeons

**Scene Structure**:
```
Main Scene (persistent)
├── Player (CharacterBody3D)
├── Camera3D (follows player)
├── WorldEnvironment (post-processing)
├── DirectionalLight3D (main lighting)
├── UILayer (HUD, health bars)
└── RoomManager (Node)
    ├── CurrentRoom (loaded .tscn)
    ├── AdjacentRooms (preloaded for smooth transitions)
    └── UnloadedRooms (freed from memory)
```

**Key Nodes**:
- `Player` (CharacterBody3D) - Player character with movement
- `Camera3D` - Fixed overhead camera
- `WorldEnvironment` - Post-processing effects
- `DirectionalLight3D` - Main scene lighting
- `RoomManager` - Handles dynamic room loading/unloading
- `UILayer` - Health bars, HUD elements

**Player Controller** (GDScript):
```gdscript
# scripts/Player/PlayerController.gd
extends CharacterBody3D

@export var movement_speed: float = 5.0
@export var attack_range: float = 2.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.8

var can_attack: bool = true

func _physics_process(delta: float) -> void:
    # WASD movement
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
    
    if direction:
        velocity.x = direction.x * movement_speed
        velocity.z = direction.z * movement_speed
    else:
        velocity.x = 0
        velocity.z = 0
    
    # Rotate to face mouse
    var mouse_pos = get_viewport().get_mouse_position()
    var camera = get_viewport().get_camera_3d()
    var from = camera.project_ray_origin(mouse_pos)
    var to = from + camera.project_ray_normal(mouse_pos) * 1000
    var plane = Plane(Vector3.UP, global_position.y)
    var intersection = plane.intersects_ray(from, to)
    if intersection:
        look_at(intersection, Vector3.UP)
    
    move_and_slide()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if can_attack:
                attack()

func attack() -> void:
    can_attack = false
    # Find nearest enemy in range
    var enemies = get_tree().get_nodes_in_group("enemies")
    var nearest_enemy = null
    var nearest_distance = attack_range
    
    for enemy in enemies:
        var distance = global_position.distance_to(enemy.global_position)
        if distance < nearest_distance:
            nearest_enemy = enemy
            nearest_distance = distance
    
    if nearest_enemy:
        nearest_enemy.take_damage(attack_damage)
    
    # Cooldown
    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
```

**Enemy AI** (GDScript):
```gdscript
# scripts/Combat/EnemyAI.gd
extends CharacterBody3D

@export var health: int = 30
@export var attack_damage: int = 5
@export var movement_speed: float = 3.0
@export var detection_range: float = 10.0
@export var attack_range: float = 1.5
@export var patrol_points: Array[Vector3] = []

enum State { PATROL, CHASE, ATTACK }
var current_state: State = State.PATROL
var current_patrol_index: int = 0
var player: CharacterBody3D = null
var attack_cooldown: float = 1.5
var can_attack: bool = true

func _ready() -> void:
    add_to_group("enemies")
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not player:
        return
    
    var distance_to_player = global_position.distance_to(player.global_position)
    
    # State transitions
    match current_state:
        State.PATROL:
            if distance_to_player < detection_range:
                current_state = State.CHASE
            else:
                patrol()
        State.CHASE:
            if distance_to_player < attack_range:
                current_state = State.ATTACK
            elif distance_to_player > detection_range * 1.5:
                current_state = State.PATROL
            else:
                chase_player()
        State.ATTACK:
            if distance_to_player > attack_range:
                current_state = State.CHASE
            else:
                attack_player()
    
    move_and_slide()

func patrol() -> void:
    if patrol_points.is_empty():
        return
    
    var target = patrol_points[current_patrol_index]
    var direction = (target - global_position).normalized()
    velocity = direction * movement_speed * 0.5
    
    if global_position.distance_to(target) < 0.5:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func chase_player() -> void:
    var direction = (player.global_position - global_position).normalized()
    velocity = direction * movement_speed
    look_at(player.global_position, Vector3.UP)

func attack_player() -> void:
    velocity = Vector3.ZERO
    look_at(player.global_position, Vector3.UP)
    
    if can_attack:
        player.take_damage(attack_damage)
        can_attack = false
        await get_tree().create_timer(attack_cooldown).timeout
        can_attack = true

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    queue_free()
```

**Camera Controller** (GDScript):
```gdscript
# scripts/Player/CameraController.gd
extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 15, 10)
@export var look_ahead: float = 2.0
@export var smoothing: float = 5.0

func _physics_process(delta: float) -> void:
    if not target:
        return
    
    var target_position = target.global_position + offset
    global_position = global_position.lerp(target_position, smoothing * delta)
    
    var look_at_position = target.global_position + target.velocity.normalized() * look_ahead
    look_at(look_at_position, Vector3.UP)
```

**Room Manager** (GDScript):
```gdscript
# scripts/World/RoomManager.gd
extends Node

@export var current_room_id: int = 1
@export var preload_distance: int = 1  # Load rooms within 1 connection

var loaded_rooms: Dictionary = {}  # room_id -> Node3D instance
var room_data: Dictionary = {}  # room_id -> Room model data
var room_connections: Dictionary = {}  # room_id -> {direction: room_id}

signal room_changed(new_room_id: int)

func _ready() -> void:
    # Load initial room data from API or local cache
    load_room_data()
    # Load starting room
    load_room(current_room_id)
    # Preload adjacent rooms
    preload_adjacent_rooms(current_room_id)

func load_room_data() -> void:
    """Load room metadata from API or local JSON"""
    # For prototype, load from local JSON file
    var file = FileAccess.open("res://data/rooms.json", FileAccess.READ)
    if file:
        var json = JSON.parse_string(file.get_as_text())
        for room in json:
            room_data[room["roomId"]] = room
            room_connections[room["roomId"]] = room["exits"]
        file.close()

func load_room(room_id: int) -> void:
    """Load a room scene into memory"""
    if loaded_rooms.has(room_id):
        return  # Already loaded
    
    var room_path = "res://scenes/rooms/room_%03d.tscn" % room_id
    var room_scene = load(room_path)
    if room_scene:
        var room_instance = room_scene.instantiate()
        add_child(room_instance)
        loaded_rooms[room_id] = room_instance
        print("Loaded room: ", room_id)

func unload_room(room_id: int) -> void:
    """Unload a room scene from memory"""
    if not loaded_rooms.has(room_id):
        return  # Not loaded
    
    var room_instance = loaded_rooms[room_id]
    room_instance.queue_free()
    loaded_rooms.erase(room_id)
    print("Unloaded room: ", room_id)

func preload_adjacent_rooms(room_id: int) -> void:
    """Preload rooms connected to the given room"""
    if not room_connections.has(room_id):
        return
    
    var exits = room_connections[room_id]
    for direction in exits:
        var adjacent_room_id = exits[direction]
        load_room(adjacent_room_id)

func unload_distant_rooms(current_room_id: int) -> void:
    """Unload rooms that are too far from current room"""
    var rooms_to_keep = [current_room_id]
    
    # Keep adjacent rooms
    if room_connections.has(current_room_id):
        var exits = room_connections[current_room_id]
        for direction in exits:
            rooms_to_keep.append(exits[direction])
    
    # Unload all other rooms
    for room_id in loaded_rooms.keys():
        if room_id not in rooms_to_keep:
            unload_room(room_id)

func change_room(new_room_id: int) -> void:
    """Handle player moving to a new room"""
    if new_room_id == current_room_id:
        return
    
    print("Changing room from ", current_room_id, " to ", new_room_id)
    
    # Load new room if not already loaded
    load_room(new_room_id)
    
    # Preload adjacent rooms
    preload_adjacent_rooms(new_room_id)
    
    # Unload distant rooms
    unload_distant_rooms(new_room_id)
    
    # Update current room
    current_room_id = new_room_id
    room_changed.emit(new_room_id)

func get_room_exit(room_id: int, direction: String) -> int:
    """Get the room ID in the given direction from the current room"""
    if not room_connections.has(room_id):
        return -1
    
    var exits = room_connections[room_id]
    if exits.has(direction):
        return exits[direction]
    
    return -1
```

**Room Transition Trigger** (GDScript):
```gdscript
# scripts/World/RoomTransition.gd
extends Area3D

@export var direction: String = "north"  # north, south, east, west
@export var target_room_id: int = -1

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        var room_manager = get_node("/root/Main/RoomManager")
        if target_room_id > 0:
            room_manager.change_room(target_room_id)
        else:
            # Auto-detect target room from current room's exits
            var current_room_id = room_manager.current_room_id
            var next_room_id = room_manager.get_room_exit(current_room_id, direction)
            if next_room_id > 0:
                room_manager.change_room(next_room_id)
```

### 6. Backend API Component

**Purpose**: Serve game data to GoDot client via REST API

**Technology**: AWS Lambda (Python) + API Gateway

**Endpoints**:

```
GET /rooms/{room_id}
GET /monsters/{monster_id}
GET /items/{item_id}
GET /rooms/{room_id}/monsters
POST /player/damage
POST /monster/{monster_id}/damage
```

**Lambda Function Example**:
```python
# lambda/get_room.py
import json
import os
from typing import Dict, Any
import psycopg2
from models.room import Room

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Get room data by ID"""
    room_id = event['pathParameters']['room_id']
    
    # Connect to RDS
    conn = psycopg2.connect(
        host=os.environ['DB_HOST'],
        database=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )
    
    cursor = conn.cursor()
    cursor.execute(
        "SELECT room_id, name, description, room_type, level_range, exits FROM rooms WHERE room_id = %s",
        (room_id,)
    )
    
    row = cursor.fetchone()
    if not row:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Room not found'})
        }
    
    room = Room(
        room_id=row[0],
        name=row[1],
        description=row[2],
        room_type=row[3],
        level_range=row[4],
        exits=row[5]
    )
    
    cursor.close()
    conn.close()
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': room.model_dump_json()
    }
```

**CDK Stack Definition**:
```python
# cdk/stacks/game_backend_stack.py
from aws_cdk import (
    Stack,
    aws_rds as rds,
    aws_lambda as lambda_,
    aws_apigateway as apigw,
    aws_ec2 as ec2,
)
from constructs import Construct

class GameBackendStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # VPC for RDS
        vpc = ec2.Vpc(self, "GameVPC", max_azs=2)
        
        # RDS PostgreSQL
        db = rds.DatabaseInstance(
            self, "GameDatabase",
            engine=rds.DatabaseInstanceEngine.postgres(
                version=rds.PostgresEngineVersion.VER_15
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.BURSTABLE3,
                ec2.InstanceSize.MICRO
            ),
            vpc=vpc,
            database_name="trdungeons",
            multi_az=False,
            allocated_storage=20,
            removal_policy=cdk.RemovalPolicy.DESTROY
        )
        
        # Lambda function
        get_room_fn = lambda_.Function(
            self, "GetRoomFunction",
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="get_room.handler",
            code=lambda_.Code.from_asset("lambda"),
            vpc=vpc,
            environment={
                "DB_HOST": db.db_instance_endpoint_address,
                "DB_NAME": "trdungeons",
                "DB_USER": "admin",
                "DB_PASSWORD": db.secret.secret_value_from_json("password").to_string()
            }
        )
        
        # Grant Lambda access to RDS
        db.connections.allow_from(get_room_fn, ec2.Port.tcp(5432))
        
        # API Gateway
        api = apigw.RestApi(self, "GameAPI",
            rest_api_name="TR-Dungeons API"
        )
        
        rooms = api.root.add_resource("rooms")
        room = rooms.add_resource("{room_id}")
        room.add_method("GET", apigw.LambdaIntegration(get_room_fn))
```

## Data Models

### Core Entities

**Room**:
- `room_id` (int, primary key)
- `name` (string, max 100 chars)
- `description` (string, max 500 chars)
- `room_type` (enum: corridor, chamber, treasure, boss)
- `level_range` (string, e.g., "1-3")
- `exits` (JSON, map of direction → room_id)
- `created_at` (timestamp)

**Monster**:
- `monster_id` (int, primary key)
- `name` (string, max 100 chars)
- `health` (int, > 0)
- `attack_damage` (int, > 0)
- `movement_speed` (float, > 0)
- `spawn_rooms` (JSON array of room_ids)
- `loot_table_id` (int, foreign key, nullable)

**Item**:
- `item_id` (int, primary key)
- `name` (string, max 100 chars)
- `item_type` (enum: weapon, armor, consumable, quest)
- `properties` (JSON, type-specific attributes)
- `rarity` (enum: common, uncommon, rare, epic, legendary)

**Player** (runtime only, not in DB for prototype):
- `health` (int, current/max)
- `position` (Vector3)
- `current_room_id` (int)
- `inventory` (Array of item_ids)

### Data Flow

**Startup Flow**:
1. GoDot loads main scene (persistent)
2. RoomManager loads room metadata (room connections, exits)
3. RoomManager loads starting room (room 1) scene
4. RoomManager preloads adjacent rooms (rooms connected to room 1)
5. Player spawns in room 1
6. Enemies spawn at designated Marker3D nodes in loaded rooms

**Runtime Flow - Room Transitions**:
1. Player approaches room exit (doorway/passage)
2. Player enters Area3D trigger zone
3. RoomTransition component detects player
4. RoomManager.change_room(new_room_id) is called
5. RoomManager loads new room if not already loaded
6. RoomManager preloads rooms adjacent to new room
7. RoomManager unloads rooms that are too far away (not current or adjacent)
8. Player position is updated to new room entrance
9. Camera follows player smoothly

**Runtime Flow - Combat**:
1. Combat occurs locally within loaded rooms (no API calls for prototype)
2. Enemy AI operates on enemies in currently loaded rooms only
3. Health changes are tracked in memory
4. Future: API calls for persistence, multiplayer state sync

**Data Generation Flow**:
1. Extract MajorMUD data → CSV files
2. Import CSV → PostgreSQL
3. Run orb-schema-generator → Generate models
4. Run scene generator script → Generate .tscn files for all rooms
5. Generate rooms.json metadata file (room connections, exits)
6. Commit .tscn files and rooms.json to Git
7. GoDot loads scenes dynamically at runtime via RoomManager

**Memory Management**:
- Maximum loaded rooms at any time: 1 (current) + N (adjacent) = typically 2-4 rooms
- For 5-room prototype: All rooms may stay loaded (small memory footprint)
- For larger dungeons: Dynamic loading/unloading keeps memory usage constant
- Enemies in unloaded rooms are freed from memory
- Room state (enemy health, loot) can be cached in RoomManager if needed


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Movement Direction Correctness

*For any* WASD key input, the Player_Character movement direction should correspond to the key pressed relative to the camera view (W=forward, A=left, S=backward, D=right).

**Validates: Requirements 1.1**

### Property 2: Camera Follow Consistency

*For any* Player_Character position, the Camera_Controller should maintain a fixed overhead angle (30-45 degrees) and follow the player position with the configured offset.

**Validates: Requirements 1.2, 4.4**

### Property 3: Collision Boundary Enforcement

*For any* collision boundary and movement direction, if the Player_Character is at the boundary, movement in the direction of the boundary should be prevented.

**Validates: Requirements 1.3, 5.4**

### Property 4: Mouse-Based Rotation

*For any* mouse cursor position, the Player_Character should rotate to face that position in world space.

**Validates: Requirements 1.4**

### Property 5: Movement Speed Consistency

*For any* movement input, the Player_Character velocity should remain within the range of 5-7 units per second.

**Validates: Requirements 1.5**

### Property 6: Attack Targeting Accuracy

*For any* configuration of enemies within attack range, clicking the attack button should target the nearest enemy.

**Validates: Requirements 2.1**

### Property 7: Damage Application Correctness

*For any* entity with health and any damage value, applying damage should reduce the entity's health by exactly the damage amount (applies to both player and enemies).

**Validates: Requirements 2.2, 3.5, 6.1, 6.2**

### Property 8: Death Triggers Removal

*For any* enemy, when its health reaches zero, it should be removed from the scene.

**Validates: Requirements 2.3**

### Property 9: Attack Range Indicator

*For any* enemy position, if the enemy is within attack range, a visual indicator should be displayed; if outside range, no indicator should be shown.

**Validates: Requirements 2.4**

### Property 10: Attack Cooldown Enforcement

*For any* sequence of attack attempts, the time between successful attacks should be at least 0.5 seconds and at most 1.0 seconds.

**Validates: Requirements 2.5**

### Property 11: AI State Transitions

*For any* enemy with patrol behavior, when the player enters detection range, the enemy should transition from PATROL to CHASE state; when the player moves within attack range, it should transition to ATTACK state.

**Validates: Requirements 3.1, 3.2, 3.4**

### Property 12: Chase Pathfinding

*For any* enemy in CHASE state and any player position, the enemy should move toward the player position using pathfinding.

**Validates: Requirements 3.3**

### Property 13: Dungeon Connectivity

*For any* two rooms in the Starter_Dungeon, there should exist a path of connected rooms allowing the player to navigate from one to the other.

**Validates: Requirements 5.5**

### Property 14: Room Structure Validity

*For any* dungeon room, it should contain floor tiles, wall sections, at least one light source, collision boundaries, and be constructed from modular Asset_Pack pieces.

**Validates: Requirements 5.2, 5.3, 5.4, 5.6**

### Property 15: Scene File Validity

*For any* generated scene file, it should be in .tscn text format, human-readable, Git-compatible, and loadable by the Game_Engine without errors.

**Validates: Requirements 5.7, 8.5, 10.1, 10.2, 10.3, 10.5**

### Property 16: Health Display Consistency

*For any* enemy with health, a health bar should be displayed above the enemy showing the current health value.

**Validates: Requirements 6.5**

### Property 17: Database Referential Integrity

*For any* foreign key relationship in the database, attempting to insert a record with an invalid foreign key should be rejected.

**Validates: Requirements 7.4**

### Property 18: Scene Generation Mapping

*For any* room_type value, the Generator_Script should map it to the corresponding Asset_Pack prefabs as defined in the asset mapping configuration.

**Validates: Requirements 8.3**

### Property 19: Enemy Spawn Placement

*For any* room with spawn data, the Generator_Script should place Enemy instances at the positions specified in the spawn data.

**Validates: Requirements 8.4**

### Property 20: Asset Material Assignment

*For any* imported Asset_Pack model, it should have materials with textures assigned.

**Validates: Requirements 9.2**

### Property 21: Asset Collision Configuration

*For any* Asset_Pack model, it should have collision shapes configured.

**Validates: Requirements 9.3**

### Property 22: Git Diff Visibility

*For any* modification to a Scene_File by the Generator_Script, the changes should be visible in Git diffs.

**Validates: Requirements 10.4**

### Property 23: Data Export Completeness

*For any* exported game entity (room, monster, item, NPC), the exported data should contain all required fields as defined in the schema.

**Validates: Requirements 11.2, 11.3, 11.4, 11.5**

### Property 24: Export Format Validity

*For any* output from the Data_Extraction_Tool, it should be valid CSV or JSON format that can be imported into the Database.

**Validates: Requirements 11.6**

### Property 25: Multi-Language Model Generation

*For any* YAML schema definition, orb_schema_generator should produce valid GDScript, Python, and TypeScript code with correct syntax.

**Validates: Requirements 12.2, 12.3, 12.4**

### Property 26: GDScript Serialization Methods

*For any* generated GDScript model, it should include to_dict() and from_dict() methods for serialization.

**Validates: Requirements 12.5**

### Property 27: Python Model Validation

*For any* generated Python Pydantic model, it should include validation logic for required fields and type constraints.

**Validates: Requirements 12.6**

### Property 28: Cross-Language Type Safety

*For any* YAML schema, the generated models in GDScript, Python, and TypeScript should have compatible type definitions (e.g., string→String→string, integer→int→number).

**Validates: Requirements 12.7**

### Property 29: API Response Format

*For any* API endpoint response, it should be valid JSON.

**Validates: Requirements 14.4**

### Property 30: API Schema Conformance (Round-Trip)

*For any* schema definition, if an object is serialized by the backend API and deserialized by the frontend, the resulting object should be equivalent to the original.

**Validates: Requirements 14.5**

### Property 31: API Authentication Enforcement

*For any* API endpoint, requests without valid authentication should be rejected with a 401 or 403 status code.

**Validates: Requirements 14.6**

### Property 32: HTTP Status Code Correctness

*For any* API request, the response should have an appropriate HTTP status code (200 for success, 404 for not found, 400 for bad request, 500 for server error).

**Validates: Requirements 14.7**

## Error Handling

### Player Errors

**Invalid Movement**:
- Attempting to move through walls → Movement blocked, no error message
- Attempting to move out of bounds → Movement blocked, no error message

**Invalid Combat**:
- Clicking attack with no enemies in range → No action, no error message
- Clicking attack during cooldown → No action, cooldown indicator shown

### System Errors

**Database Errors**:
- Connection failure → Log error, retry with exponential backoff
- Query timeout → Log error, return 504 Gateway Timeout
- Invalid data → Log error, return 400 Bad Request

**Scene Loading Errors**:
- Missing .tscn file → Log error, show error screen to player
- Corrupted .tscn file → Log error, attempt to regenerate from database
- Missing asset reference → Log warning, use placeholder asset

**API Errors**:
- Network timeout → Retry up to 3 times, then show error to player
- 500 Internal Server Error → Log error, show generic error message
- 404 Not Found → Log warning, handle gracefully (e.g., room doesn't exist)

### Data Extraction Errors

**MajorMUD Database Errors**:
- Corrupted Btrieve file → Log error, skip corrupted records, continue extraction
- Missing required fields → Log warning, use default values where possible
- Invalid data types → Log error, skip invalid records

**CSV/JSON Export Errors**:
- Write permission denied → Log error, fail extraction with clear message
- Disk space full → Log error, fail extraction with clear message
- Invalid characters in data → Sanitize data, log warning

### Code Generation Errors

**orb-schema-generator Errors**:
- Invalid YAML syntax → Fail with clear error message pointing to line number
- Missing required fields in schema → Fail with validation error
- Unsupported type → Fail with error message listing supported types

**Scene Generator Errors**:
- Missing asset mapping → Log error, use default asset
- Invalid room_type → Log error, skip room generation
- Database query failure → Log error, fail generation with clear message

## Testing Strategy

### Dual Testing Approach

This project requires both **unit tests** and **property-based tests** for comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs
- Both are complementary and necessary

### Unit Testing

**Focus Areas**:
- Specific examples demonstrating correct behavior
- Integration points between components
- Edge cases (e.g., zero health, empty room, no enemies)
- Error conditions (e.g., missing files, network failures)

**Example Unit Tests**:
```gdscript
# test_player_movement.gd
func test_player_moves_forward_on_w_key():
    var player = Player.new()
    var initial_position = player.global_position
    player.handle_input("W", 1.0)  # 1 second of movement
    assert(player.global_position.z < initial_position.z, "Player should move forward")

func test_player_stops_at_wall():
    var player = Player.new()
    player.global_position = Vector3(0, 0, 0)
    var wall = StaticBody3D.new()
    wall.global_position = Vector3(0, 0, 1)
    player.handle_input("S", 1.0)
    assert(player.global_position.z < 1.0, "Player should not move through wall")
```

**Python Unit Tests**:
```python
# test_scene_generator.py
def test_generate_corridor_room():
    """Test that corridor rooms use correct assets"""
    generator = SceneGenerator()
    scene = generator.generate_room(room_type="corridor")
    assert "floor_stone_01" in scene
    assert "wall_stone_01" in scene

def test_generate_room_with_enemies():
    """Test that enemies are placed at spawn points"""
    generator = SceneGenerator()
    spawn_data = [{"monster_id": 1, "position": [3, 0, 3]}]
    scene = generator.generate_room(room_type="chamber", spawns=spawn_data)
    assert "MonsterSpawn001" in scene
    assert "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0, 3)" in scene
```

### Property-Based Testing

**Configuration**:
- Use **fast-check** for GDScript/TypeScript (via GDScript test framework)
- Use **Hypothesis** for Python
- Minimum **100 iterations** per property test
- Each test must reference its design document property

**Tag Format**:
```gdscript
# Feature: tr-dungeons-game-prototype, Property 1: Movement Direction Correctness
```

**Example Property Tests**:

```gdscript
# test_movement_properties.gd
# Feature: tr-dungeons-game-prototype, Property 1: Movement Direction Correctness
func test_property_movement_direction_correctness():
    var player = Player.new()
    var test_cases = [
        ["W", Vector3(0, 0, -1)],  # Forward
        ["A", Vector3(-1, 0, 0)],  # Left
        ["S", Vector3(0, 0, 1)],   # Backward
        ["D", Vector3(1, 0, 0)]    # Right
    ]
    
    for case in test_cases:
        var key = case[0]
        var expected_direction = case[1]
        player.global_position = Vector3.ZERO
        player.handle_input(key, 1.0)
        var actual_direction = (player.global_position - Vector3.ZERO).normalized()
        assert(actual_direction.is_equal_approx(expected_direction), 
               "Movement direction should match key input")

# Feature: tr-dungeons-game-prototype, Property 7: Damage Application Correctness
func test_property_damage_application():
    for i in range(100):  # 100 iterations
        var initial_health = randi() % 100 + 1  # Random health 1-100
        var damage = randi() % 50 + 1  # Random damage 1-50
        
        var entity = CharacterBody3D.new()
        entity.health = initial_health
        entity.take_damage(damage)
        
        var expected_health = max(0, initial_health - damage)
        assert(entity.health == expected_health, 
               "Health should decrease by exactly the damage amount")
```

**Python Property Tests**:
```python
# test_scene_generator_properties.py
from hypothesis import given, strategies as st
import hypothesis

# Feature: tr-dungeons-game-prototype, Property 18: Scene Generation Mapping
@given(room_type=st.sampled_from(["corridor", "chamber", "treasure", "boss"]))
@hypothesis.settings(max_examples=100)
def test_property_scene_generation_mapping(room_type):
    """For any room_type, the generator should map to correct assets"""
    generator = SceneGenerator()
    scene = generator.generate_room(room_type=room_type)
    
    # Verify correct asset mapping
    asset_mapping = generator.get_asset_mapping()
    expected_floor = asset_mapping[room_type]["floor"]
    expected_wall = asset_mapping[room_type]["wall"]
    
    assert expected_floor in scene
    assert expected_wall in scene

# Feature: tr-dungeons-game-prototype, Property 30: API Schema Conformance (Round-Trip)
@given(
    room_id=st.integers(min_value=1, max_value=1000),
    name=st.text(min_size=1, max_size=100),
    room_type=st.sampled_from(["corridor", "chamber", "treasure", "boss"])
)
@hypothesis.settings(max_examples=100)
def test_property_api_schema_round_trip(room_id, name, room_type):
    """For any room data, serialization then deserialization should preserve the data"""
    from models.room import Room
    
    # Create room object
    original = Room(
        room_id=room_id,
        name=name,
        room_type=room_type,
        description="Test room",
        exits={"north": 2}
    )
    
    # Serialize to JSON (backend API)
    json_data = original.model_dump_json()
    
    # Deserialize (frontend)
    restored = Room.model_validate_json(json_data)
    
    # Verify equivalence
    assert restored.room_id == original.room_id
    assert restored.name == original.name
    assert restored.room_type == original.room_type
```

### Integration Testing

**Scenarios**:
1. **End-to-End Data Pipeline**:
   - Extract MajorMUD data → Import to PostgreSQL → Generate scenes → Load in GoDot
   - Verify: All 5 rooms load successfully, enemies spawn, player can navigate

2. **API Integration**:
   - Deploy CDK stack → Call API endpoints → Verify responses
   - Test: GET /rooms/{id}, GET /monsters/{id}, authentication

3. **Scene Generation**:
   - Generate scenes from database → Load in GoDot → Verify rendering
   - Test: All asset references resolve, collision works, lighting renders

### Test Organization

```
tests/
├── unit/
│   ├── gdscript/
│   │   ├── test_player_movement.gd
│   │   ├── test_enemy_ai.gd
│   │   └── test_combat_system.gd
│   └── python/
│       ├── test_scene_generator.py
│       ├── test_data_extraction.py
│       └── test_api_handlers.py
├── property/
│   ├── gdscript/
│   │   ├── test_movement_properties.gd
│   │   ├── test_combat_properties.gd
│   │   └── test_ai_properties.gd
│   └── python/
│       ├── test_scene_generator_properties.py
│       ├── test_api_properties.py
│       └── test_model_generation_properties.py
└── integration/
    ├── test_data_pipeline.py
    ├── test_api_integration.py
    └── test_scene_loading.gd
```

### Continuous Integration

**GitHub Actions Workflow**:
```yaml
name: TR-Dungeons Tests

on: [push, pull_request]

jobs:
  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt
      - run: pytest tests/unit/python tests/property/python
  
  test-gdscript:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: abarichello/godot-ci@v3
        with:
          godot-version: '4.2'
      - run: godot --headless --script tests/run_tests.gd
  
  test-integration:
    runs-on: ubuntu-latest
    needs: [test-python, test-gdscript]
    steps:
      - uses: actions/checkout@v3
      - run: pytest tests/integration/
```

### Test Coverage Goals

- **Unit Tests**: 80%+ code coverage
- **Property Tests**: All 32 properties implemented
- **Integration Tests**: All critical paths covered
- **Manual Testing**: Visual quality, performance, gameplay feel
