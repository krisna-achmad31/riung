import json
with open('design/riung.pen','r',encoding='utf-8',errors='ignore') as f:
    data=json.load(f)

print("=== TOP KEYS ===")
print(list(data.keys()))

print("\n=== THEMES ===")
themes = data.get('themes') or {}
if isinstance(themes, list):
    for v in themes:
        print(v.get('id'), "name:", v.get('name'), "colors:", list((v.get('colors') or {}).keys())[:15])
else:
    for k,v in themes.items():
        colors = v.get('colors') if isinstance(v,dict) else None
        if isinstance(colors, list): colors_keys = [c.get('id') for c in colors] if isinstance(colors[0], dict) else colors[:5]
        elif isinstance(colors, dict): colors_keys = list(colors.keys())
        else: colors_keys = []
        print(k, "name:", v.get('name') if isinstance(v,dict) else v, "colors:", colors_keys[:15])

print("\n=== VARIABLES (first 30) ===")
vars_data = data.get('variables') or {}
for k in list(vars_data.keys())[:30]:
    val = vars_data[k]
    if isinstance(val, dict):
        print(k, "=", val.get('value'), "| type:", val.get('variableType'), "| desc:", (val.get('name') or '')[:40])
    else:
        print(k, "=", str(val)[:60])

children = data.get('children',[])
print("\n=== CHILDREN OVERVIEW (first 40 screens) ===")
for i,c in enumerate(children[:40]):
    name = (c.get('name') or '').replace('\n',' ')
    ctype = c.get('type','')
    cid = c.get('id','')
    print(f"{i:03d} | {ctype:15} | id={cid:8} | {name[:100]}")
