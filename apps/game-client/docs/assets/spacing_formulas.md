# Spacing Formula Documentation

## Corridor Count Formula

The number of corridor pieces required for a given distance is calculated using:

```
count = ceil((distance - overlap) / effective_length)
```

Where:
- `distance` = target distance between two points
- `overlap` = distance that corridors overlap at connection points
- `effective_length` = corridor_length - overlap
- `corridor_length` = full length of a single corridor piece

## Worked Examples

Assuming a corridor with:
- Length: 5.0 units
- Overlap: 0.5 units
- Effective length: 4.5 units

### Distance: 10.0 units

```
count = ceil((10.0 - 0.5) / 4.5)
count = ceil(9.50 / 4.5)
count = ceil(2.11)
count = 3
```

**Result**: 3 corridor pieces
**Actual length**: 14.00 units (difference: 4.00 units)

### Distance: 15.0 units

```
count = ceil((15.0 - 0.5) / 4.5)
count = ceil(14.50 / 4.5)
count = ceil(3.22)
count = 4
```

**Result**: 4 corridor pieces
**Actual length**: 18.50 units (difference: 3.50 units)

### Distance: 20.0 units

```
count = ceil((20.0 - 0.5) / 4.5)
count = ceil(19.50 / 4.5)
count = ceil(4.33)
count = 5
```

**Result**: 5 corridor pieces
**Actual length**: 23.00 units (difference: 3.00 units)

### Distance: 30.0 units

```
count = ceil((30.0 - 0.5) / 4.5)
count = ceil(29.50 / 4.5)
count = ceil(6.56)
count = 7
```

**Result**: 7 corridor pieces
**Actual length**: 32.00 units (difference: 2.00 units)

## Tolerance

- The formula ensures the actual length is within ±0.5 units of the target distance
- Connection points should align within ±0.1 units for valid connections
- Gaps larger than 0.2 units are considered errors
- Overlaps larger than 0.5 units are considered errors

