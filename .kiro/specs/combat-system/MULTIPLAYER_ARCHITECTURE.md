# Multiplayer Architecture Design

## Overview

This document describes the multiplayer-ready architecture for the TR-Dungeons combat system. While the initial implementation is single-player, the data models and architecture are designed to support future multiplayer features with minimal refactoring.

## Architecture Phases

### Phase 1: Single-Player (Current)
- All combat runs client-side in Godot
- Backend provides configuration data only (enemy types, loot tables, abilities)
- No real-time synchronization
- Local save/load for player progress

### Phase 2: Co-op PvE (Future)
- WebSocket connection for real-time room state
- Server tracks room instances and player sessions
- Batch updates for non-critical data (position, health)
- Immediate updates for critical events (death, loot, doors)
- Client-side prediction with server reconciliation

### Phase 3: PvP (Much Later)
- Full server-authoritative combat
- Client-side prediction with rollback
- Lag compensation for hit detection
- Anti-cheat validation

## Data Models

### Configuration Data (Static)
These models define game content and are fetched at game start:

- **CombatStats**: Base stats for entities (health, damage, speed, etc.)
- **EnemyType**: Enemy definitions with AI parameters
- **LootTable**: Loot drop configurations
- **Ability**: Ability definitions with costs and effects

**Storage**: DynamoDB tables (CombatStatsTable, EnemyTypesTable, LootTablesTable, AbilitiesTable)

**Access Pattern**: 
- Client fetches on game start
- Cached locally for offline play
- Updated when new content is released

### Session Data (Dynamic)
These models track active gameplay and are updated in real-time:

- **PlayerSession**: Current player state (health, mana, position, room)
- **RoomState**: Dungeon room instance state (enemies, loot, doors)
- **CombatEvent**: Combat events for synchronization and logging

**Storage**: DynamoDB tables with TTL (PlayerSessionsTable, RoomStatesTable, CombatEventsTable)

**Access Pattern**:
- Created when player joins/room spawns
- Updated frequently during gameplay
- Expires after inactivity (TTL)

## Update Strategies

### Immediate Updates (Real-Time via WebSocket)

**Critical events that must sync immediately:**

1. **Player Death**
   - Prevents duplicate loot drops
   - Triggers respawn for all clients
   - Updates room state

2. **Enemy Death**
   - Prevents multiple players from killing same enemy
   - Triggers loot drop (server-authoritative)
   - Updates room cleared status

3. **Loot Pickup**
   - First player to pick up gets the item
   - Removes loot from room state
   - Prevents duplicate pickups

4. **Door Interactions**
   - Opens/closes doors for all players
   - Prevents race conditions
   - Triggers room transitions

5. **Boss Phase Transitions**
   - Synchronizes boss mechanics
   - Ensures all players see same phase
   - Critical for coordinated gameplay

**Implementation:**
```
Client → WebSocket → Server
  ↓
Server validates event
  ↓
Server updates RoomState
  ↓
Server broadcasts to all clients in room
  ↓
Clients apply update
```

### Batched Updates (Every 200-500ms)

**Non-critical data that can tolerate small delays:**

1. **Player Position**
   - Smooth interpolation handles delays
   - Reduces network traffic
   - Acceptable for co-op PvE

2. **Health/Mana/Stamina**
   - Small delays don't affect gameplay
   - UI updates can lag slightly
   - Batched with position updates

3. **Buff/Debuff Status**
   - Visual effects can lag
   - Not time-critical for co-op
   - Included in batch updates

4. **Combat Animations**
   - Predicted client-side
   - Server confirms later
   - Corrections are subtle

**Implementation:**
```
Client accumulates changes locally
  ↓
Every 200-500ms:
  Client → HTTP POST → Server
  ↓
Server validates and updates PlayerSession
  ↓
Server returns updated RoomState
  ↓
Client applies corrections if needed
```

### Never Synced (Client-Only)

**Data that stays local:**

1. **Particle Effects** - Each client renders independently
2. **Camera Movement** - Per-player preference
3. **UI State** - Local only
4. **Audio Playback** - Local only
5. **Animation Blending** - Client-side smoothing

## Data Flow Examples

### Example 1: Player Attacks Enemy (Co-op)

