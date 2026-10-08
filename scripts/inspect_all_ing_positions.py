import pymupdf

doc = pymupdf.open('lezzet_kitabi.pdf')

recipe_defs = [
    {'id': 'ispanak_corbasi', 'title': 'Ispanak Çorbası', 'p_start': 24},
    {'id': 'sebze_corbasi', 'title': 'Sebze Çorbası', 'p_start': 30},
    {'id': 'patates_corbasi', 'title': 'Patates Çorbası', 'p_start': 38},
    {'id': 'brokoli_corbasi', 'title': 'Brokoli Çorbası', 'p_start': 44},
    {'id': 'tavuklu_sezar_salata', 'title': 'Tavuklu Sezar Salata', 'p_start': 56},
    {'id': 'roka_salatasi', 'title': 'Roka Salatası', 'p_start': 62},
    {'id': 'beyaz_peynirli_makarna', 'title': 'Beyaz Peynirli ve Kremalı Dirsek Makarna', 'p_start': 72},
    {'id': 'kuru_domatesli_makarna', 'title': 'Kuru Domates ve Ispanaklı Kelebek Makarna', 'p_start': 80},
    {'id': 'mantar_soslu_makarna', 'title': 'Mantar Soslu Penne Makarna', 'p_start': 88},
    {'id': 'caprese_sandvic', 'title': 'Caprese Sandviç', 'p_start': 100},
    {'id': 'club_sandvic', 'title': 'Club Sandviç', 'p_start': 104},
    {'id': 'hamburger', 'title': 'Hamburger', 'p_start': 112},
    {'id': 'keci_peynirli_sandvic', 'title': 'Keçi Peynirli Izgara Sebzeli Sandviç', 'p_start': 120},
    {'id': 'kumru_sandvic', 'title': 'Kumru Sandviç', 'p_start': 128},
    {'id': 'tavuk_fume_sandvic', 'title': 'Tavuk Füme Sandviç', 'p_start': 136},
    {'id': 'ton_balikli_sandvic', 'title': 'Ton Balıklı Sandviç', 'p_start': 140},
    {'id': 'hindi_fume_lavas', 'title': 'Lavaş Ekmeğine Sarılı Hindi Füme Dürüm', 'p_start': 144},
    {'id': 'bol_peynirli_pogaca', 'title': 'Bol Peynirli Poğaça', 'p_start': 152},
    {'id': 'minik_kekler', 'title': 'Minik Kekler (Muffin)', 'p_start': 160},
    {'id': 'cikolata_toplari', 'title': 'Çikolata Topları', 'p_start': 168},
    {'id': 'gulen_yuz_kurabiye', 'title': 'Gülen Yüz Kurabiye', 'p_start': 174},
]

for r in recipe_defs:
    page = doc[r['p_start'] - 1]
    
    # 1. Collect all images in ingredient area (x > 480, y < 400)
    images = []
    for img in page.get_images():
        xref = img[0]
        rects = page.get_image_rects(xref)
        for rect in rects:
            if rect.x0 > 480 and rect.y0 < 400 and 15 < rect.width < 150 and 15 < rect.height < 150:
                images.append((rect, xref))
                
    # 2. Collect text blocks in ingredient area
    blocks = []
    for b in page.get_text('blocks'):
        rect = pymupdf.Rect(b[:4])
        text = b[4].strip().replace('\n', ' ')
        if rect.x0 > 480 and rect.y0 < 410 and 'Araçlar' not in text and 'MALZEMELER' not in text and 'Kişilik' not in text and 'Porsiyon' not in text:
            if text:
                blocks.append((rect, text))
                
    print(f"=== {r['id']} ({r['title']}) ===")
    print(f"  Found {len(images)} images and {len(blocks)} ingredient texts")
    
    # Pair each text with the closest image above it
    for b_rect, text in blocks:
        # Find image whose bottom is near text.y0 (within 10-60 points above text)
        cand = []
        for i_rect, xref in images:
            # Image is generally directly above the text
            # so i_rect.x0 should be close to b_rect.x0 and i_rect.y1 <= b_rect.y0 + 10
            x_dist = abs((i_rect.x0 + i_rect.x1)/2 - (b_rect.x0 + b_rect.x1)/2)
            y_diff = b_rect.y0 - i_rect.y1
            if -10 <= y_diff <= 60 and x_dist < 60:
                cand.append((y_diff + x_dist, xref, i_rect))
        cand.sort()
        if cand:
            best_xref, best_rect = cand[0][1], cand[0][2]
            print(f"  MATCH: '{text}' -> xref={best_xref} at {best_rect}")
        else:
            print(f"  NO MATCH: '{text}' at {b_rect}")
