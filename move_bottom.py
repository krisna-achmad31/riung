import json

with open('design/riung.pen', 'r', encoding='utf-8', errors='ignore') as f:
    data = json.load(f)

children = data['children']

# New positions: below the deepest existing row (y=49000), with margin
NEW_Y_ROW = 50000
positions = {
    'PB-01':     (0,   NEW_Y_ROW),          # small pill, top of the new strip
    'TIER-01':   (0,   NEW_Y_ROW + 120),    # card below the pill
    'PW-ONB-01': (700, NEW_Y_ROW + 120),    # onboarding paywall to the right
}

moved = []
for c in children:
    cid = c.get('id')
    if cid in positions:
        x, y = positions[cid]
        c['x'] = x
        c['y'] = y
        moved.append(cid)

with open('design/riung.pen', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)

# Verify
children = data['children']
ids = [c['id'] for c in children]
print('Total anak:', len(children))
for target in ('PB-01', 'TIER-01', 'PW-ONB-01'):
    idx = ids.index(target)
    c = children[idx]
    print('%s | index %d/%d | %s | x=%s y=%s w=%s h=%s'
          % (target, idx, len(children) - 1, c['name'], c.get('x'), c.get('y'), c.get('width'), c.get('height')))
print()
print('Semua frame baru sekarang berada di bawah baris terjauh (y=49000), jadi terlihat di paling bawah kanvas.')
