import json
with open('design/riung.pen', 'r', encoding='utf-8', errors='ignore') as f:
    data = json.load(f)
children = data['children']
print('Total anak komponen sekarang:', len(children))
print()
for i, c in enumerate(children):
    if c['id'] in ('PB-01', 'TIER-01', 'PW-ONB-01'):
        idx_rev = len(children) - 1 - i  # jarak dari akhir
        print('Frame baru ke-' + str(i + 1) + ' (indeks ' + str(i) + ')')
        print('  id=' + c['id'])
        print('  nama=' + c['name'])
        print('  posisi x/y=' + str(c.get('x')) + '/' + str(c.get('y')))
        print('  ukuran=' + str(c.get('width')) + 'x' + str(c.get('height')))
        print('  fill=' + str(c.get('fill')))
        print('  jumlah anak dalam=' + str(len(c.get('children', []))))
        print('  jarak dari akhir array=' + str(idx_rev) + ' komponen')
        print()
print('Letak: di AKHIR array children (setelah semua frame desain lama seperti Glass, REF, Toko, Launch, Onboarding, dll).')
