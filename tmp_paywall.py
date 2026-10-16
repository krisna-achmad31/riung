import json
with open('design/riung.pen','r',encoding='utf-8',errors='ignore') as f:
    data=json.load(f)
children = data.get('children',[])
for c in children:
    name = (c.get('name') or '').strip()
    if 'paywall' in name.lower() or 'premium' in name.lower() or 'toko' in name.lower() or 'langgan' in name.lower() or 'tiket' in name.lower():
        print(f"id={c.get('id')} | type={c.get('type')} | name={name}")
        # also print children count for this screen
        sub = c.get('children',[])
        print(f"     sub-components: {len(sub)}")
        for s in sub[:10]:
            sub_name = (s.get('name') or '').strip()
            sub_type = s.get('type','')
            print(f"       - {sub_type:12} | {s.get('id','')}: {sub_name[:70]}")
