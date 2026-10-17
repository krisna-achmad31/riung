import json
with open('design/riung.pen', 'r', encoding='utf-8', errors='ignore') as f:
    data = json.load(f)

children = data['children']

# Compute bounding box of all existing frames (excluding the 3 new ones)
max_bottom = 0
max_right = 0
min_x = None
for c in children:
    if c.get('id') in ('PB-01', 'TIER-01', 'PW-ONB-01'):
        continue
    x = c.get('x', 0) or 0
    y = c.get('y', 0) or 0
    w = c.get('width', 0) or 0
    h = c.get('height', 0) or 0
    if y + h > max_bottom:
        max_bottom = y + h
    if x + w > max_right:
        max_right = x + w
    if min_x is None or x < min_x:
        min_x = x

print('Existing frames bounding box (no new):')
print('  min_x =', min_x)
print('  max_right =', max_right)
print('  max_bottom =', max_bottom)
print()

# Also show the frames nearest the bottom
print('Frames with largest y:')
pairs = []
for c in children:
    if c.get('id') in ('PB-01', 'TIER-01', 'PW-ONB-01'):
        continue
    y = c.get('y', 0) or 0
    pairs.append((y, c.get('id'), c.get('name'), c.get('x'), c.get('y'), c.get('width'), c.get('height')))
pairs.sort(reverse=True)
for p in pairs[:8]:
    print('  y=%s | id=%s | %s | x=%s w=%s h=%s' % (p[0], p[1], p[2], p[3], p[5], p[6]))
