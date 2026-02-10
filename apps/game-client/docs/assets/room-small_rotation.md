# Rotation Transform Documentation

Asset: room-small

## Cardinal Direction Rotations

| Direction | Y Rotation | Euler Angles |
|-----------|------------|---------------|
| North     | 0°         | (0°, 0°, 0°)  |
| East      | 90°        | (0°, 90°, 0°) |
| South     | 180°       | (0°, 180°, 0°)|
| West      | 270°       | (0°, 270°, 0°)|

## Connection Point Transformations

Original connection points and their transformations for each cardinal direction:

### Connection Point 1 (door)

**Original**:
- Position: (0.00, 1.57, 6.00)
- Normal: (0.00, 0.00, 1.00)

**North (0°)**:
- Position: (0.00, 1.57, 6.00)
- Normal: (0.00, 0.00, 1.00)

**East (90°)**:
- Position: (6.00, 1.57, -0.00)
- Normal: (1.00, 0.00, -0.00)

**South (180°)**:
- Position: (-0.00, 1.57, -6.00)
- Normal: (-0.00, 0.00, -1.00)

**West (270°)**:
- Position: (-6.00, 1.57, 0.00)
- Normal: (-1.00, 0.00, 0.00)

### Connection Point 2 (door)

**Original**:
- Position: (0.00, 1.57, -6.00)
- Normal: (0.00, 0.00, -1.00)

**North (0°)**:
- Position: (0.00, 1.57, -6.00)
- Normal: (0.00, 0.00, -1.00)

**East (90°)**:
- Position: (-6.00, 1.57, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**South (180°)**:
- Position: (0.00, 1.57, 6.00)
- Normal: (0.00, 0.00, 1.00)

**West (270°)**:
- Position: (6.00, 1.57, -0.00)
- Normal: (1.00, 0.00, -0.00)

### Connection Point 3 (door)

**Original**:
- Position: (6.00, 1.57, 0.00)
- Normal: (1.00, 0.00, 0.00)

**North (0°)**:
- Position: (6.00, 1.57, 0.00)
- Normal: (1.00, 0.00, 0.00)

**East (90°)**:
- Position: (0.00, 1.57, -6.00)
- Normal: (-0.00, 0.00, -1.00)

**South (180°)**:
- Position: (-6.00, 1.57, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**West (270°)**:
- Position: (-0.00, 1.57, 6.00)
- Normal: (0.00, 0.00, 1.00)

### Connection Point 4 (door)

**Original**:
- Position: (-6.00, 1.57, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**North (0°)**:
- Position: (-6.00, 1.57, 0.00)
- Normal: (-1.00, 0.00, 0.00)

**East (90°)**:
- Position: (0.00, 1.57, 6.00)
- Normal: (0.00, 0.00, 1.00)

**South (180°)**:
- Position: (6.00, 1.57, -0.00)
- Normal: (1.00, 0.00, -0.00)

**West (270°)**:
- Position: (-0.00, 1.57, -6.00)
- Normal: (-0.00, 0.00, -1.00)

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

