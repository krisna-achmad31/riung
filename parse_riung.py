import json
with open("design/riung.pen") as f:
    data = json.load(f)

def find_waswas(node):
    if node.get("name") == "Chat Si Waswas":
        print("Found in riung.pen!")
        return True
    for c in node.get("children", []):
        if find_waswas(c): return True
    return False
find_waswas(data)
