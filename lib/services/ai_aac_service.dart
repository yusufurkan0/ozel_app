import 'package:flutter/material.dart';
import '../models/makaton_item.dart';

/// Yapay Zeka Destekli Sosyal Hikaye Modeli.
class AiSocialStory {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final List<AiSocialStoryStep> steps;

  const AiSocialStory({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'colorValue': color.toARGB32(),
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory AiSocialStory.fromJson(Map<String, dynamic> json) => AiSocialStory(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        emoji: json['emoji'] as String,
        color: Color(json['colorValue'] as int? ?? 0xFF7EB8E0),
        steps: (json['steps'] as List)
            .map((s) => AiSocialStoryStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class AiSocialStoryStep {
  final String title;
  final String text;
  final IconData icon;
  final String emoji;

  const AiSocialStoryStep({
    required this.title,
    required this.text,
    required this.icon,
    required this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'text': text,
        'iconCode': icon.codePoint,
        'emoji': emoji,
      };

  factory AiSocialStoryStep.fromJson(Map<String, dynamic> json) =>
      AiSocialStoryStep(
        title: json['title'] as String,
        text: json['text'] as String,
        icon: IconData(json['iconCode'] as int? ?? Icons.star.codePoint,
            fontFamily: 'MaterialIcons'),
        emoji: json['emoji'] as String,
      );
}

/// Özel Eğitim ve Alternatif İletişim (AAC) için Akıllı AI Motoru.
///
/// %100 çevrimdışı çalışabilen semantik kural ve tahminleme mimarisine sahiptir.
class AiAacService {
  static final AiAacService _instance = AiAacService._internal();
  factory AiAacService() => _instance;
  AiAacService._internal();

  // ─── 1. AI Sıradaki Kelime / Sembol Tahminleyicisi ───────────────────────
  List<MakatonItem> predictNextItems(
    List<MakatonItem> currentSentence,
    List<MakatonItem> allItems,
  ) {
    if (allItems.isEmpty) return [];

    final itemMap = {for (final item in allItems) item.id: item};
    final labelMap = {for (final item in allItems) item.label.toLowerCase(): item};

    MakatonItem? findItem(String key) => itemMap[key] ?? labelMap[key.toLowerCase()];

    // Cümle boşsa: Başlangıç çekirdek kelimeleri öner (Özne & Temel İhtiyaçlar)
    if (currentSentence.isEmpty) {
      final starterIds = ['ben', 'istiyorum', 'su', 'yemek', 'anne', 'oyun'];
      final list = <MakatonItem>[];
      for (final id in starterIds) {
        final item = findItem(id);
        if (item != null) list.add(item);
      }
      return list;
    }

    final last = currentSentence.last;
    final recommendedIds = <String>[];

    // Son kelime Yiyecek / İçecek ise:
    if (last.category == MakatonCategory.food) {
      recommendedIds.addAll(['istiyorum', 'ver', 'lutfen', 'daha_fazla', 'bitti', 'tesekkurler']);
    }
    // Son kelime Kişi / Özne ise:
    else if (last.category == MakatonCategory.people || last.category == MakatonCategory.social) {
      if (last.id == 'ben' || last.id == 'sen') {
        recommendedIds.addAll(['istiyorum', 'seviyorum', 'gidelim', 'mutlu', 'yemek', 'oyun']);
      } else {
        recommendedIds.addAll(['gel', 'ver', 'saril', 'bak', 'yardim_et', 'seviyorum']);
      }
    }
    // Son kelime Eylem / Fiil ise:
    else if (last.category == MakatonCategory.actions) {
      if (last.id == 'istiyorum' || last.id == 'ver' || last.id == 'al') {
        recommendedIds.addAll(['lutfen', 'su', 'yemek', 'oyun', 'park', 'tesekkurler']);
      } else if (last.id == 'gidelim') {
        recommendedIds.addAll(['park', 'okul', 'ev', 'lutfen', 'anne']);
      } else {
        recommendedIds.addAll(['lutfen', 'bitti', 'daha_fazla', 'tesekkurler']);
      }
    }
    // Son kelime Duygu ise:
    else if (last.category == MakatonCategory.emotions) {
      recommendedIds.addAll(['cunku', 'anne', 'yardim_et', 'saril', 'dinlen']);
    }
    // Son kelime Yer / Mekan ise:
    else if (last.category == MakatonCategory.places) {
      recommendedIds.addAll(['gidelim', 'istiyorum', 'cok_guzel', 'bitti']);
    }
    // Varsayılan tamamlama öbekleri
    else {
      recommendedIds.addAll(['istiyorum', 'lutfen', 'tesekkurler', 'bitti']);
    }

    final results = <MakatonItem>[];
    for (final id in recommendedIds) {
      final item = findItem(id);
      if (item != null && !currentSentence.contains(item)) {
        results.add(item);
      }
    }

    // Yeterli öneri çıkmazsa genel eylem ve nezaket ekle
    if (results.length < 3) {
      for (final fallbackId in ['istiyorum', 'lutfen', 'tesekkurler', 'ver']) {
        final item = findItem(fallbackId);
        if (item != null && !results.contains(item) && !currentSentence.contains(item)) {
          results.add(item);
        }
      }
    }

    return results.take(5).toList();
  }

  // ─── 2. Kişiselleştirilmiş AI Sosyal Hikaye Üreticisi ─────────────────────
  AiSocialStory generateSocialStory({
    required String topic,
    required String childName,
  }) {
    final lower = topic.toLowerCase();
    final name = childName.isEmpty ? 'Canım' : childName;
    final storyId = 'ai_story_${DateTime.now().millisecondsSinceEpoch}';

    // Aşı / Doktor / Hastane
    if (lower.contains('aşı') || lower.contains('iğne') || lower.contains('kan') || lower.contains('hastane')) {
      return AiSocialStory(
        id: storyId,
        title: '$name Aşı Oluyor',
        description: 'Aşılar bizi mikroplardan korur ve güçlü yapar.',
        emoji: '💉',
        color: const Color(0xFF5C6BC0),
        steps: [
          AiSocialStoryStep(
            title: 'Hastaneye Gidiyoruz',
            text: '$name ailesiyle birlikte sağlık ocağına gidiyor. Orada doktorlar var.',
            icon: Icons.local_hospital_rounded,
            emoji: '🏥',
          ),
          AiSocialStoryStep(
            title: 'Sakin ve Rahat Bekliyoruz',
            text: 'Sandalyede oturuyoruz. Derin bir nefes alıp sevdiğimiz bir şeyi düşünüyoruz.',
            icon: Icons.chair_rounded,
            emoji: '🪑',
          ),
          AiSocialStoryStep(
            title: 'Küçük Bir Dokunuş',
            text: 'Hemşire kolumuzu siliyor. Sivrisinek ısırığı gibi çok kısa bir an sürecek.',
            icon: Icons.healing_rounded,
            emoji: '🩹',
          ),
          AiSocialStoryStep(
            title: 'Harika Başardın!',
            text: 'İşte bitti bile! Üzerine güzel bir yara bandı yapıştırdık. Çok cesursun $name!',
            icon: Icons.star_rounded,
            emoji: '🌟',
          ),
        ],
      );
    }

    // Uçak / Yolculuk
    if (lower.contains('uçak') || lower.contains('yolculuk') || lower.contains('tatil') || lower.contains('bavul')) {
      return AiSocialStory(
        id: storyId,
        title: '$name Uçağa Biniyor',
        description: 'Gökyüzünde güvenli ve eğlenceli bir yolculuk rehberi.',
        emoji: '✈️',
        color: const Color(0xFF26A69A),
        steps: [
          AiSocialStoryStep(
            title: 'Havalimanına Gidiyoruz',
            text: 'Büyük bavullarımızı teslim ediyoruz ve güvenli kapıdan geçiyoruz.',
            icon: Icons.luggage_rounded,
            emoji: '🧳',
          ),
          AiSocialStoryStep(
            title: 'Uçağa Binip Kemerimizi Bağlıyoruz',
            text: 'Koltuk numaramızı buluyoruz. Kemerimizi "tık" diye bağlıyoruz. Çok güvendeyiz.',
            icon: Icons.airline_seat_recline_extra_rounded,
            emoji: '💺',
          ),
          AiSocialStoryStep(
            title: 'Motor Sesi ve Kalkış',
            text: 'Uçak hızlanırken ses çıkarabilir. Kulaklığımızı takabilir veya oyun oynayabiliriz.',
            icon: Icons.headset_rounded,
            emoji: '🎧',
          ),
          AiSocialStoryStep(
            title: 'Bulutların Üzerindeyiz!',
            text: 'Pencereden dışarı bakıyoruz, her şey çok küçük görünüyor. Harika bir yolcusun $name!',
            icon: Icons.cloud_rounded,
            emoji: '☁️',
          ),
        ],
      );
    }

    // Yüzme / Deniz / Havuz
    if (lower.contains('yüzme') || lower.contains('havuz') || lower.contains('deniz') || lower.contains('su')) {
      return AiSocialStory(
        id: storyId,
        title: '$name Yüzmeye Gidiyor',
        description: 'Havuzda ve denizde güvenli, eğlenceli kurallar.',
        emoji: '🏊‍♂️',
        color: const Color(0xFF29B6F6),
        steps: [
          AiSocialStoryStep(
            title: 'Mayomuzu ve Kolluklarımızı Giyiyoruz',
            text: 'Suya girmeden önce kolluklarımızı takıyoruz. Kolluklar bizi suyun üstünde tutar.',
            icon: Icons.check_circle_rounded,
            emoji: '🦺',
          ),
          AiSocialStoryStep(
            title: 'Yavaşça Suya Adım Atıyoruz',
            text: 'Merdivenlerden yavaşça iniyoruz. Suyun serinliği çok güzel.',
            icon: Icons.waves_rounded,
            emoji: '🌊',
          ),
          AiSocialStoryStep(
            title: 'Birlikte Ayaklarımızı Çırpıyoruz',
            text: 'Suyun içinde ayaklarımızı çırpıp baloncuklar yapıyoruz. Çok eğlenceli!',
            icon: Icons.pool_rounded,
            emoji: '💦',
          ),
          AiSocialStoryStep(
            title: 'Havlumuza Sarınıyoruz',
            text: 'Sudan çıkınca yumuşacık havlumuzla kurulanıyoruz. Aferin $name!',
            icon: Icons.wb_sunny_rounded,
            emoji: '☀️',
          ),
        ],
      );
    }

    // Genel / Özel Konu İçin Akıllı Adaptasyon
    return AiSocialStory(
      id: storyId,
      title: '$name ve $topic',
      description: '$topic durumuna adım adım sakin hazırlık rehberi.',
      emoji: '🎈',
      color: const Color(0xFFAB47BC),
      steps: [
        AiSocialStoryStep(
          title: 'Hazırlık Yapıyoruz',
          text: '$name bugün $topic deneyimini yaşayacak. Önceden bilmek bizi rahatlatır.',
          icon: Icons.info_outline_rounded,
          emoji: '📋',
        ),
        AiSocialStoryStep(
          title: 'Kuralları Hatırlıyoruz',
          text: 'Sakin kalıyoruz, ailemizin elini tutuyoruz ve çevremizi inceliyoruz.',
          icon: Icons.favorite_rounded,
          emoji: '🤝',
        ),
        AiSocialStoryStep(
          title: 'Adım Adım İlerliyoruz',
          text: 'Her şey sırayla gerçekleşiyor. Zorlanırsak derin nefes alıyoruz.',
          icon: Icons.self_improvement_rounded,
          emoji: '🧘‍♂️',
        ),
        AiSocialStoryStep(
          title: 'Tebrikler, Başardın!',
          text: 'Yeni bir deneyimi daha başarıyla tamamladın $name! Seninle gurur duyuyoruz.',
          icon: Icons.emoji_events_rounded,
          emoji: '🏆',
        ),
      ],
    );
  }

  // ─── 3. Terapist & Aile İçin AI Klinik İçgörü Analizi ─────────────────────
  String generateClinicalInsights({
    required String childName,
    required int totalPresses,
    required int streak,
    required List<MapEntry<String, int>> topSymbols,
    required String todayEmotion,
    required double routineRate,
  }) {
    final name = childName.isEmpty ? 'Çocuk' : childName;
    final topList = topSymbols.map((e) => '"${e.key}" (${e.value}x)').join(', ');

    return '''
📋 AI KLİNİK AAC & DAVRANIŞSAL DEĞERLENDİRME
--------------------------------------------------
Öğrenci / Birey: $name
Analiz Tarihi: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}

1. İLETİŞİM GELİŞİMİ VE İFADE GÜCÜ:
• $name bu dönemde toplam $totalPresses kez sembol kartlarını kullanarak aktif alternatif iletişim (AAC) kurmuştur.
• En sık tercih edilen ifade öbekleri: ${topList.isNotEmpty ? topList : "Temel ihtiyaç ve selamlama kartları"}.
• Değerlendirme: Çocuk temel ihtiyaçlarını fiziksel zorlama veya hırçınlık yerine görsel sembollerle ifade etme alışkanlığı kazanmaktadır.

2. GÜNLÜK RUTİN VE UYUM İSTİKRARI:
• Aktif gün serisi $streak gündür kesintisiz devam etmektedir.
• Günlük yaşam rutinlerini tamamlama başarısı %${(routineRate * 100).toInt()} seviyesindedir.
• Değerlendirme: Rutin takvimindeki görsel pekiştireçler bağımsız yaşam becerilerini güçlendirmektedir.

3. DUYGU DURUMU & PEDAGOJİK TAVSİYELER:
• En son bildirilen duygu durumu: ${todayEmotion.isNotEmpty ? todayEmotion : "Dengeli ve sakin"}.
• Terapist Tavsiyesi: 
  a) Çocuğun en sık kullandığı kelimelerle 2'li kombinasyonlar (örn: "Su + İstiyorum") kurması teşvik edilmelidir.
  b) İletişim panosundaki başarıları pozitif sosyal pekiştireçlerle (övgü, sarılma) desteklenmelidir.
''';
  }
}
