import re
import os

with open('lib/data/lezzet_plus_recipes.dart', 'r', encoding='utf-8') as f:
    text = f.read()

paths = sorted(set(re.findall(r'assets/images/lezzet/ing_[^\'"]+', text)))
missing = [p for p in paths if not os.path.exists(p)]
print(f"Total unique ingredient image paths: {len(paths)}")
print(f"Missing count: {len(missing)}")
if missing:
    for m in missing:
        print(f"  MISSING: {m}")
else:
    print("ALL ingredient images exist on disk!")
