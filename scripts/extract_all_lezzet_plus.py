import json
import pymupdf
import re
import os
import sys
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

# Ensure assets directory exists
OUTPUT_IMG_DIR = os.path.join('assets', 'images', 'lezzet')
os.makedirs(OUTPUT_IMG_DIR, exist_ok=True)

doc = pymupdf.open('lezzet_kitabi.pdf')

recipe_defs = [
    {
        'id': 'ispanak_corbasi',
        'title': 'Ispanak Çorbası',
        'category': 'Çorbalar',
        'subtitle': 'Temel Reis\'in vazgeçilmez enerji deposu olan ıspanakla hem lezzetli hem de besleyici enfes bir çorba!',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '25 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF16A34A',
        'icon': 'Icons.soup_kitchen_rounded',
        'p_start': 24,
        'p_end': 29,
    },
    {
        'id': 'sebze_corbasi',
        'title': 'Sebze Çorbası',
        'category': 'Çorbalar',
        'subtitle': 'Havuç, patates ve bezelyenin bir araya geldiği bu muhteşem tarif gerçek bir enerji deposu! Üstelik hazırlaması da çok kolay!',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '25 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFFEA580C',
        'icon': 'Icons.soup_kitchen_rounded',
        'p_start': 30,
        'p_end': 37,
    },
    {
        'id': 'patates_corbasi',
        'title': 'Patates Çorbası',
        'category': 'Çorbalar',
        'subtitle': 'Mutfakların olmazsa olmaz sebzesi patates ile çok kısa sürede lezzetli bir çorba hazırlayabilirsiniz.',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '25 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFFCA8A04',
        'icon': 'Icons.soup_kitchen_rounded',
        'p_start': 38,
        'p_end': 43,
    },
    {
        'id': 'brokoli_corbasi',
        'title': 'Brokoli Çorbası',
        'category': 'Çorbalar',
        'subtitle': 'Sevdiklerinize sıcacık ve lezzetli bir çorba sunmak için brokoli ile harika bir tarif hazırlıyoruz.',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '25 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF059669',
        'icon': 'Icons.soup_kitchen_rounded',
        'p_start': 44,
        'p_end': 53,
    },
    {
        'id': 'tavuklu_sezar_salata',
        'title': 'Tavuklu Sezar Salata',
        'category': 'Salatalar',
        'subtitle': 'Çıtır kruton ekmekleri, ızgara tavuk dilimleri ve enfes sosuyla restoran lezzetinde muhteşem bir salata.',
        'portions': '4 Kişilik',
        'prep_time': '20 Dakika',
        'cook_time': '15 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF2563EB',
        'icon': 'Icons.eco_rounded',
        'p_start': 56,
        'p_end': 61,
    },
    {
        'id': 'roka_salatasi',
        'title': 'Roka Salatası',
        'category': 'Salatalar',
        'subtitle': 'Domatesin kırmızısıyla renklenen yemyeşil ve taptaze bir vitamin şöleni! Roka ve peynirin mükemmel uyumu.',
        'portions': '4 Kişilik',
        'prep_time': '20 Dakika',
        'cook_time': '0 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF15803D',
        'icon': 'Icons.eco_rounded',
        'p_start': 62,
        'p_end': 67,
    },
    {
        'id': 'beyaz_peynirli_makarna',
        'title': 'Beyaz Peynirli ve Kremalı Dirsek Makarna',
        'category': 'Makarnalar',
        'subtitle': 'Makarnayı kim sevmez ki? Bu tarifte brokoli ve karnabahar gibi besleyici sebzeleri enfes beyaz peynir sosuyla buluşturduk.',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '25 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFFD97706',
        'icon': 'Icons.dinner_dining_rounded',
        'p_start': 72,
        'p_end': 79,
    },
    {
        'id': 'kuru_domatesli_makarna',
        'title': 'Kuru Domates ve Ispanaklı Kelebek Makarna',
        'category': 'Makarnalar',
        'subtitle': 'Güneşte kurutulmuş domatesler ve taze ıspanak yapraklarıyla rengarenk kelebek makarnalar sofrada!',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '20 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFFDC2626',
        'icon': 'Icons.dinner_dining_rounded',
        'p_start': 80,
        'p_end': 87,
    },
    {
        'id': 'mantar_soslu_makarna',
        'title': 'Mantar Soslu Penne Makarna',
        'category': 'Makarnalar',
        'subtitle': 'Muhteşem bir kremalı mantar sosu yapmaya hazır mısın? Penne makarna ile buluşan enfes lezzet.',
        'portions': '4 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '15 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF9333EA',
        'icon': 'Icons.dinner_dining_rounded',
        'p_start': 88,
        'p_end': 95,
    },
    {
        'id': 'caprese_sandvic',
        'title': 'Caprese Sandviç',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Peynir, domates ve fesleğenin buluştuğu çok kısa sürede hazırlayabileceğin nefis ve taze bir İtalyan klasiği!',
        'portions': '1 Kişilik',
        'prep_time': '15 Dakika',
        'cook_time': '0 Dakika',
        'difficulty': 'Çok Kolay',
        'theme_color': '0xFFE11D48',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 100,
        'p_end': 103,
    },
    {
        'id': 'club_sandvic',
        'title': 'Club Sandviç',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Tost ekmekleri arasında kat kat tavuk, kaşar ve taze sebzelerle hazırlanan zengin ve doyurucu bir sandviç.',
        'portions': '1 Kişilik',
        'prep_time': '20 Dakika',
        'cook_time': '10 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF0284C7',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 104,
        'p_end': 111,
    },
    {
        'id': 'hamburger',
        'title': 'Hamburger',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Evde kendi ellerinle hazırlayacağın nefis bir hamburger köftesi, eriyen peynir ve taze garnitürler.',
        'portions': '1 Kişilik',
        'prep_time': '35 Dakika',
        'cook_time': '20 Dakika',
        'difficulty': 'Orta',
        'theme_color': '0xFFB45309',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 112,
        'p_end': 119,
    },
    {
        'id': 'keci_peynirli_sandvic',
        'title': 'Keçi Peynirli Izgara Sebzeli Sandviç',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Keçi peyniri ve ızgara sebzeler bu sağlıklı sandviçte bir araya geliyor. Üstelik pesto sos ile çok lezzetli!',
        'portions': '1 Kişilik',
        'prep_time': '25 Dakika',
        'cook_time': '10 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF0D9488',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 120,
        'p_end': 127,
    },
    {
        'id': 'kumru_sandvic',
        'title': 'Kumru Sandviç',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'İzmir\'in meşhur lezzeti! Bol malzemeli sucuk, salam ve eritilmiş kaşar peyniriyle sıcacık bir lezzet şöleni.',
        'portions': '1 Kişilik',
        'prep_time': '20 Dakika',
        'cook_time': '10 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFFE11D48',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 128,
        'p_end': 135,
    },
    {
        'id': 'tavuk_fume_sandvic',
        'title': 'Tavuk Füme Sandviç',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Pratik ve doyurucu bir tarif! İster kahvaltıda ister ara öğünde hızlıca hazırlayabilirsin.',
        'portions': '1 Kişilik',
        'prep_time': '15 Dakika',
        'cook_time': '0 Dakika',
        'difficulty': 'Çok Kolay',
        'theme_color': '0xFF4F46E5',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 136,
        'p_end': 139,
    },
    {
        'id': 'ton_balikli_sandvic',
        'title': 'Ton Balıklı Sandviç',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Karnın acıktığında çok kısa sürede hazırlanan, omega-3 zengini lezzetli bir ton balıklı sandviç.',
        'portions': '1 Kişilik',
        'prep_time': '15 Dakika',
        'cook_time': '0 Dakika',
        'difficulty': 'Çok Kolay',
        'theme_color': '0xFF0284C7',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 140,
        'p_end': 143,
    },
    {
        'id': 'hindi_fume_lavas',
        'title': 'Lavaş Ekmeğine Sarılı Hindi Füme Dürüm',
        'category': 'Sandviçler & Burgerler',
        'subtitle': 'Az malzemeyle bol lezzetli bir dürüm hazırlamak mümkün! İncecik lavaş ekmeği ve hindi füme buluşması.',
        'portions': '1 Kişilik',
        'prep_time': '15 Dakika',
        'cook_time': '0 Dakika',
        'difficulty': 'Çok Kolay',
        'theme_color': '0xFF7C3AED',
        'icon': 'Icons.lunch_dining_rounded',
        'p_start': 144,
        'p_end': 147,
    },
    {
        'id': 'bol_peynirli_pogaca',
        'title': 'Bol Peynirli Poğaça',
        'category': 'Tatlılar & Hamur İşleri',
        'subtitle': 'Dereotu ve peynirin buluştuğu muhteşem bir tarif... Fırından yeni çıkmış sıcacık mis gibi poğaçalar!',
        'portions': '4 Kişilik',
        'prep_time': '35 Dakika',
        'cook_time': '20 Dakika',
        'difficulty': 'Orta',
        'theme_color': '0xFFD97706',
        'icon': 'Icons.bakery_dining_rounded',
        'p_start': 152,
        'p_end': 159,
    },
    {
        'id': 'minik_kekler',
        'title': 'Minik Kekler (Muffin)',
        'category': 'Tatlılar & Hamur İşleri',
        'subtitle': 'Bu keklerin minicik durduğuna bakmayın, hepsinin içi lezzet dolu! Kokusu tüm mutfağı saracak.',
        'portions': '4 Kişilik',
        'prep_time': '30 Dakika',
        'cook_time': '25 Dakika',
        'difficulty': 'Orta',
        'theme_color': '0xFFDB2777',
        'icon': 'Icons.cake_rounded',
        'p_start': 160,
        'p_end': 167,
    },
    {
        'id': 'cikolata_toplari',
        'title': 'Çikolata Topları',
        'category': 'Tatlılar & Hamur İşleri',
        'subtitle': 'Hepimizin çok sevdiği çikolatayla top top lezzetler hazırlıyoruz. Hem yapması çok eğlenceli hem çok leziz!',
        'portions': '4 Kişilik',
        'prep_time': '30 Dakika',
        'cook_time': '0 Dakika',
        'difficulty': 'Kolay',
        'theme_color': '0xFF78350F',
        'icon': 'Icons.cookie_rounded',
        'p_start': 168,
        'p_end': 173,
    },
    {
        'id': 'gulen_yuz_kurabiye',
        'title': 'Gülen Yüz Kurabiye',
        'category': 'Tatlılar & Hamur İşleri',
        'subtitle': 'Gülümseyen kurabiyelerle hem kendimizi hem de sevdiklerimizi mutlu ediyoruz! Pudra şekeri ve reçel dolgulu kurabiyeler.',
        'portions': '4 Kişilik',
        'prep_time': '30 Dakika',
        'cook_time': '15 Dakika',
        'difficulty': 'Orta',
        'theme_color': '0xFFEAB308',
        'icon': 'Icons.sentiment_very_satisfied_rounded',
        'p_start': 174,
        'p_end': 181,
    },
]

