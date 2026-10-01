import 'package:flutter/material.dart';
import '../models/kitchen_recipe.dart';

class LezzetPlusRecipes {
  static List<KitchenRecipe> getRecipes() {
    return [
      // 1. ISPANAK ÇORBASI (Lezzet +1 Kitabı Sayfa 24-29)
      KitchenRecipe(
        id: 'ispanak_corbasi',
        title: 'Ispanak Çorbası',
        category: 'Çorbalar',
        subtitle:
            'Temel Reis\'in vazgeçilmez enerji deposu olan ıspanakla hem lezzetli hem de besleyici enfes bir çorba!',
        portions: '4 Kişilik',
        prepTime: '25 Dakika',
        cookTime: '25 Dakika',
        difficulty: 'Kolay',
        icon: Icons.soup_kitchen_rounded,
        themeColor: const Color(0xFF16A34A), // Ispanak Yeşili
        coverImagePath: 'assets/images/lezzet/ispanak_corbasi_cover.png',
        ingredients: [
          RecipeCheckItem(
            id: 'isp_ing_1',
            name: 'Ispanak',
            amount: 'Yarım kilo',
            icon: Icons.eco_rounded,
            imagePath: 'assets/images/lezzet/ing_ispanak.png',
          ),
          RecipeCheckItem(
            id: 'isp_ing_2',
            name: 'Kuru Soğan',
            amount: '1 adet',
            icon: Icons.circle_rounded,
            imagePath: 'assets/images/lezzet/ing_sogan.png',
          ),
          RecipeCheckItem(
            id: 'isp_ing_3',
            name: 'Patates',
            amount: '1 adet',
            icon: Icons.egg_rounded,
            imagePath: 'assets/images/lezzet/ing_patates.png',
          ),
          RecipeCheckItem(
            id: 'isp_ing_4',
            name: 'Temiz Su',
            amount: '3 su bardağı',
            icon: Icons.water_drop_rounded,
            imagePath: 'assets/images/lezzet/ing_su.png',
          ),
          RecipeCheckItem(
            id: 'isp_ing_5',
            name: 'Tuz',
            amount: '1 çay kaşığı',
            icon: Icons.grain_rounded,
            imagePath: 'assets/images/lezzet/ing_tuz.png',
          ),
          RecipeCheckItem(
            id: 'isp_ing_6',
            name: 'Karabiber',
            amount: '1 tutam',
            icon: Icons.scatter_plot_rounded,
            imagePath: 'assets/images/lezzet/ing_karabiber.png',
          ),
          RecipeCheckItem(
            id: 'isp_ing_7',
            name: 'Sıvı Yağ',
            amount: '3 yemek kaşığı',
            icon: Icons.opacity_rounded,
            imagePath: 'assets/images/lezzet/ing_yag.png',
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'isp_tool_1',
            name: 'Su Bardağı',
            amount: '1 adet',
            icon: Icons.local_drink_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_2',
            name: 'Kesme Tahtası',
            amount: '1 adet',
            icon: Icons.crop_landscape_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_3',
            name: 'Yemek Bıçağı',
            amount: '1 adet',
            icon: Icons.restaurant_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_4',
            name: 'Çay Kaşığı',
            amount: '1 adet',
            icon: Icons.soup_kitchen_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_5',
            name: 'Çorba Kepçesi',
            amount: '1 adet',
            icon: Icons.soup_kitchen_outlined,
          ),
          RecipeCheckItem(
            id: 'isp_tool_6',
            name: 'Çorba Tenceresi',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_7',
            name: 'Çay Bardağı',
            amount: '1 adet',
            icon: Icons.local_cafe_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_8',
            name: 'Soyma Aleti (Soyacak)',
            amount: '1 adet',
            icon: Icons.cut_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_9',
            name: 'Mutfak Saati / Kronometre',
            amount: '1 adet',
            icon: Icons.timer_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_10',
            name: 'Su Sürahisi',
            amount: '1 adet',
            icon: Icons.water_damage_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_11',
            name: 'Tahta Yemek Kaşığı',
            amount: '1 adet',
            icon: Icons.flatware_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_12',
            name: 'Hazırlık Kasesi',
            amount: '2 adet',
            icon: Icons.rice_bowl_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_13',
            name: 'El Robotu (Blender)',
            amount: '1 adet',
            icon: Icons.blender_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_14',
            name: 'Mutfak Robotu',
            amount: '1 adet',
            icon: Icons.kitchen_rounded,
          ),
          RecipeCheckItem(
            id: 'isp_tool_15',
            name: 'Büyük Yıkama Kabı / Süzgeç',
            amount: '1 adet',
            icon: Icons.filter_alt_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla en az 20 saniye yıka ve kurula.',
            tip: 'Temiz eller hijyenik yemek yapmanın ilk adımıdır.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Kesme tahtasını ve yemek bıçağını tezgaha güvenle yerleştir.',
            icon: Icons.crop_landscape_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Soğanın kabuklarını soyma aleti veya parmaklarınla dikkatlice soy.',
            icon: Icons.circle_outlined,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Soğanı kesme tahtasında küçük küçük küpler halinde doğra.',
            tip: 'Bıçak kullanırken parmaklarını içeriye doğru kıvırarak tut.',
            icon: Icons.restaurant_rounded,
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Doğradığın soğanları birinci kaseye koy ve kenara al.',
            icon: Icons.rice_bowl_rounded,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Patatesi temiz soğuk suyun altında yıka.',
            icon: Icons.shower_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Patatesin kabuğunu soyma aletiyle dikkatlice soy.',
            icon: Icons.cut_rounded,
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'Soyduğun patatesi kesme tahtasında küçük küpler halinde doğra.',
            icon: Icons.dashboard_customize_rounded,
          ),
          RecipeStepItem(
            stepNumber: 9,
            instruction: 'Doğradığın patatesleri ikinci kaseye koy.',
            icon: Icons.rice_bowl_rounded,
          ),
          RecipeStepItem(
            stepNumber: 10,
            instruction: 'Ispanakları ayıkla, sararmış ve çürük yaprakları ayır.',
            icon: Icons.filter_vintage_rounded,
          ),
          RecipeStepItem(
            stepNumber: 11,
            instruction: 'Ayıkladığın ıspanakları süzgece koy, yaprakları soğuk suda tek tek yıka.',
            tip: 'Ispanakların tamamen temizlenmesi çok önemlidir.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 12,
            instruction: 'Ispanakları büyük bir kaba al, kağıt havlu ile kurula.',
            icon: Icons.dry_cleaning_rounded,
          ),
          RecipeStepItem(
            stepNumber: 13,
            instruction: 'Sürahiye 3 su bardağı temiz su doldur.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 14,
            instruction: '1 çay kaşığı tuzu ve 1 tutam karabiberi hazırla.',
            icon: Icons.grain_rounded,
          ),
          RecipeStepItem(
            stepNumber: 15,
            instruction: 'Çay bardağına 3 yemek kaşığı sıvı yağı ölçerek koy.',
            icon: Icons.opacity_rounded,
          ),
          RecipeStepItem(
            stepNumber: 16,
            instruction: 'Tencereyi ve tahta yemek kaşığını ocağın yanına hazırla.',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeStepItem(
            stepNumber: 17,
            instruction: 'Tüm malzemelerin ve araçların tam olduğunu kontrol listenden onayla.',
            icon: Icons.checklist_rtl_rounded,
          ),
          RecipeStepItem(
            stepNumber: 18,
            instruction: 'Ocağın altını orta ateşte yak (Gerekirse bir yetişkinden yardım iste).',
            tip: 'Ocağın ateşine asla doğrudan dokunma.',
            icon: Icons.local_fire_department_rounded,
            imagePath: 'assets/images/lezzet/step_19.png',
          ),
          RecipeStepItem(
            stepNumber: 19,
            instruction: 'Tencereyi al ve dikkatlice ocağın üzerine koy.',
            icon: Icons.pan_tool_alt_rounded,
            imagePath: 'assets/images/lezzet/step_20.png',
          ),
          RecipeStepItem(
            stepNumber: 20,
            instruction: 'Tencereye 3 yemek kaşığı sıvı yağı dök. Yağın ısınması için 1 dakika bekle.',
            tip: 'Aşağıdaki sayacı başlatarak 1 dakikayı takip edebilirsin.',
            icon: Icons.timer_rounded,
            timerSeconds: 60,
            timerLabel: '1 Dakika Yağ Isınma Sayacı',
            imagePath: 'assets/images/lezzet/step_21.png',
          ),
          RecipeStepItem(
            stepNumber: 21,
            instruction: 'Kasedeki doğranmış soğanları tencereye boşalt.',
            icon: Icons.soup_kitchen_rounded,
            imagePath: 'assets/images/lezzet/step_22.png',
          ),
          RecipeStepItem(
            stepNumber: 22,
            instruction: 'Soğanları tahta kaşıkla 2 dakika boyunca karıştırarak kavur.',
            tip: 'Soğanlar hafif şeffaflaşana kadar tahta kaşıkla karıştır.',
            icon: Icons.loop_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dakika Soğan Kavurma Sayacı',
            imagePath: 'assets/images/lezzet/step_23.png',
          ),
          RecipeStepItem(
            stepNumber: 23,
            instruction: 'Temizlenmiş ıspanakları tencereye ekle.',
            icon: Icons.eco_rounded,
            imagePath: 'assets/images/lezzet/step_24.png',
          ),
          RecipeStepItem(
            stepNumber: 24,
            instruction: 'Kasedeki küp patatesleri tencereye ekle.',
            icon: Icons.egg_rounded,
            imagePath: 'assets/images/lezzet/step_25.png',
          ),
          RecipeStepItem(
            stepNumber: 25,
            instruction: 'Sürahideki 3 su bardağı suyu tencerenin içine dikkatlice dök.',
            icon: Icons.water_drop_rounded,
            imagePath: 'assets/images/lezzet/step_26.png',
          ),
          RecipeStepItem(
            stepNumber: 26,
            instruction: 'Tencereye 1 çay kaşığı tuzu dök.',
            icon: Icons.grain_rounded,
            imagePath: 'assets/images/lezzet/step_27.png',
          ),
          RecipeStepItem(
            stepNumber: 27,
            instruction: 'Tencereye 1 tutam karabiber dök.',
            icon: Icons.scatter_plot_rounded,
            imagePath: 'assets/images/lezzet/step_28.png',
          ),
          RecipeStepItem(
            stepNumber: 28,
            instruction: 'Hepsini tahta kaşıkla güzelce karıştır.',
            icon: Icons.sync_rounded,
            imagePath: 'assets/images/lezzet/step_29.png',
          ),
          RecipeStepItem(
            stepNumber: 29,
            instruction: 'Tencerenin kapağını dikkatlice kapat.',
            icon: Icons.shield_rounded,
            imagePath: 'assets/images/lezzet/step_30.png',
          ),
          RecipeStepItem(
            stepNumber: 30,
            instruction: 'Ocağın altını kısık ateşe ayarla.',
            icon: Icons.whatshot_rounded,
            imagePath: 'assets/images/lezzet/step_31.png',
          ),
          RecipeStepItem(
            stepNumber: 31,
            instruction: 'Çorbanın iyice pişmesi için kapağı kapalı şekilde 15 dakika bekle.',
            tip: 'Sayacı başlat! Süre dolduğunda alarm seni uyaracak.',
            icon: Icons.timer_rounded,
            timerSeconds: 900,
            timerLabel: '15 Dakika Pişirme Sayacı',
            imagePath: 'assets/images/lezzet/step_32.png',
          ),
          RecipeStepItem(
            stepNumber: 32,
            instruction: 'Tencerenin kapağını dikkatlice aç. El robotunu (blender) dik tutarak çorbayı pürüzsüz hale getir.',
            tip: 'El robotunu dik tutmak ve sıçratmamak çok önemlidir.',
            icon: Icons.blender_rounded,
            imagePath: 'assets/images/lezzet/step_33.png',
          ),
          RecipeStepItem(
            stepNumber: 33,
            instruction: 'Ocağın altını kapat.',
            tip: 'Ocağın kapalı olduğundan emin ol.',
            icon: Icons.power_settings_new_rounded,
            imagePath: 'assets/images/lezzet/step_34.png',
          ),
          RecipeStepItem(
            stepNumber: 34,
            instruction: 'Çorban servise hazır! Çorba kepçesi ile kaselere doldur. Afiyet olsun!',
            icon: Icons.emoji_events_rounded,
            imagePath: 'assets/images/lezzet/ispanak_corbasi_cover.png',
          ),
        ],
        chefTips: const [
          'Ispanakları iyice temizlemek için yıkadıktan sonra sirkeli suda bekletebilirsin. Evde sirke yoksa tuz ve karbonat kullanabilirsin!',
          'Kalan ıspanakları güzelce kurut, buzdolabı poşetlerine koy ve buzlukta sakla.',
          'Ispanak çorbasını servis ederken yanına fırında kızarmış çıtır ekmek dilimleri ilave edebilirsin!',
          'Ispanak çok besleyici bir kış sebzesidir; A ve C vitaminleri bakımından zengindir.',
        ],
      ),

      // 2. SEBZE ÇORBASI (Lezzet +1 Kitabı Sayfa 30-37)
      KitchenRecipe(
        id: 'sebze_corbasi',
        title: 'Vitamin Deposu Sebze Çorbası',
        category: 'Çorbalar',
        subtitle:
            'Havuç, patates ve bezelyenin bir araya geldiği, sıcacık ve bol vitaminli şifa kaynağı!',
        portions: '4 Kişilik',
        prepTime: '20 Dakika',
        cookTime: '25 Dakika',
        difficulty: 'Kolay',
        icon: Icons.soup_kitchen_rounded,
        themeColor: const Color(0xFFEA580C), // Havuç Turuncusu
        coverImagePath: 'assets/images/lezzet/sebze_corbasi_thumb.png',
        ingredients: [
          RecipeCheckItem(
            id: 'seb_ing_1',
            name: 'Kuru Soğan',
            amount: '1 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_2',
            name: 'Havuç',
            amount: '1 adet',
            icon: Icons.eco_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_3',
            name: 'Patates',
            amount: '1 adet',
            icon: Icons.egg_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_4',
            name: 'Taze / Dondurulmuş Bezelye',
            amount: '1 kase',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_5',
            name: 'Sıvı Yağ',
            amount: '3 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_6',
            name: 'Temiz Su',
            amount: '4 su bardağı',
            icon: Icons.water_drop_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_7',
            name: 'Tuz',
            amount: '1 çay kaşığı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_ing_8',
            name: 'Karabiber',
            amount: '1 tutam',
            icon: Icons.scatter_plot_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'seb_tool_1',
            name: 'Çorba Tenceresi',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_2',
            name: 'Tahta Kaşık',
            amount: '1 adet',
            icon: Icons.flatware_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_3',
            name: 'Kesme Tahtası',
            amount: '1 adet',
            icon: Icons.crop_landscape_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_4',
            name: 'Yemek Bıçağı',
            amount: '1 adet',
            icon: Icons.restaurant_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_5',
            name: 'Soyma Aleti (Soyacak)',
            amount: '1 adet',
            icon: Icons.cut_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_6',
            name: 'Hazırlık Kaseleri',
            amount: '3 adet',
            icon: Icons.rice_bowl_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_7',
            name: 'Su Sürahisi',
            amount: '1 adet',
            icon: Icons.water_damage_rounded,
          ),
          RecipeCheckItem(
            id: 'seb_tool_8',
            name: 'Mutfak Saati',
            amount: '1 adet',
            icon: Icons.timer_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla 20 saniye güzelce yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Havuç ve patatesi temiz suda yıkayıp soyma aletiyle soy.',
            icon: Icons.cut_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Havucu kesme tahtasında küçük küpler halinde doğra ve kaseye koy.',
            icon: Icons.dashboard_customize_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Patatesi küp küp doğra ve ayrı bir kaseye koy.',
            icon: Icons.egg_rounded,
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Soğanın kabuğunu soyup ince ince yemeklik doğra.',
            icon: Icons.circle_outlined,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Bezelyeleri süzgeçte yıka ve hazırla.',
            icon: Icons.grain_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Sürahiye 4 su bardağı su doldur.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'Ocağı orta ateşte yak ve tencereyi yerleştir.',
            icon: Icons.local_fire_department_rounded,
          ),
          RecipeStepItem(
            stepNumber: 9,
            instruction: 'Tencereye 3 yemek kaşığı sıvı yağ koy. Isınması için 1 dakika bekle.',
            icon: Icons.timer_rounded,
            timerSeconds: 60,
            timerLabel: '1 Dakika Yağ Isınma',
          ),
          RecipeStepItem(
            stepNumber: 10,
            instruction: 'Soğanları tencereye ekle ve tahta kaşıkla 2 dakika kavur.',
            icon: Icons.loop_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dakika Soğan Kavurma',
          ),
          RecipeStepItem(
            stepNumber: 11,
            instruction: 'Kasedeki havuçları tencereye ekle.',
            icon: Icons.eco_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_11.png',
          ),
          RecipeStepItem(
            stepNumber: 12,
            instruction: 'Kasedeki bezelyeleri tencereye ekle.',
            icon: Icons.grain_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_12.png',
          ),
          RecipeStepItem(
            stepNumber: 13,
            instruction: 'Kasedeki patatesleri tencereye ekle.',
            icon: Icons.egg_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_13.png',
          ),
          RecipeStepItem(
            stepNumber: 14,
            instruction: 'Tüm sebzeleri tahta kaşıkla 3 dakika boyunca karıştır.',
            icon: Icons.sync_rounded,
            timerSeconds: 180,
            timerLabel: '3 Dakika Sebzeleri Karıştırma',
            imagePath: 'assets/images/lezzet/sebze_step_14.png',
          ),
          RecipeStepItem(
            stepNumber: 15,
            instruction: 'Sürahideki 4 su bardağı suyu tencereye dikkatlice dök.',
            icon: Icons.water_drop_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_15.png',
          ),
          RecipeStepItem(
            stepNumber: 16,
            instruction: '1 çay kaşığı tuz ve 1 tutam karabiberi ekle.',
            icon: Icons.grain_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_16.png',
          ),
          RecipeStepItem(
            stepNumber: 17,
            instruction: 'Tencerenin kapağını kapat.',
            icon: Icons.shield_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_17.png',
          ),
          RecipeStepItem(
            stepNumber: 18,
            instruction: 'Ocağın altını kısık ateşe getir.',
            icon: Icons.whatshot_rounded,
            imagePath: 'assets/images/lezzet/sebze_step_18.png',
          ),
          RecipeStepItem(
            stepNumber: 19,
            instruction: 'Tencerenin kapağını kapatıp sebzeler yumuşayana kadar 20 dakika bekle.',
            icon: Icons.timer_rounded,
            timerSeconds: 1200,
            timerLabel: '20 Dakika Kısık Ateşte Pişirme',
            imagePath: 'assets/images/lezzet/sebze_step_19.png',
          ),
          RecipeStepItem(
            stepNumber: 20,
            instruction: 'Ocağın altını kapat. İster taneli olarak, istersen blenderdan geçirerek sıcak servis yap. Afiyet olsun!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Patates, havuç, bezelye... Ve işte vitamin deposu bir çorba!',
          'Çorbanı seversen bir parça tereyağı ile daha lezzetli kılabilirsin.',
          'Hazırladığın sıcacık çorbayı zevkine göre taze nane veya dereotu ile süsleyebilirsin.',
        ],
      ),

      // 3. KREmALI PATATES ÇORBASI (Lezzet +1 Kitabı Sayfa 38)
      KitchenRecipe(
        id: 'patates_corbasi',
        title: 'Kremalı Patates Çorbası',
        category: 'Çorbalar',
        subtitle:
            'İpeksi kıvamı ve yumuşacık lezzetiyle kış günlerinin en sevilen sıcacık çorbası.',
        portions: '4 Kişilik',
        prepTime: '15 Dakika',
        cookTime: '20 Dakika',
        difficulty: 'Kolay',
        icon: Icons.soup_kitchen_rounded,
        themeColor: const Color(0xFFCA8A04), // Patates Sarısı
        ingredients: [
          RecipeCheckItem(
            id: 'pat_ing_1',
            name: 'Orta Boy Patates',
            amount: '3 adet',
            icon: Icons.egg_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_ing_2',
            name: 'Kuru Soğan',
            amount: '1 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_ing_3',
            name: 'Sıvı Yağ veya Tereyağı',
            amount: '2 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_ing_4',
            name: 'Süt veya Sıvı Krema',
            amount: '1 çay bardağı',
            icon: Icons.local_cafe_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_ing_5',
            name: 'Su veya Sebze Suyu',
            amount: '4 su bardağı',
            icon: Icons.water_drop_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_ing_6',
            name: 'Tuz ve Karabiber',
            amount: '1 çay kaşığı',
            icon: Icons.grain_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'pat_tool_1',
            name: 'Tencere',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_tool_2',
            name: 'Kesme Tahtası & Bıçak',
            amount: '1 set',
            icon: Icons.restaurant_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_tool_3',
            name: 'Soyacak',
            amount: '1 adet',
            icon: Icons.cut_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_tool_4',
            name: 'El Robotu (Blender)',
            amount: '1 adet',
            icon: Icons.blender_rounded,
          ),
          RecipeCheckItem(
            id: 'pat_tool_5',
            name: 'Tahta Kaşık & Kepçe',
            amount: '1 set',
            icon: Icons.flatware_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka ve kurula.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: '3 adet patatesi soyma aletiyle soyup küp küp doğra.',
            icon: Icons.dashboard_customize_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Soğanı yemeklik küçük küçük doğra.',
            icon: Icons.circle_outlined,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Tencereyi ocağa al, yağı döküp 1 dakika ısıt.',
            icon: Icons.timer_rounded,
            timerSeconds: 60,
            timerLabel: '1 Dk Yağ Isıtma',
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Soğanları ekleyip 2 dakika kavur.',
            icon: Icons.loop_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dk Soğan Kavurma',
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Doğranmış patatesleri tencereye ekle ve 2 dakika karıştır.',
            icon: Icons.egg_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dk Karıştırma',
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: '4 su bardağı suyu dök, tuzunu ekle ve kapağını kapat.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'Patatesler iyice yumuşayana kadar 15 dakika kısık ateşte pişir.',
            icon: Icons.timer_rounded,
            timerSeconds: 900,
            timerLabel: '15 Dk Pişirme',
          ),
          RecipeStepItem(
            stepNumber: 9,
            instruction: 'El robotuyla patatesleri tamamen pürüzsüz kıvama getir.',
            icon: Icons.blender_rounded,
          ),
          RecipeStepItem(
            stepNumber: 10,
            instruction: '1 çay bardağı süt veya kremayı ekleyip karıştır. 2 dakika kaynatıp ocağı kapat.',
            icon: Icons.timer_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dk Kıvam Kaynatma',
          ),
        ],
        chefTips: const [
          'Patates çorbasına kıtır ekmek krutonları çok yakışır.',
          'Üzerine biraz pul biber ve eritilmiş tereyağı gezdirebilirsin.',
        ],
      ),

      // 4. KIRMIZI MERCİMEK ÇORBASI (Lezzet +1 Kitabı Sayfa 42)
      KitchenRecipe(
        id: 'mercimek_corbasi',
        title: 'Geleneksel Kırmızı Mercimek Çorbası',
        category: 'Çorbalar',
        subtitle:
            'Günün her saatinde içimizi ısıtan, sofralarımızın baş tacı klasik mercimek çorbası.',
        portions: '4 Kişilik',
        prepTime: '15 Dakika',
        cookTime: '25 Dakika',
        difficulty: 'Kolay',
        icon: Icons.soup_kitchen_rounded,
        themeColor: const Color(0xFFD97706),
        ingredients: [
          RecipeCheckItem(
            id: 'mer_ing_1',
            name: 'Kırmızı Mercimek',
            amount: '1 su bardağı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_ing_2',
            name: 'Kuru Soğan',
            amount: '1 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_ing_3',
            name: 'Havuç',
            amount: '1 adet',
            icon: Icons.eco_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_ing_4',
            name: 'Sıvı Yağ veya Tereyağı',
            amount: '3 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_ing_5',
            name: 'Sıcak Su',
            amount: '5 su bardağı',
            icon: Icons.water_drop_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_ing_6',
            name: 'Tuz & Nane',
            amount: '1 çay kaşığı',
            icon: Icons.grain_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'mer_tool_1',
            name: 'Tencere',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_tool_2',
            name: 'Süzgeç',
            amount: '1 adet',
            icon: Icons.filter_alt_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_tool_3',
            name: 'El Robotu (Blender)',
            amount: '1 adet',
            icon: Icons.blender_rounded,
          ),
          RecipeCheckItem(
            id: 'mer_tool_4',
            name: 'Tahta Kaşık & Kepçe',
            amount: '1 set',
            icon: Icons.flatware_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: '1 bardak mercimeği süzgeçte berrak su akana kadar yıka.',
            icon: Icons.filter_alt_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Soğan ve havucu soyup küçük küçük doğra.',
            icon: Icons.restaurant_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Tencereye yağı koy, soğan ve havucu 2 dakika sotele.',
            icon: Icons.timer_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dk Soteleme',
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Yıkanmış mercimekleri ve 5 su bardağı sıcak suyu ekle.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Tuzunu ekle, tencerenin kapağını kapat.',
            icon: Icons.shield_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Mercimekler tamamen yumuşayana kadar 20 dakika pişir.',
            icon: Icons.timer_rounded,
            timerSeconds: 1200,
            timerLabel: '20 Dk Pişirme',
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'El robotu ile çorbayı pürüzsüz hale getir.',
            icon: Icons.blender_rounded,
          ),
          RecipeStepItem(
            stepNumber: 9,
            instruction: 'Limon dilimi ve nane ile servis et. Afiyet olsun!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Mercimekleri yıkarken sarı köpüklü su gidene kadar durulamak çorbanın gaz yapmasını engeller.',
          'Servis ederken taze limon sıkmayı unutma!',
        ],
      ),

      // 5. RENKLİ HAVUÇ SALATASI (Lezzet +1 Kitabı Sayfa 54 Salatalar)
      KitchenRecipe(
        id: 'havuc_salatasi',
        title: 'Renkli & Çıtır Havuç Salatası',
        category: 'Salatalar',
        subtitle:
            'Ateş kullanmadan, güvenle hazırlayabileceğiniz göz sağlığına dost leziz ve taptaze bir salata.',
        portions: '2 Kişilik',
        prepTime: '15 Dakika',
        cookTime: '0 Dakika',
        difficulty: 'Çok Kolay',
        icon: Icons.eco_rounded,
        themeColor: const Color(0xFFF97316),
        ingredients: [
          RecipeCheckItem(
            id: 'hav_ing_1',
            name: 'Taze Havuç',
            amount: '3 adet',
            icon: Icons.eco_rounded,
          ),
          RecipeCheckItem(
            id: 'hav_ing_2',
            name: 'Zeytinyağı',
            amount: '2 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'hav_ing_3',
            name: 'Limon Suyu',
            amount: 'Yarım limon',
            icon: Icons.circle_outlined,
          ),
          RecipeCheckItem(
            id: 'hav_ing_4',
            name: 'Tuz',
            amount: 'Yarım çay kaşığı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'hav_ing_5',
            name: 'Kırık Ceviz İçi',
            amount: '1 avuç',
            icon: Icons.scatter_plot_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'hav_tool_1',
            name: 'Sebze Rendesi',
            amount: '1 adet',
            icon: Icons.grid_view_rounded,
          ),
          RecipeCheckItem(
            id: 'hav_tool_2',
            name: 'Geniş Salata Kasesi',
            amount: '1 adet',
            icon: Icons.rice_bowl_rounded,
          ),
          RecipeCheckItem(
            id: 'hav_tool_3',
            name: 'Limon Sıkacağı',
            amount: '1 adet',
            icon: Icons.local_drink_rounded,
          ),
          RecipeCheckItem(
            id: 'hav_tool_4',
            name: 'Salata Kaşığı & Çatalı',
            amount: '1 set',
            icon: Icons.flatware_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla 20 saniye yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Havuçları yıka ve kabuklarını soyacakla soy.',
            icon: Icons.cut_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Sebze rendesinin kalın tarafıyla havuçları salata kasesine rendele.',
            tip: 'Rende yaparken parmaklarını rendeye çok yaklaştırmamaya dikkat et.',
            icon: Icons.grid_view_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Yarım limonu sıkacakta sık ve suyunu havuçların üzerine dök.',
            icon: Icons.opacity_rounded,
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: '2 yemek kaşığı zeytinyağı ve yarım çay kaşığı tuzu ekle.',
            icon: Icons.grain_rounded,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Salata kaşıklarıyla tüm sosu havuçlara iyice karıştır.',
            icon: Icons.sync_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Üzerine ceviz parçalarını serpiştir. Çıtır salatan hazır! Afiyet olsun!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Havuç A vitamini yönünden zengindir ve göz sağlığına büyük katkı sağlar.',
          'İsteğe göre içine 2 kaşık süzme yoğurt ekleyerek yoğurtlu havuç mezesi de yapabilirsin.',
        ],
      ),

      // 6. PRATİK KAŞARLI & DOMATESLİ TOST (Pratik Lezzetler)
      KitchenRecipe(
        id: 'kasarli_tost',
        title: 'Lezzet +1 Kaşarlı & Domatesli Tost',
        category: 'Pratik Lezzetler',
        subtitle:
            'Kahvaltı ve ara öğünlerde kolayca hazırlayabileceğiniz, sıcacık ve nefis tost.',
        portions: '1 Kişilik',
        prepTime: '5 Dakika',
        cookTime: '4 Dakika',
        difficulty: 'Çok Kolay',
        icon: Icons.lunch_dining_rounded,
        themeColor: const Color(0xFF0284C7),
        ingredients: [
          RecipeCheckItem(
            id: 'tost_ing_1',
            name: 'Tost Ekmeği',
            amount: '2 dilim',
            icon: Icons.breakfast_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'tost_ing_2',
            name: 'Kaşar Peyniri',
            amount: '2 dilim',
            icon: Icons.crop_portrait_rounded,
          ),
          RecipeCheckItem(
            id: 'tost_ing_3',
            name: 'Domates',
            amount: '2 ince dilim',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'tost_ing_4',
            name: 'Tereyağı',
            amount: '1 fındık büyüklüğünde',
            icon: Icons.opacity_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'tost_tool_1',
            name: 'Tost Makinesi',
            amount: '1 adet',
            icon: Icons.kitchen_rounded,
          ),
          RecipeCheckItem(
            id: 'tost_tool_2',
            name: 'Servis Tabağı',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'tost_tool_3',
            name: 'Tahta Spatula',
            amount: '1 adet',
            icon: Icons.flatware_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Tost makinesini fişe tak ve ısınması için çalıştır (Büyüğünden yardım al).',
            icon: Icons.power_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Birinci dilim tost ekmeğini tabağa koy.',
            icon: Icons.breakfast_dining_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Üzerine 2 dilim kaşar peyniri ve domates dilimlerini diz.',
            icon: Icons.crop_portrait_rounded,
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'İkinci ekmek dilimini üstüne kapat.',
            icon: Icons.layers_rounded,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Tostu ısınan tost makinesinin içine koy ve kapağını yavaşça kapat.',
            icon: Icons.kitchen_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Peynirler eriyip ekmek çıtır olana kadar 3 dakika bekle.',
            icon: Icons.timer_rounded,
            timerSeconds: 180,
            timerLabel: '3 Dakika Tost Sayacı',
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'Tahta spatula ile tostu tabağa al. Sıcakken afiyetle ye!',
            tip: 'Tost makinesinin metal plakalarına elinle dokunma, çok sıcaktır.',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Dilersen ekmeğin dışına çok az tereyağı sürerek daha çıtır olmasını sağlayabilirsin.',
          'Yanında bir bardak ılık süt veya taze sıkılmış meyve suyu harika gider!',
        ],
      ),

      // 7. TAZE DOMATES ÇORBASI (Lezzet +1 Çorbalar)
      KitchenRecipe(
        id: 'domates_corbasi',
        title: 'Taze Domates Çorbası',
        category: 'Çorbalar',
        subtitle:
            'Olgun domateslerin mis kokusuyla, üzerine rendelenmiş kaşar peyniriyle sunulan iştah açıcı lezzet.',
        portions: '4 Kişilik',
        prepTime: '15 Dakika',
        cookTime: '20 Dakika',
        difficulty: 'Kolay',
        icon: Icons.soup_kitchen_rounded,
        themeColor: const Color(0xFFDC2626), // Domates Kırmızısı
        ingredients: [
          RecipeCheckItem(
            id: 'dom_ing_1',
            name: 'Olgun Domates',
            amount: '4 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_ing_2',
            name: 'Domates Salçası',
            amount: '1 yemek kaşığı',
            icon: Icons.soup_kitchen_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_ing_3',
            name: 'Un',
            amount: '2 yemek kaşığı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_ing_4',
            name: 'Tereyağı veya Sıvı Yağ',
            amount: '2 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_ing_5',
            name: 'Sıcak Su veya Et Suyu',
            amount: '4 su bardağı',
            icon: Icons.water_drop_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_ing_6',
            name: 'Tuz',
            amount: '1 çay kaşığı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_ing_7',
            name: 'Rendelenmiş Kaşar Peyniri',
            amount: '1 küçük kase',
            icon: Icons.scatter_plot_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'dom_tool_1',
            name: 'Çorba Tenceresi',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_tool_2',
            name: 'Rende',
            amount: '1 adet',
            icon: Icons.grid_view_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_tool_3',
            name: 'Çırpıcı / Tahta Kaşık',
            amount: '1 adet',
            icon: Icons.flatware_rounded,
          ),
          RecipeCheckItem(
            id: 'dom_tool_4',
            name: 'Ölçü Bardağı',
            amount: '1 adet',
            icon: Icons.local_drink_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: '4 adet domatesi yıka ve rendenin ince tarafıyla rendele.',
            icon: Icons.grid_view_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Tencereye yağı koy, 2 kaşık unu ekleyip kokusu çıkana kadar 2 dakika kavur.',
            icon: Icons.timer_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dk Un Kavurma',
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: '1 yemek kaşığı salçayı ekle ve 1 dakika karıştır.',
            icon: Icons.timer_rounded,
            timerSeconds: 60,
            timerLabel: '1 Dk Salça Kavurma',
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Rendelenmiş domatesleri tencereye ilave et ve karıştır.',
            icon: Icons.soup_kitchen_rounded,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: '4 su bardağı sıcak suyu azar azar eklerken topaklanmaması için çırpıcıyla karıştır.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Tuzunu ekle, kısık ateşte 15 dakika kaynat.',
            icon: Icons.timer_rounded,
            timerSeconds: 900,
            timerLabel: '15 Dk Kısık Ateşte Kaynatma',
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'Çorbayı kaseye al, üzerine kaşar peyniri serperek sıcak servis et. Afiyet olsun!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Domates çorbasına arzu edersen yarım çay bardağı süt ekleyerek rengini ve lezzetini yumuşatabilirsin.',
        ],
      ),

      // 8. KREMALI BROKOLİ ÇORBASI (Lezzet +1 Çorbalar)
      KitchenRecipe(
        id: 'brokoli_corbasi',
        title: 'Şifalı Brokoli Çorbası',
        category: 'Çorbalar',
        subtitle:
            'Yeşilin en sağlıklı tonu! Bağışıklık sistemini güçlendiren, yumuşak içimli çorba.',
        portions: '4 Kişilik',
        prepTime: '20 Dakika',
        cookTime: '20 Dakika',
        difficulty: 'Kolay',
        icon: Icons.soup_kitchen_rounded,
        themeColor: const Color(0xFF15803D),
        ingredients: [
          RecipeCheckItem(
            id: 'brok_ing_1',
            name: 'Brokoli',
            amount: '500 gram',
            icon: Icons.eco_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_ing_2',
            name: 'Havuç',
            amount: '1 adet',
            icon: Icons.eco_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_ing_3',
            name: 'Patates',
            amount: '1 adet',
            icon: Icons.egg_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_ing_4',
            name: 'Kuru Soğan',
            amount: '1 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_ing_5',
            name: 'Zeytinyağı veya Sıvı Yağ',
            amount: '2 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_ing_6',
            name: 'Sıcak Su',
            amount: '4 su bardağı',
            icon: Icons.water_drop_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_ing_7',
            name: 'Tuz ve Karabiber',
            amount: '1 çay kaşığı',
            icon: Icons.grain_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'brok_tool_1',
            name: 'Tencere',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_tool_2',
            name: 'Bıçak ve Kesme Tahtası',
            amount: '1 set',
            icon: Icons.restaurant_rounded,
          ),
          RecipeCheckItem(
            id: 'brok_tool_3',
            name: 'El Blenderı',
            amount: '1 adet',
            icon: Icons.blender_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Brokoliyi küçük çiçeklerine ayırıp bol suda yıka.',
            icon: Icons.eco_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Patates, havuç ve soğanı soyup küp küp doğra.',
            icon: Icons.dashboard_customize_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Tencereye yağı ve soğanları koyup 2 dakika kavur.',
            icon: Icons.timer_rounded,
            timerSeconds: 120,
            timerLabel: '2 Dk Soğan Kavurma',
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Havuç, patates ve brokolileri ekle, 3 dakika birlikte karıştır.',
            icon: Icons.timer_rounded,
            timerSeconds: 180,
            timerLabel: '3 Dk Sebze Soteleme',
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: '4 su bardağı sıcak suyu ve tuzu ekleyip kapağını kapat.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Sebzeler yumuşayana kadar 15 dakika pişir.',
            icon: Icons.timer_rounded,
            timerSeconds: 900,
            timerLabel: '15 Dk Pişirme Sayacı',
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'El blenderı ile çorbayı pürüzsüz hale getir. Sıcak servis yap!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Brokoli çok zengin C vitamini içerir ve hastalıklara karşı kalkan görevi görür.',
        ],
      ),

      // 9. LEZZET +1 DOMATES SOSLU MAKARNA (Lezzet +1 Makarnalar)
      KitchenRecipe(
        id: 'domatesli_makarna',
        title: 'Lezzet +1 Domates Soslu Makarna',
        category: 'Makarnalar',
        subtitle:
            'Özel bireylerin kendi başlarına kolayca hazırlayabileceği en keyifli ve lezzetli ana yemek.',
        portions: '3 Kişilik',
        prepTime: '10 Dakika',
        cookTime: '12 Dakika',
        difficulty: 'Kolay',
        icon: Icons.dinner_dining_rounded,
        themeColor: const Color(0xFFB91C1C),
        ingredients: [
          RecipeCheckItem(
            id: 'mak_ing_1',
            name: 'Burgu veya Kalem Makarna',
            amount: 'Yarım paket',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_ing_2',
            name: 'Kaynar Su',
            amount: '5 su bardağı',
            icon: Icons.water_drop_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_ing_3',
            name: 'Rendelenmiş Domates',
            amount: '2 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_ing_4',
            name: 'Zeytinyağı',
            amount: '2 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_ing_5',
            name: 'Tuz',
            amount: '1 tatlı kaşığı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_ing_6',
            name: 'Kekik veya Fesleğen',
            amount: '1 tutam',
            icon: Icons.eco_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'mak_tool_1',
            name: 'Geniş Makarna Tenceresi',
            amount: '1 adet',
            icon: Icons.dinner_dining_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_tool_2',
            name: 'Makarna Süzgeci',
            amount: '1 adet',
            icon: Icons.filter_alt_rounded,
          ),
          RecipeCheckItem(
            id: 'mak_tool_3',
            name: 'Tahta Kaşık',
            amount: '1 adet',
            icon: Icons.flatware_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Tencereye 5 bardak suyu koy, 1 tatlı kaşığı tuz ekle ve kaynamaya bırak.',
            icon: Icons.water_drop_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Su kaynayınca yarım paket makarnayı tencereye dök.',
            icon: Icons.grain_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Makarnaların birbirine yapışmaması için tahta kaşıkla bir kez karıştır.',
            icon: Icons.sync_rounded,
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: 'Makarnanın tam kıvamında haşlanması için 10 dakika bekle.',
            icon: Icons.timer_rounded,
            timerSeconds: 600,
            timerLabel: '10 Dk Makarna Haşlama Sayacı',
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Haşlanan makarnayı dikkatlice süzgece dök ve suyunu süz (Gerekirse yetişkinden yardım iste).',
            icon: Icons.filter_alt_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Aynı tencereye yağı ve rendelenmiş domatesi koyup 3 dakika sos yap.',
            icon: Icons.timer_rounded,
            timerSeconds: 180,
            timerLabel: '3 Dk Sos Pişirme',
          ),
          RecipeStepItem(
            stepNumber: 8,
            instruction: 'Süzdüğün makarnayı sosun içine dök, kekik ekleyip karıştır. Tabağa alıp servis et!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Makarnayı süzerken sıcak buhara karşı yüzünü ve ellerini korumayı unutma.',
          'Üzerine biraz beyaz peynir veya kaşar ufalayarak lezzetini ikiye katlayabilirsin.',
        ],
      ),

      // 10. TON BALIKLI & MISIRLI SALATA (Lezzet +1 Salatalar)
      KitchenRecipe(
        id: 'ton_balikli_salata',
        title: 'Pratik Ton Balıklı & Mısırlı Salata',
        category: 'Salatalar',
        subtitle:
            'Ateş ve ocak gerektirmeyen, yüksek proteinli ve çok besleyici harika bir yaz/öğlen salatası.',
        portions: '2 Kişilik',
        prepTime: '10 Dakika',
        cookTime: '0 Dakika',
        difficulty: 'Çok Kolay',
        icon: Icons.eco_rounded,
        themeColor: const Color(0xFF0D9488),
        ingredients: [
          RecipeCheckItem(
            id: 'ton_ing_1',
            name: 'Konserve Ton Balığı',
            amount: '1 küçük kutu (süzülmüş)',
            icon: Icons.set_meal_rounded,
          ),
          RecipeCheckItem(
            id: 'ton_ing_2',
            name: 'Kıvırcık / Marul Yaprakları',
            amount: '5-6 yaprak',
            icon: Icons.eco_rounded,
          ),
          RecipeCheckItem(
            id: 'ton_ing_3',
            name: 'Konserve Mısır',
            amount: '3 yemek kaşığı',
            icon: Icons.grain_rounded,
          ),
          RecipeCheckItem(
            id: 'ton_ing_4',
            name: 'Salatalık',
            amount: '1 adet',
            icon: Icons.circle_rounded,
          ),
          RecipeCheckItem(
            id: 'ton_ing_5',
            name: 'Zeytinyağı ve Limon',
            amount: '2 yemek kaşığı',
            icon: Icons.opacity_rounded,
          ),
        ],
        tools: [
          RecipeCheckItem(
            id: 'ton_tool_1',
            name: 'Salata Kasesi',
            amount: '1 adet',
            icon: Icons.rice_bowl_rounded,
          ),
          RecipeCheckItem(
            id: 'ton_tool_2',
            name: 'Kesme Tahtası & Bıçak',
            amount: '1 set',
            icon: Icons.restaurant_rounded,
          ),
          RecipeCheckItem(
            id: 'ton_tool_3',
            name: 'Çatal',
            amount: '1 adet',
            icon: Icons.flatware_rounded,
          ),
        ],
        steps: const [
          RecipeStepItem(
            stepNumber: 1,
            instruction: 'Ellerini sabunla yıka.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 2,
            instruction: 'Marul yapraklarını soğuk suda tek tek yıkayıp kurula.',
            icon: Icons.wash_rounded,
          ),
          RecipeStepItem(
            stepNumber: 3,
            instruction: 'Marulları elinle küçük parçalara bölerek salata kasesine koy.',
            icon: Icons.eco_rounded,
          ),
          RecipeStepItem(
            stepNumber: 4,
            instruction: 'Salatalığı yıkayıp ince halkalar halinde doğra, kaseye ekle.',
            icon: Icons.dashboard_customize_rounded,
          ),
          RecipeStepItem(
            stepNumber: 5,
            instruction: '3 kaşık tatlı mısırı salatanın üzerine serpiştir.',
            icon: Icons.grain_rounded,
          ),
          RecipeStepItem(
            stepNumber: 6,
            instruction: 'Ton balığının yağını süzüp çatalla hafifçe parçalayarak ekle.',
            icon: Icons.set_meal_rounded,
          ),
          RecipeStepItem(
            stepNumber: 7,
            instruction: 'Zeytinyağı, biraz limon suyu ve az tuz ekleyip karıştır. Afiyet olsun!',
            icon: Icons.emoji_events_rounded,
          ),
        ],
        chefTips: const [
          'Ton balığı omega-3 deposudur, beyin sağlığı ve odaklanma için çok faydalıdır.',
        ],
      ),
    ];
  }
}
