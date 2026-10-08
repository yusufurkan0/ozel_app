import pymupdf
import os
import re
from PIL import Image
from io import BytesIO

doc = pymupdf.open('lezzet_kitabi.pdf')
OUTPUT_DIR = os.path.join('assets', 'images', 'lezzet')
os.makedirs(OUTPUT_DIR, exist_ok=True)

recipe_defs = [
    {'id': 'ispanak_corbasi', 'title': 'Ispanak Çorbası', 'p_start': 24, 'p_end': 29},
    {'id': 'sebze_corbasi', 'title': 'Sebze Çorbası', 'p_start': 30, 'p_end': 37},
    {'id': 'patates_corbasi', 'title': 'Patates Çorbası', 'p_start': 38, 'p_end': 43},
    {'id': 'brokoli_corbasi', 'title': 'Brokoli Çorbası', 'p_start': 44, 'p_end': 53},
    {'id': 'tavuklu_sezar_salata', 'title': 'Tavuklu Sezar Salata', 'p_start': 56, 'p_end': 61},
    {'id': 'roka_salatasi', 'title': 'Roka Salatası', 'p_start': 62, 'p_end': 67},
    {'id': 'beyaz_peynirli_makarna', 'title': 'Beyaz Peynirli ve Kremalı Dirsek Makarna', 'p_start': 72, 'p_end': 79},
    {'id': 'kuru_domatesli_makarna', 'title': 'Kuru Domates ve Ispanaklı Kelebek Makarna', 'p_start': 80, 'p_end': 87},
    {'id': 'mantar_soslu_makarna', 'title': 'Mantar Soslu Penne Makarna', 'p_start': 88, 'p_end': 95},
    {'id': 'caprese_sandvic', 'title': 'Caprese Sandviç', 'p_start': 100, 'p_end': 103},
    {'id': 'club_sandvic', 'title': 'Club Sandviç', 'p_start': 104, 'p_end': 111},
    {'id': 'hamburger', 'title': 'Hamburger', 'p_start': 112, 'p_end': 119},
    {'id': 'keci_peynirli_sandvic', 'title': 'Keçi Peynirli Izgara Sebzeli Sandviç', 'p_start': 120, 'p_end': 127},
    {'id': 'kumru_sandvic', 'title': 'Kumru Sandviç', 'p_start': 128, 'p_end': 135},
    {'id': 'tavuk_fume_sandvic', 'title': 'Tavuk Füme Sandviç', 'p_start': 136, 'p_end': 139},
    {'id': 'ton_balikli_sandvic', 'title': 'Ton Balıklı Sandviç', 'p_start': 140, 'p_end': 143},
    {'id': 'hindi_fume_lavas', 'title': 'Lavaş Ekmeğine Sarılı Hindi Füme Dürüm', 'p_start': 144, 'p_end': 147},
    {'id': 'bol_peynirli_pogaca', 'title': 'Bol Peynirli Poğaça', 'p_start': 152, 'p_end': 159},
    {'id': 'minik_kekler', 'title': 'Minik Kekler (Muffin)', 'p_start': 160, 'p_end': 167},
    {'id': 'cikolata_toplari', 'title': 'Çikolata Topları', 'p_start': 168, 'p_end': 173},
    {'id': 'gulen_yuz_kurabiye', 'title': 'Gülen Yüz Kurabiye', 'p_start': 174, 'p_end': 181},
]

def save_pixmap(pix, path, max_dim=250):
    if pix.colorspace and pix.colorspace.n >= 4:
        pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
    img_data = pix.tobytes("png")
    im = Image.open(BytesIO(img_data))
    if im.mode not in ('RGB', 'RGBA'):
        im = im.convert('RGB')
    w, h = im.size
    if max(w, h) > max_dim:
        scale = max_dim / float(max(w, h))
        im = im.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)
    im.save(path, 'PNG', optimize=True)

# 1. First, make sure ispanak_corbasi has proper images and alias files so nothing ever breaks
# We already have: ing_ispanak.png, ing_sogan.png, ing_patates.png, ing_su.png, ing_tuz.png, ing_karabiber.png, ing_yag.png
# Let's also create aliases ing_kuru.png -> ing_sogan.png, ing_temiz.png -> ing_su.png, ing_sıvı.png -> ing_yag.png just in case!
aliases = [
    ('ing_sogan.png', 'ing_kuru.png'),
    ('ing_su.png', 'ing_temiz.png'),
    ('ing_yag.png', 'ing_sıvı.png'),
    ('ing_yag.png', 'ing_sivi.png'),
]
for src, dst in aliases:
    src_p = os.path.join(OUTPUT_DIR, src)
    dst_p = os.path.join(OUTPUT_DIR, dst)
    if os.path.exists(src_p) and not os.path.exists(dst_p):
        with open(src_p, 'rb') as f_in, open(dst_p, 'wb') as f_out:
            f_out.write(f_in.read())
        print(f"Created alias {dst} from {src}")

# 2. Extract ingredient images for all recipes from their cover page
for rdef in recipe_defs:
    rec_id = rdef['id']
    p_start = rdef['p_start']
    page = doc[p_start - 1]
    
    # Get all ingredient images on the right half (x > 450, y < 440, size reasonable)
    images = []
    for img in page.get_images():
        xref = img[0]
        for r in page.get_image_rects(xref):
            if r.x0 > 450 and r.y0 < 440 and 20 < r.width < 140 and 20 < r.height < 120:
                images.append((r, xref))
                
    # Sort by left column (x < 600) then right column (x >= 600)
    left_imgs = [item for item in images if item[0].x0 < 600]
    right_imgs = [item for item in images if item[0].x0 >= 600]
    left_imgs.sort(key=lambda item: item[0].y0)
    right_imgs.sort(key=lambda item: item[0].y0)
    sorted_images = left_imgs + right_imgs
    
    print(f"[{rec_id}] Extracting {len(sorted_images)} ingredient images...")
    for idx, (r, xref) in enumerate(sorted_images):
        target_path = os.path.join(OUTPUT_DIR, f"ing_{rec_id}_{idx+1}.png")
        try:
            pix = pymupdf.Pixmap(doc, xref)
            save_pixmap(pix, target_path)
        except Exception as e:
            # Fallback to clip
            pix = page.get_pixmap(clip=r, dpi=150)
            save_pixmap(pix, target_path)
            
print("All ingredient images extracted successfully!")
