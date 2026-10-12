import json

with open("design/riung.pen") as f:
    data = json.load(f)

# Find first text node to learn the format
def find_text(node):
    if node.get("type") == "text":
        return node
    for child in node.get("children", []):
        res = find_text(child)
        if res: return res
    return None

t = find_text(data)
print(json.dumps(t, indent=2))