**Single-Player (Phase 1):**
```
Player presses attack button
  ↓
Godot: CombatComponent.attack()
  ↓
Godot: Hitbox detects enemy hurtbox
  ↓
Godot: Enemy.take_damage()
  ↓
Godot: Enemy health reduced
  ↓
Godot: If health <= 0, enemy dies and drops loot
```

**Multiplayer (Phase 2):**
```
Player presses attack button
  ↓
Godot: CombatComponent.attack() (client prediction)
  ↓
Godot: Hitbox detects enemy hurtbox
  ↓
Client → WebSocket → Server: CombatEvent(damage_dealt)
  ↓
Server validates hit (position, range, timing)
  ↓
Server updates RoomState.enemies[].current_health
  ↓
Server → WebSocket → All clients: RoomState update
  ↓
Clients apply damage (reconcile with prediction)
  ↓
If enemy dies:
  Server generates loot (server-authoritative)
  Server → WebSocket → All clients: Enemy death + loot spawn
```

### Example 2: Player Picks Up Loot (Co-op)

**Single-Player (Phase 1):**
```
Player walks near loot
  ↓
Godot: Loot.area_entered(player)
  ↓
Godot: Player inventory updated
  ↓
Godot: Loot removed from scene
```

**Multiplayer (Phase 2):**
```
Player walks near loot
  ↓
Godot: Loot.area_entered(player) (client prediction)
  ↓
Client → WebSocket → Server: Loot pickup request
  ↓
Server checks RoomState.loot_drops[].is_picked_up
  ↓
If not picked up:
  Server marks as picked up
  Server updates player inventory
  Server → WebSocket → All clients: Loot removed
  ↓
If already picked up:
  Server → WebSocket → Client: Pickup rejected
  Client rolls back prediction
```

### Example 3: Room Cleared (Co-op)

**Single-Player (Phase 1):**
```
Last enemy dies
  ↓
Godot: Check if all enemies dead
  ↓
Godot: Open exit doors
  ↓
Godot: Play victory sound
```

**Multiplayer (Phase 2):**
```
Last enemy dies
  ↓
Server updates RoomState.enemies[].is_alive = false
  ↓
Server checks if all enemies dead
  ↓
Server sets RoomState.is_cleared = true
  ↓
Server updates RoomState.doors[].is_open = true
  ↓
Server → WebSocket → All clients: Room cleared
  ↓
Clients open doors and play effects
```

## Database Schema Design

### PlayerSessionsTable

**Purpose**: Track active player sessions for multiplayer coordination

**Key Schema:**
- Partition Key: `session_id` (unique per session)
- GSI: `player_id` (find all sessions for a player)
- GSI: `room_id` (find all players in a room)

**TTL**: Sessions expire after 1 hour of inactivity

**Use Cases:**
- Find all players in a room
- Check if player is online
- Disconnect detection via heartbeat
- Session recovery after disconnect

### RoomStatesTable

**Purpose**: Track dungeon room instances and their state

**Key Schema:**
- Partition Key: `room_id` (unique per room instance)
- GSI: `dungeon_id` (find all instances of a dungeon)

**TTL**: Rooms expire after 30 minutes if empty

**Use Cases:**
- Get current room state
- Update enemy health
- Track loot drops
- Manage door states
- Room cleared status

### CombatEventsTable

**Purpose**: Log combat events for synchronization and analytics

**Key Schema:**
- Partition Key: `room_id` (events grouped by room)
- Sort Key: `event_id` (unique event identifier)
- GSI: `room_id` + `timestamp` (query events by time)

**TTL**: Events expire after 24 hours

**Use Cases:**
- Synchronize combat events between clients
- Replay combat for debugging
- Analytics and balancing
- Cheat detection

## API Endpoints

### Configuration Endpoints (Phase 1)

**GET /api/combat-stats/{id}**
- Fetch combat stats configuration
- Cached client-side
- Updated on content releases

**GET /api/enemy-types/{id}**
- Fetch enemy type configuration
- Cached client-side
- Updated on content releases

**GET /api/loot-tables/{id}**
- Fetch loot table configuration
- Cached client-side
- Updated on content releases

**GET /api/abilities/{id}**
- Fetch ability configuration
- Cached client-side
- Updated on content releases

### Session Endpoints (Phase 2)

**POST /api/sessions**
- Create new player session
- Returns session_id
- Initializes player state

**GET /api/sessions/{session_id}**
- Get current session state
- Returns player health, mana, position, room

