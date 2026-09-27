import 'package:flutter/material.dart';

/// Makaton el hareketi animasyon tipi
enum GestureMotionType {
  toMouth,    // Ağza doğru götürme (Su, Yemek)
  chestTap,   // Göğse dokunma / dairesel ovma (Lütfen, Ben)
  wave,       // El sallama (Merhaba, Güle Güle)
  twoHands,   // İki elin birleşmesi / açılması (Daha, Bitti, Yardım)
  chinTap,    // Çeneye dokunma (Anne, Baba)
  point,      // Gösterme / işaret etme (Bak, Tuvalet)
  bounce,     // Zıplatma / sallama (Oyun)
}

/// 🤲 Makaton El Hareketi ve Kart Öğretim Modeli
class MakatonGesture {
  final String id;
  final String cardId;
  final String word;
  final String emoji;
  final String category;
  final String gestureTitle;
  final List<String> steps;
  final String parentTip;
  final IconData handIcon;
  final GestureMotionType motionType;
  final String speechText;
  final String imageAssetPath;

  const MakatonGesture({
    required this.id,
    required this.cardId,
    required this.word,
    required this.emoji,
    required this.category,
    required this.gestureTitle,
    required this.steps,
    required this.parentTip,
    required this.handIcon,
    required this.motionType,
    required this.speechText,
    required this.imageAssetPath,
  });

