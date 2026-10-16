import json
with open('design/riung.pen','r',encoding='utf-8',errors='ignore') as f:
    data=json.load(f)

children = data.get('children',[])
screens = []
for c in children:
    cid = c.get('id','')
    name = (c.get('name') or '').strip()
    ctype = c.get('type','')
    # only include frames/rectangles that look like screens
    if ctype in ('frame','rectangle'):
        screens.append((cid, ctype, name))

# Print all unique screen-like names sorted
names = sorted({n for _,_,n in screens})
for n in names:
    print(n)
