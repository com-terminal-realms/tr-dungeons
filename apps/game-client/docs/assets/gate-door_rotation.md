# Rotation Transform Documentation

Asset: gate-door

## Cardinal Direction Rotations

| Direction | Y Rotation | Euler Angles |
|-----------|------------|---------------|
| North     | 0°         | (0°, 0°, 0°)  |
| East      | 90°        | (0°, 90°, 0°) |
| South     | 180°       | (0°, 180°, 0°)|
| West      | 270°       | (0°, 270°, 0°)|

## Connection Point Transformations

Original connection points and their transformations for each cardinal direction:

### Connection Point 1 (corridor_end)

**Original**:
- Position: (-3.00, 2.20, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**North (0°)**:
- Position: (-3.00, 2.20, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**East (90°)**:
- Position: (0.00, 2.20, 3.00)
- Normal: (0.00, 0.00, 1.00)

**South (180°)**:
- Position: (3.00, 2.20, -0.00)
- Normal: (1.00, 0.00, -0.00)

**West (270°)**:
- Position: (-0.00, 2.20, -3.00)
- Normal: (-0.00, 0.00, -1.00)

### Connection Point 2 (corridor_end)

**Original**:
- Position: (2.20, 2.20, 0.00)
- Normal: (1.00, 0.00, 0.00)

**North (0°)**:
- Position: (2.20, 2.20, 0.00)
- Normal: (1.00, 0.00, 0.00)

**East (90°)**:
- Position: (-0.00, 2.20, -2.20)
- Normal: (-0.00, 0.00, -1.00)

**South (180°)**:
- Position: (-2.20, 2.20, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**West (270°)**:
- Position: (0.00, 2.20, 2.20)
- Normal: (0.00, 0.00, 1.00)

## Rotation Matrices

Y-axis rotation matrices for cardinal directions:

### North (0°)

```
[ 1  0  0 ]
[ 0  1  0 ]
[ 0  0  1 ]
```

### East (90°)

```
[ 0  0  1 ]
[ 0  1  0 ]
[-1  0  0 ]
```

### South (180°)

```
[-1  0  0 ]
[ 0  1  0 ]
[ 0  0 -1 ]
```

### West (270°)

```
[ 0  0 -1 ]
[ 0  1  0 ]
[ 1  0  0 ]
```