**PUT /api/sessions/{session_id}**
- Update session state (batched updates)
- Updates position, health, mana, stamina
- Returns updated state

**DELETE /api/sessions/{session_id}**
- End player session
- Cleanup room state if last player

### Room Endpoints (Phase 2)

**POST /api/rooms**
- Create new room instance
- Spawns enemies based on dungeon template
- Returns room_id and initial state

**GET /api/rooms/{room_id}**
- Get current room state
- Returns enemies, loot, doors, players

**PUT /api/rooms/{room_id}/join**
- Player joins room
- Adds player to room state
- Returns current room state

**PUT /api/rooms/{room_id}/leave**
- Player leaves room
- Removes player from room state
- Cleanup if last player

### Event Endpoints (Phase 2)

**POST /api/events**
- Submit combat event
- Server validates and processes
- Broadcasts to room via WebSocket

**GET /api/events/{room_id}**
- Get recent events for room
- Used for sync after disconnect
- Returns last N events

## WebSocket Protocol (Phase 2)

### Connection

**Client → Server:**
```json
{
  "type": "connect",
  "session_id": "uuid",
  "room_id": "uuid"
}
```

**Server → Client:**
```json
{
  "type": "connected",
  "room_state": { /* full room state */ }
}
```

### Heartbeat

**Client → Server (every 10 seconds):**
```json
{
  "type": "heartbeat",
  "session_id": "uuid",
  "timestamp": "2026-02-14T12:00:00Z"
}
```

**Server → Client:**
```json
{
  "type": "heartbeat_ack",
  "server_time": "2026-02-14T12:00:00Z"
}
```

### Combat Events

**Client → Server:**
```json
{
  "type": "combat_event",
  "event": {
    "event_type": "damage_dealt",
    "source_player_id": "uuid",
    "target_enemy_id": "uuid",
    "damage_amount": 25.0,
    "is_critical": true,
    "position": {"x": 10.0, "y": 0.0, "z": 5.0}
  }
}
```

**Server → All Clients in Room:**
```json
{
  "type": "room_update",
  "room_state": {
    "enemies": [
      {
        "enemy_instance_id": "uuid",
        "current_health": 25.0,
        "is_alive": true
      }
    ]
  }
}
```

### Loot Events

**Client → Server:**
```json
{
  "type": "loot_pickup",
  "loot_instance_id": "uuid",
  "player_id": "uuid"
}
```

**Server → All Clients in Room:**
```json
{
  "type": "loot_removed",
  "loot_instance_id": "uuid",
  "picked_up_by": "uuid"
}
```

## Client-Side Implementation

### Godot Multiplayer Manager

**scripts/backend/multiplayer_manager.gd:**
```gdscript
class_name MultiplayerManager
extends Node

signal room_state_updated(room_state: Dictionary)
signal player_joined(player_id: String)
signal player_left(player_id: String)
signal combat_event_received(event: Dictionary)

var websocket: WebSocketPeer
var session_id: String
var room_id: String
var is_connected: bool = false

func connect_to_room(p_session_id: String, p_room_id: String) -> void:
    session_id = p_session_id
    room_id = p_room_id
    
    websocket = WebSocketPeer.new()
    websocket.connect_to_url("wss://api.example.com/ws")
    
    # Wait for connection
    await get_tree().create_timer(1.0).timeout
    
    # Send connect message
    var connect_msg = {
        "type": "connect",
        "session_id": session_id,
        "room_id": room_id
    }
    websocket.send_text(JSON.stringify(connect_msg))
    is_connected = true

func send_combat_event(event: Dictionary) -> void:
    if not is_connected:
        return
    
    var msg = {
        "type": "combat_event",
        "event": event
    }
    websocket.send_text(JSON.stringify(msg))

func _process(delta: float) -> void:
    if not is_connected:
        return
    
    websocket.poll()
    
    var state = websocket.get_ready_state()
    if state == WebSocketPeer.STATE_OPEN:
        while websocket.get_available_packet_count():
            var packet = websocket.get_packet()
            var json = JSON.parse_string(packet.get_string_from_utf8())
            _handle_message(json)

func _handle_message(msg: Dictionary) -> void:
    match msg.type:
        "connected":
            room_state_updated.emit(msg.room_state)
        "room_update":
            room_state_updated.emit(msg.room_state)
        "player_joined":
            player_joined.emit(msg.player_id)
        "player_left":
            player_left.emit(msg.player_id)
        "combat_event":
            combat_event_received.emit(msg.event)
```

