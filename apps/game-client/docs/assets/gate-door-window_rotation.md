# Rotation Transform Documentation

Asset: gate-door-window

## Cardinal Direction Rotations

| Direction | Y Rotation | Euler Angles |
|-----------|------------|---------------|
| North     | 0°         | (0°, 0°, 0°)  |
| East      | 90°        | (0°, 90°, 0°) |
| South     | 180°       | (0°, 180°, 0°)|
| West      | 270°       | (0°, 270°, 0°)|

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