def clean_tr_text(text):
    if not text:
        return ""
    text = text.replace('\n', ' ')
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def save_pixmap_as_rgb_jpg(pix, target_path, max_dim=640, quality=82):
    if os.path.exists(target_path) and os.path.getsize(target_path) > 1000:
        return
    # Convert colorspace to RGB if not already
    if pix.colorspace and pix.colorspace.n >= 4:
        pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
    elif pix.colorspace is None:
        pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
        
    img_data = pix.tobytes("jpeg")
    from io import BytesIO
    im = Image.open(BytesIO(img_data))
    if im.mode != 'RGB':
        im = im.convert('RGB')
    
    # Resize keeping aspect ratio
    w, h = im.size
    if max(w, h) > max_dim:
        scale = max_dim / float(max(w, h))
        new_w = int(w * scale)
        new_h = int(h * scale)
        im = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    im.save(target_path, 'JPEG', quality=quality, optimize=True)

print(f"Starting extraction for {len(recipe_defs)} recipes from lezzet_kitabi.pdf...", flush=True)

all_extracted_recipes = []

for rdef in recipe_defs:
    rec_id = rdef['id']
    p_start = rdef['p_start']
    p_end = rdef['p_end']
    
    print(f"\n---> Processing [{rec_id}]: {rdef['title']} (Pages {p_start}-{p_end})", flush=True)
    
    # 1. EXTRACT COVER HERO IMAGE
    cover_page = doc[p_start - 1]
    cover_img_path = f"assets/images/lezzet/cover_{rec_id}.jpg"
    full_cover_path = os.path.join(OUTPUT_IMG_DIR, f"cover_{rec_id}.jpg")
    
    cover_found = False
    for img in cover_page.get_images():
        xref = img[0]
        rects = cover_page.get_image_rects(xref)
        if rects:
            r = rects[0]
            # Hero image on left side with height > 180
            if r.x0 < 160 and r.height > 180:
                pix = pymupdf.Pixmap(doc, xref)
                save_pixmap_as_rgb_jpg(pix, full_cover_path, max_dim=800, quality=85)
                cover_found = True
                print(f"  Extracted Cover Image: {cover_img_path} ({pix.width}x{pix.height})", flush=True)
                break
                
    if not cover_found:
        # Fallback: render the left half of the cover page
        rect = pymupdf.Rect(60, 230, 430, 690)
        pix = cover_page.get_pixmap(clip=rect, dpi=150)
        save_pixmap_as_rgb_jpg(pix, full_cover_path, max_dim=800, quality=85)
        print(f"  Rendered fallback Cover Image: {cover_img_path}", flush=True)

    # 2. EXTRACT INGREDIENTS & TOOLS
    ingredients = []
    tools = []
    
    cover_blocks = cover_page.get_text('blocks')
    right_blocks = [b for b in cover_blocks if (b[0] + b[2])/2 > 450]
    right_blocks.sort(key=lambda b: b[1])
    
    in_tools = False
    for b in right_blocks:
        txt = b[4].strip()
        lines = [l.strip() for l in txt.split('\n') if l.strip()]
        for l in lines:
            if any(w in l for w in ['Araçlar', 'Aralar']):
                in_tools = True
                continue
            if l.isdigit() or any(w in l for w in ['Dakika', 'Kişilik', 'MALZEME', 'Malzeme']):
                continue
            clean_line = clean_tr_text(l)
            if len(clean_line) > 2:
                if in_tools:
                    tools.append(clean_line)
                else:
                    ingredients.append(clean_line)

    ingredients = list(dict.fromkeys(ingredients))
    tools = list(dict.fromkeys(tools))
    
    # 3. EXTRACT STEP-BY-STEP INSTRUCTIONS AND IMAGES
    steps = []
    step_num = 1
    
    rows = [(50, 270), (270, 480), (480, 700)]
    cols = [(50, 290), (290, 520), (520, 760)]
    
    for pno in range(p_start + 1, p_end + 1):
        page = doc[pno - 1]
        
        # For each cell in 3x3 grid
        for r_idx, (y_min, y_max) in enumerate(rows):
            for c_idx, (x_min, x_max) in enumerate(cols):
                # 1. Find image in this cell
                cell_img = None
                for img in page.get_images():
                    xref = img[0]
                    rects = page.get_image_rects(xref)
                    if rects:
                        r = rects[0]
                        cx, cy = (r.x0 + r.x1)/2, (r.y0 + r.y1)/2
                        if x_min <= cx < x_max and y_min <= cy < y_max:
                            if r.width > 80 and r.height > 60:
                                cell_img = (xref, r)
                                break
                                
                # 2. Find instruction text in this cell
                cell_texts = []
                for b in page.get_text('blocks'):
                    cx, cy = (b[0] + b[2])/2, (b[1] + b[3])/2
                    txt = b[4].strip()
                    if x_min <= cx < x_max and y_min <= cy < y_max:
                        # Exclude isolated numbers, page titles, footer logos
                        if not txt.isdigit() and len(txt) > 2:
                            upper = txt.upper()
                            if not any(ign in upper for ign in ['AFİYET OLSUN', 'AKLINIZDA BULUNSUN', 'FAYDALI PÜF', 'PÜF NOKTALARI', rdef['title'].upper()]):
                                # In the lower portion of the cell
                                if cy > (y_min + y_max)/2:
                                    cell_texts.append(txt.replace('\n', ' '))
                
                # If we found an image or text in this grid slot, it's a step!
                if cell_img or cell_texts:
                    instruction = clean_tr_text(' '.join(cell_texts))
                    
                    # Extract and save step image
                    step_img_rel_path = f"assets/images/lezzet/step_{rec_id}_{step_num}.jpg"
                    full_step_path = os.path.join(OUTPUT_IMG_DIR, f"step_{rec_id}_{step_num}.jpg")
                    
                    if cell_img:
                        try:
                            pix = pymupdf.Pixmap(doc, cell_img[0])
                            save_pixmap_as_rgb_jpg(pix, full_step_path, max_dim=600, quality=82)
                        except Exception as e:
                            # fallback: render the image rect
                            r = cell_img[1]
                            pix = page.get_pixmap(clip=r, dpi=130)
                            save_pixmap_as_rgb_jpg(pix, full_step_path, max_dim=600, quality=82)
                    else:
                        # If no embedded image object, render the cell area
                        rect = pymupdf.Rect(x_min, y_min, x_max, y_min + 175)
                        pix = page.get_pixmap(clip=rect, dpi=130)
                        save_pixmap_as_rgb_jpg(pix, full_step_path, max_dim=600, quality=82)
                    
                    # Detect timer in instruction (e.g. '15 dakika bekle', '7 dakika pişir', '2 dakika karıştır')
                    timer_seconds = None
                    timer_label = None
                    min_match = re.search(r'(\d+)\s*dakika', instruction, re.IGNORECASE)
                    if min_match:
                        mins = int(min_match.group(1))
                        if 1 <= mins <= 60:
                            timer_seconds = mins * 60
                            if any(w in instruction.lower() for w in ['pişir', 'kaynat', 'haşla']):
                                timer_label = f'{mins} Dakika Pişirme'
                            elif any(w in instruction.lower() for w in ['bekle', 'dinlendir']):
                                timer_label = f'{mins} Dakika Bekleme'
                            elif any(w in instruction.lower() for w in ['karıştır']):
                                timer_label = f'{mins} Dakika Karıştırma'
                            else:
                                timer_label = f'{mins} Dakika Süre'
                                
                    steps.append({
                        'step_number': step_num,
                        'instruction': instruction if instruction else f'Adım {step_num} hazırlığını tamamla.',
                        'image_path': step_img_rel_path,
                        'timer_seconds': timer_seconds,
                        'timer_label': timer_label,
                    })
                    
                    step_num += 1

    # 4. EXTRACT CHEF TIPS (Püf noktaları) from final page
    tips = []
    end_page = doc[p_end - 1]
    for b in end_page.get_text('blocks'):
        txt = b[4].strip()
        if '*' in txt or '•' in txt or 'FAYDALI' in txt.upper() or 'AKLINIZDA' in txt.upper():
            lines = [l.strip() for l in txt.split('\n') if l.strip()]
            for l in lines:
                if l.startswith('*') or l.startswith('•') or l.startswith('-'):
                    tip_clean = clean_tr_text(l.lstrip('*•- '))
                    if len(tip_clean) > 10:
                        tips.append(tip_clean)
                        
    tips = list(dict.fromkeys(tips))
    
    print(f"  Summary: {len(ingredients)} ingredients, {len(tools)} tools, {len(steps)} steps, {len(tips)} tips.", flush=True)
    
    all_extracted_recipes.append({
        'id': rec_id,
        'title': rdef['title'],
        'category': rdef['category'],
        'subtitle': rdef['subtitle'],
        'portions': rdef['portions'],
        'prep_time': rdef['prep_time'],
        'cook_time': rdef['cook_time'],
        'difficulty': rdef['difficulty'],
        'theme_color': rdef['theme_color'],
        'icon': rdef['icon'],
        'cover_image_path': cover_img_path,
        'ingredients': ingredients,
        'tools': tools,
        'steps': steps,
        'chef_tips': tips,
    })

# Save JSON data
with open('scripts/extracted_recipes.json', 'w', encoding='utf-8') as f:
    json.dump(all_extracted_recipes, f, ensure_ascii=False, indent=2)

print("\nAll 21 recipes successfully extracted and saved to scripts/extracted_recipes.json!", flush=True)