## Migration Path

### Phase 1 → Phase 2 Migration

**Step 1: Add multiplayer fields to existing code**
- Add `player_id` to player data
- Add `room_id` to room/dungeon tracking
- Add `session_id` to save data

**Step 2: Implement session management**
- Create PlayerSession on game start
- Update session with heartbeat
- Cleanup session on game exit

**Step 3: Implement room instancing**
- Create RoomState when entering dungeon
- Track enemy state in RoomState
- Sync loot drops via RoomState

**Step 4: Add WebSocket connection**
- Connect to WebSocket on room join
- Send combat events via WebSocket
- Receive room updates via WebSocket

**Step 5: Client-side prediction**
- Apply combat locally (instant feedback)
- Send event to server (validation)
- Reconcile with server response (correction)

## Performance Considerations

### Network Traffic

**Batch Updates (200ms intervals):**
- Player position: 12 bytes × 5/sec = 60 bytes/sec
- Health/mana/stamina: 12 bytes × 5/sec = 60 bytes/sec
- Total per player: ~120 bytes/sec

**Immediate Events:**
- Damage event: ~100 bytes
- Death event: ~80 bytes
- Loot event: ~120 bytes
- Average: ~10 events/minute = ~200 bytes/minute

**Total bandwidth per player: ~150 bytes/sec (1.2 Kbps)**

### Database Costs

**DynamoDB Pricing (Pay-per-request):**
- Write: $1.25 per million requests
- Read: $0.25 per million requests

**Estimated costs (4 players, 1 hour session):**
- Session updates: 4 × 5/sec × 3600 = 72,000 writes = $0.09
- Room updates: 10/sec × 3600 = 36,000 writes = $0.045
- Event logging: 40/min × 60 = 2,400 writes = $0.003
- Total: ~$0.14 per hour per room

**Very affordable for co-op PvE!**

## Security Considerations

### Anti-Cheat

**Server-side validation:**
- Validate all damage calculations
- Check ability cooldowns
- Verify resource costs
- Validate positions (no teleporting)
- Rate limit requests

**Client-side detection:**
- Monitor for impossible values
- Track timing anomalies
- Log suspicious behavior
- Report to server for analysis

### Authentication

**Phase 1 (Single-player):**
- No authentication needed
- Local save files only

**Phase 2 (Multiplayer):**
- AWS Cognito for player accounts
- JWT tokens for API authentication
- Session tokens for WebSocket
- Refresh tokens for long sessions

## Testing Strategy

### Unit Tests

**Test session management:**
- Create/update/delete sessions
- Heartbeat handling
- Disconnect detection
- Session recovery

**Test room state:**
- Room creation/cleanup
- Enemy state updates
- Loot drop management
- Door state changes

**Test event processing:**
- Event validation
- Event broadcasting
- Event ordering
- Event replay

### Integration Tests

**Test multiplayer scenarios:**
- Two players attack same enemy
- Two players pick up same loot
- Player disconnects during combat
- Room cleanup when empty
- Session recovery after disconnect

### Load Tests

**Test scalability:**
- 100 concurrent rooms
- 400 concurrent players
- 1000 events/second
- Database throughput
- WebSocket connection limits

## Future Enhancements

### Phase 3: PvP

**Server-authoritative combat:**
- All combat calculations on server
- Client sends inputs only
- Server broadcasts results
- Lag compensation for fairness

**Matchmaking:**
- Skill-based matchmaking
- Party system
- Ranked/unranked modes
- Leaderboards

**Anti-cheat:**
- Server-side hit validation
- Replay analysis
- Behavior monitoring
- Ban system

### Phase 4: Persistence

**Player progression:**
- Character levels
- Equipment system
- Skill trees
- Achievements

**Dungeon persistence:**
- Save dungeon progress
- Resume from checkpoint
- Shared dungeon instances
- Dungeon leaderboards

## Conclusion

This architecture provides a clear migration path from single-player to multiplayer while keeping the initial implementation simple. The data models are designed with multiplayer in mind, making the future transition smooth and minimizing refactoring.

**Key Principles:**
1. Start simple (single-player)
2. Design for multiplayer (data models)
3. Migrate incrementally (phase by phase)
4. Test thoroughly (unit + integration + load)
5. Monitor performance (costs + latency)
