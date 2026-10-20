import json

with open('design/riung.pen', 'r', encoding='utf-8', errors='ignore') as f:
    data = json.load(f)

# New frames to inject
new_frames = [
    {
        "type": "frame",
        "id": "PB-01",
        "name": "Pro Badge (komponen)",
        "x": 120,
        "y": 3200,
        "width": 120,
        "height": 36,
        "fill": ["#F1EDFC"],
        "layout": "horizontal",
        "children": [
            {
                "type": "ellipse",
                "id": "PB-01-icon",
                "name": "Bintang",
                "x": 10,
                "y": 10,
                "width": 16,
                "height": 16,
                "fill": ["#FF9F5A"],
                "cornerRadius": 8
            },
            {
                "type": "text",
                "id": "PB-01-label",
                "name": "PRO",
                "x": 32,
                "y": 6,
                "width": 60,
                "height": 24,
                "fill": ["#332E45"],
                "font": "Plus Jakarta Sans",
                "fontSize": 10,
                "fontWeight": "Bold"
            }
        ]
    },
    {
        "type": "frame",
        "id": "TIER-01",
        "name": "Tier Card — Premium",
        "x": 100,
        "y": 3600,
        "width": 420,
        "height": 520,
        "fill": ["#FFFFFF"],
        "layout": "vertical",
        "children": [
            {
                "type": "rectangle",
                "id": "TIER-01-topbar",
                "name": "Gradient Bar",
                "x": 0,
                "y": 0,
                "width": 420,
                "height": 3,
                "fill": ["#6C63E0", "#FF9F5A"],
                "gradient": {"from": {"x":0,"y":0}, "to":{"x":1,"y":0}, "stops":[{"color":"#6C63E0","offset":0},{"color":"#FF9F5A","offset":1}]}
            },
            {
                "type": "text",
                "id": "TIER-01-header",
                "name": "Header",
                "x": 24,
                "y": 24,
                "width": 372,
                "height": 32,
                "fill": ["#332E45"],
                "font": "Bricolage Grotesque",
                "fontSize": 22,
                "fontWeight": "Bold",
                "text": "Riung Premium"
            },
            {
                "type": "frame",
                "id": "TIER-01-badge",
                "name": "Badge Terbaik",
                "x": 340,
                "y": 24,
                "width": 68,
                "height": 22,
                "fill": ["#FFE4CC"],
                "cornerRadius": 10,
                "children": [
                    {
                        "type": "text",
                        "id": "TIER-01-badge-text",
                        "name": "Terbaik",
                        "x": 6,
                        "y": 4,
                        "width": 56,
                        "height": 14,
                        "fill": ["#FF9F5A"],
                        "font": "Plus Jakarta Sans",
                        "fontSize": 9,
                        "fontWeight": "Bold",
                        "text": "Terbaik"
                    }
                ]
            },
            {
                "type": "group",
                "id": "TIER-01-features",
                "name": "Fitur List",
                "x": 24,
                "y": 72,
                "width": 372,
                "height": 240,
                "layout": "vertical",
                "children": [
                    {"type":"text","id":"TIER-01-f1","name":"Check","x":0,"y":0,"w":372,"h":36,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":15,"text":"✓ Semua monster terbuka"},
                    {"type":"text","id":"TIER-01-f2","name":"Check","x":0,"y":48,"w":372,"h":36,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":15,"text":"✓ Laporan refleksi mingguan"},
                    {"type":"text","id":"TIER-01-f3","name":"Check","x":0,"y":96,"w":372,"h":36,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":15,"text":"✓ Meditasi & fokus tanpa batas"},
                    {"type":"text","id":"TIER-01-f4","name":"Check","x":0,"y":144,"w":372,"h":36,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":15,"text":"✓ Jurnal PIN & ekspor data"}
                ]
            },
            {
                "type": "frame",
                "id": "TIER-01-pricepill",
                "name": "Price Pill",
                "x": 24,
                "y": 340,
                "width": 180,
                "height": 36,
                "fill": ["#FFF8EF"],
                "cornerRadius": 18,
                "stroke": "#F0E4D6",
                "strokeWidth": 1,
                "children": [
                    {"type":"text","id":"TIER-01-price","name":"Price","x":12,"y":8,"w":156,"h":20,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":14,"fontWeight":"Bold","text":"Rp 99.000 / tahun"}
                ]
            },
            {
                "type": "frame",
                "id": "TIER-01-cta",
                "name": "CTA Button",
                "x": 24,
                "y": 392,
                "width": 372,
                "height": 48,
                "fill": ["#6C63E0"],
                "cornerRadius": 12,
                "children": [
                    {"type":"text","id":"TIER-01-cta-text","name":"CTA","x":0,"y":14,"w":372,"h":20,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":16,"fontWeight":"Bold","align":"center","text":"Pilih Premium"}
                ]
            }
        ]
    },
    {
        "type": "frame",
        "id": "PW-ONB-01",
        "name": "Paywall — Onboarding",
        "x": 0,
        "y": 4700,
        "width": 1440,
        "height": 900,
        "fill": ["#FDEFE0", "#FFF8EF"],
        "gradient": {"from":{"x":0,"y":0},"to":{"x":0,"y":1},"stops":[{"color":"#E4DEF3","offset":0},{"color":"#FFF7E4","offset":1}]},
        "layout": "vertical",
        "children": [
            {
                "type": "text",
                "id": "PW-ONB-01-header",
                "name": "Header",
                "x": 120,
                "y": 80,
                "width": 1200,
                "height": 60,
                "fill": ["#332E45"],
                "font": "Bricolage Grotesque",
                "fontSize": 36,
                "fontWeight": "Bold",
                "text": "Buka Akses Penuh"
            },
            {
                "type": "group",
                "id": "PW-ONB-01-columns",
                "name": "Tier Columns",
                "x": 120,
                "y": 220,
                "width": 1200,
                "height": 480,
                "layout": "horizontal",
                "children": [
                    {
                        "type": "frame",
                        "id": "PW-ONB-01-col-monthly",
                        "name": "Bulanan",
                        "x": 0,
                        "y": 0,
                        "width": 560,
                        "height": 480,
                        "fill": ["#FFFFFF"],
                        "cornerRadius": 24,
                        "opacity": 0.92,
                        "stroke": "#F0E4D6",
                        "strokeWidth": 1
                    },
                    {
                        "type": "frame",
                        "id": "PW-ONB-01-col-yearly",
                        "name": "Tahunan",
                        "x": 640,
                        "y": 0,
                        "width": 560,
                        "height": 480,
                        "fill": ["#FFFFFF"],
                        "cornerRadius": 24,
                        "opacity": 0.92,
                        "stroke": "#F0E4D6",
                        "strokeWidth": 1
                    }
                ]
            },
            {
                "type": "frame",
                "id": "PW-ONB-01-bottomsheet",
                "name": "Bottom Sheet Glass",
                "x": 120,
                "y": 720,
                "width": 1200,
                "height": 120,
                "fill": ["#C7FFFFFF"],
                "cornerRadius": 24,
                "children": [
                    {
                        "type": "frame",
                        "id": "PW-ONB-01-cta-glass",
                        "name": "Button Lanjutkan",
                        "x": 400,
                        "y": 24,
                        "width": 400,
                        "height": 72,
                        "fill": ["#6C63E0"],
                        "cornerRadius": 16,
                        "children": [
                            {"type":"text","id":"PW-ONB-01-cta-label","name":"Lanjutkan","x":0,"y":20,"w":400,"h":32,"fill":["#332E45"],"font":"Plus Jakarta Sans","fontSize":18,"fontWeight":"Bold","align":"center","text":"Lanjutkan"}
                        ]
                    }
                ]
            }
        ]
    }
]

data['children'].extend(new_frames)

with open('design/riung.pen', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)

print("Added 3 new frames to riung.pen:")
for frame in new_frames:
    print(f"  - {frame['id']} | {frame['name']} (type={frame['type']}, w={frame.get('width')}, h={frame.get('height')})")
print(f"Total children now: {len(data['children'])}")
