# Input Map Configuration

## Required Input Actions

Add these input actions to your project settings:

**Path**: Project > Project Settings > Input Map

### Combat Actions

| Action Name | Key/Button | Description |
|------------|------------|-------------|
| `attack` | Left Mouse Button | Melee attack |
| `cast_fireball` | Right Mouse Button | Cast fireball ability |
| `dodge` | Spacebar | Dodge roll |

### Movement Actions

| Action Name | Key | Description |
|------------|-----|-------------|
| `move_forward` | W | Move forward |
| `move_backward` | S | Move backward |
| `move_left` | A | Move left |
| `move_right` | D | Move right |

## Configuration Steps

1. Open Godot Editor
2. Go to Project > Project Settings
3. Select the "Input Map" tab
4. For each action:
   - Type the action name in the "Add New Action" field
   - Click "Add"
   - Click the "+" button next to the action
   - Press the key/button you want to assign
   - Click "OK"

## Alternative: Manual project.godot Edit

Add this to your `project.godot` file under `[input]`:

```ini
[input]

attack={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":1,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":true,"double_click":false,"script":null)
]
}

cast_fireball={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":2,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":2,"canceled":false,"pressed":true,"double_click":false,"script":null)
]
}

dodge={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
]
}

move_forward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)
]
}

move_backward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
]
}

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
]
}

move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
]
}
```

## Testing Input

After configuration, test in the combat arena:

1. Open `scenes/test/combat_arena.tscn`
2. Press F5 to run
3. Test each input:
   - WASD: Movement
   - Left Click: Attack
   - Right Click: Fireball
   - Spacebar: Dodge

## Troubleshooting

**Input not working?**
- Check that action names match exactly (case-sensitive)
- Verify the input is configured in Project Settings
- Check console for error messages

**Player not responding?**
- Ensure player scene has the combat_player.gd script attached
- Check that CombatComponent is present and connected
- Verify collision layers are configured correctly
