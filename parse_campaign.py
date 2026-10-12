import json
with open("design/campaign.pen") as f:
    data = json.load(f)

def extract_names(node, depth=0):
    if depth > 0: print("  " * depth + node.get("name", "unnamed"))
    for c in node.get("children", []):
        extract_names(c, depth + 1)
extract_names(data)