  /// Doğrulanmış ve 100% Görsel Rehberli Makaton el hareketleri kütüphanesi
  static List<MakatonGesture> allGestures() {
    return const [
      // ─── 1. TEMEL İHTİYAÇLAR ──────────────────────────────────────────
      MakatonGesture(
        id: 'g_su',
        cardId: 'su',
        word: 'Su',
        emoji: '💧',
        category: 'İhtiyaçlar',
        gestureTitle: 'Bardak Tutup İçme Hareketi',
        steps: [
          'Sağ elini küçük bir bardak tutuyormuş gibi "C" şeklinde bük.',
          'Baş parmağını ve parmaklarını dudaklarına doğru hafifçe yaklaştır.',
          'Başını hafifçe geriye atarak su içme taklidi yap.',
        ],
        parentTip: 'İlk alıştırmada çocuğun eline gerçek bir renkli plastik bardak vererek hareketi taklit ettirebilirsiniz.',
        handIcon: Icons.local_drink_rounded,
        motionType: GestureMotionType.toMouth,
        speechText: 'Su içmek istiyorum.',
        imageAssetPath: 'assets/images/makaton_water_sign.jpg',
      ),
      MakatonGesture(
        id: 'g_yemek',
        cardId: 'yemek',
        word: 'Yemek',
        emoji: '🍲',
        category: 'İhtiyaçlar',
        gestureTitle: 'Parmak Uçlarını Ağza Götürme',
        steps: [
          'Sağ elinin tüm parmak uçlarını birleştirerek minik bir lokma tutar gibi yap.',
          'Elinin ucunu iki defa ağzına doğru hafifçe dokundur.',
          'Ağzını hafifçe çiğner gibi oynatarak destekle.',
        ],
        parentTip: 'Yemek saati öncesinde bu işareti yapıp ardından tabaktan bir lokma vererek pekiştirin.',
        handIcon: Icons.restaurant_rounded,
        motionType: GestureMotionType.toMouth,
        speechText: 'Acıktım, yemek istiyorum.',
        imageAssetPath: 'assets/images/makaton_food_sign.jpg',
      ),
      MakatonGesture(
        id: 'g_tuvalet',
        cardId: 'tuvalet',
        word: 'Tuvalet',
        emoji: '🚽',
        category: 'İhtiyaçlar',
        gestureTitle: 'Omuza Dokunma / T İşareti',
        steps: [
          'Sağ elinin işaret veya baş parmağını kaldır.',
          'Sağ omzuna veya göğsünün üst kısmına iki defa hafifçe dokun.',
          'İleri seviye için: Sol el açıkken, sağ elin işaret parmağıyla üzerine "T" harfi yap.',
        ],
        parentTip: 'Tuvalete her gidişinizde kapının önünde bu işareti birlikte tekrarlayın.',
        handIcon: Icons.wc_rounded,
        motionType: GestureMotionType.point,
        speechText: 'Tuvaletim geldi, tuvalete gitmek istiyorum.',
        imageAssetPath: 'assets/images/makaton_toilet_sign.jpg',
      ),
      MakatonGesture(
        id: 'g_uyku',
        cardId: 'uyku',
        word: 'Uyu',
        emoji: '😴',
        category: 'İhtiyaçlar',
        gestureTitle: 'Başını Yastığa Yaslama',
        steps: [
          'İki avuç içini birbirine yapıştır (dua eder gibi).',
          'Ellerini yanağının altına koy ve başını hafifçe yana eğ.',
          'Gözlerini bir saniyeliğine kapatıp dinlenme hissi ver.',
        ],
        parentTip: 'Yatak odasına geçerken ışıkları kısıp bu hareketi yapmanız sakinleşmesini kolaylaştırır.',
        handIcon: Icons.bedtime_rounded,
        motionType: GestureMotionType.chinTap,
        speechText: 'Uykum geldi, uyumak istiyorum.',
        imageAssetPath: 'assets/images/makaton_sleep_sign.jpg',
      ),

      // ─── 2. SOSYAL & NEZAKET ──────────────────────────────────────────
      MakatonGesture(
        id: 'g_lutfen',
        cardId: 'lutfen',
        word: 'Lütfen',
        emoji: '🙏',
        category: 'Sosyal',
        gestureTitle: 'Göğse Dairesel Sevgi Hareketi',
        steps: [
          'Sağ elini avuç için açık şekilde düz tut.',
          'Elini göğsünün üzerine koy.',
          'Saat yönünde iki defa dairesel şekilde göğsünü hafifçe ov.',
        ],
        parentTip: 'Çocuk bir nesne istediğinde elini göğsüne koymasını destekleyip hemen ardından nesneyi verin.',
        handIcon: Icons.volunteer_activism_rounded,
        motionType: GestureMotionType.chestTap,
        speechText: 'Lütfen bana ver.',
        imageAssetPath: 'assets/images/makaton_please_sign.jpg',
      ),
      MakatonGesture(
        id: 'g_merhaba',
        cardId: 'merhaba',
        word: 'Merhaba',
        emoji: '👋',
        category: 'Sosyal',
        gestureTitle: 'Açık El Sallama',
        steps: [
          'Sağ elini baş hizana kaldır, avuç için karşıya baksın.',
          'Elini sağa ve sola iki defa neşeyle salla.',
          'Göz teması kurarak gülümse.',
        ],
        parentTip: 'Odaya biri girdiğinde veya okul servisine bindiğinde ilk yapılacak en neşeli işarettir.',
        handIcon: Icons.waving_hand_rounded,
        motionType: GestureMotionType.wave,
        speechText: 'Merhaba, nasılsın?',
        imageAssetPath: 'assets/images/makaton_hello_sign.jpg',
      ),
      MakatonGesture(
        id: 'g_yardim',
        cardId: 'yardim',
        word: 'Yardım',
        emoji: '🤝',
        category: 'Sosyal',
        gestureTitle: 'Avuç Üzerine Yumruk Koyma',
        steps: [
          'Sol elini avuç için yukarı bakacak şekilde düz aç.',
          'Sağ elini baş parmağı yukarı bakan bir yumruk yap.',
          'Sağ elini sol avucunun üzerine koyup her iki eli birlikte hafifçe yukarı kaldır.',
        ],
        parentTip: 'Açamadığı bir kavanoz veya yapamadığı bir yapboz parçasında bu işareti yapmasını isteyin.',
        handIcon: Icons.handshake_rounded,
        motionType: GestureMotionType.twoHands,
        speechText: 'Lütfen bana yardım eder misin?',
        imageAssetPath: 'assets/images/makaton_help_sign.jpg',
      ),

      // ─── 3. EYLEMLER & TAMAMLAMA ───────────────────────────────────────
      MakatonGesture(
        id: 'g_bitti',
        cardId: 'bitti',
        word: 'Bitti',
        emoji: '✨',
        category: 'Eylemler',
        gestureTitle: 'Elleri İki Yana Açma',
        steps: [
          'İki elini göğüs hizasında, avuç içleri sana bakacak şekilde tut.',
          'Bileklerini çevirerek avuç içlerini karşıya ve iki yana doğru hızla aç.',
          '"İşte bitti!" der gibi elleri yana savur.',
        ],
        parentTip: 'Yemek bittiğinde veya oyuncakları kutuya topladıktan sonra net bir kapanış sinyali verir.',
        handIcon: Icons.check_circle_rounded,
        motionType: GestureMotionType.twoHands,
        speechText: 'Etkinlik bitti, tamamlandı.',
        imageAssetPath: 'assets/images/makaton_finished_sign.jpg',
      ),
    ];
  }
}
