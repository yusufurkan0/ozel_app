import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FreeTimePlan {
  final String id;
  final String activityTitle;
  final String activityEmoji;
  final String dayTitle;
  final Map<int, String> answers; // 1..13 soru yanıtları
  final DateTime createdAt;
  bool isCompleted;

  FreeTimePlan({
    required this.id,
    required this.activityTitle,
    required this.activityEmoji,
    required this.dayTitle,
    required this.answers,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'activityTitle': activityTitle,
        'activityEmoji': activityEmoji,
        'dayTitle': dayTitle,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
        'createdAt': createdAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory FreeTimePlan.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = rawAnswers.map((k, v) => MapEntry(int.tryParse(k) ?? 1, v.toString()));

    return FreeTimePlan(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      activityTitle: json['activityTitle'] ?? 'Serbest Zaman Etkinliği',
      activityEmoji: json['activityEmoji'] ?? '🎉',
      dayTitle: json['dayTitle'] ?? '',
      answers: parsedAnswers,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isCompleted: json['isCompleted'] == true,
    );
  }

  static const List<Map<String, dynamic>> questions = [
    {
      'step': 1,
      'question': '1. Hangi serbest zaman etkinliğini yapacaksın?',
      'icon': '🎯',
      'hint': 'Örn: Sinemaya gideceğim, Maça gideceğim...',
      'options': ['Sinemaya gideceğim 🎬', 'Kafeye gideceğim ☕', 'Müzeye gideceğim 🏛️', 'Alışverişe gideceğim 🛍️', 'Pikniğe gideceğim 🧺', 'Bowling oynayacağım 🎳'],
    },
    {
      'step': 2,
      'question': '2. Bu etkinliği tam olarak nerede yapacaksın?',
      'icon': '📍',
      'hint': 'Mekanın adı veya semti (Örn: Kadıköy Sineması, Şehir Parkı)',
      'options': ['Yakındaki AVM / Sinema Salonu', 'Şehir Parkı / Bahçe', 'Merkezdeki Kafe', 'Kültür Merkezi / Müze', 'Bowling Salonu'],
    },
    {
      'step': 3,
      'question': '3. Bu etkinliği kiminle birlikte yapacaksın?',
      'icon': '👥',
      'hint': 'Yanında kim olacak?',
      'options': ['Kendi başıma 🚶', 'Ailemle birlikte 👨‍👩‍👧', 'Arkadaşımla 🧑‍🤝‍🧑', 'İş Koçumla 💼'],
    },
    {
      'step': 4,
      'question': '4. Hangi gün ve saat kaçta gideceksin?',
      'icon': '⏰',
      'hint': 'Gidiş saati ve buluşma zamanı',
      'options': ['Sabah saat 10:00', 'Öğleden sonra 14:00', 'İkindi saat 16:30', 'Akşam saat 19:00'],
    },
    {
      'step': 5,
      'question': '5. Oraya hangi ulaşım aracıyla gideceksin?',
      'icon': '🚌',
      'hint': 'Nasıl gideceksin?',
      'options': ['Yürüyerek gideceğim 🚶', 'Otobüs / Dolmuşla 🚌', 'Metro / Marmaray ile 🚇', 'Ailemin arabasıyla 🚗', 'Taksi ile 🚕'],
    },
    {
      'step': 6,
      'question': '6. Yanına hangi eşyaları alman gerekiyor?',
      'icon': '🎒',
      'hint': 'Çantana koyacakların',
      'options': ['Cüzdan / Para / Kart 💳', 'Akıllı Telefon 📱', 'Ev Anahtarı 🔑', 'Kimlik Kartım 🪪', 'Su Şişesi 💧', 'Bilet / Rezervasyon 🎟️'],
    },
    {
      'step': 7,
      'question': '7. Ne kadar para harcamayı planlıyorsun?',
      'icon': '💵',
      'hint': 'Tahmini bütçen',
      'options': ['Hiç para harcamayacağım (0 TL)', '50 - 100 TL arası', '100 - 250 TL arası', '250 - 500 TL arası'],
    },
    {
      'step': 8,
      'question': '8. Ne giyeceksin? Kıyafetin nasıl olacak?',
      'icon': '👕',
      'hint': 'Hava durumuna ve mekana uygun kıyafet',
      'options': ['Rahat spor kıyafetler ve spor ayakkabı 👟', 'Hava serinse mont / hırka 🧥', 'Güneşliyse şapka ve tişört 🧢', 'Şık ve temiz günlük kıyafet 👔'],
    },
    {
      'step': 9,
      'question': '9. Oraya vardığında sırasıyla ne yapacaksın?',
      'icon': '📝',
      'hint': 'Mekandaki ilk adımların',
      'options': ['Gişeden bilet alıp sıraya gireceğim 🎟️', 'Arkadaşımla buluşup masaya oturacağım ☕', 'Sergiyi / filmi sakince gezeceğim 🖼️', 'Oyun ayakkabılarımı giyip başlayacağım 🎳'],
    },
    {
      'step': 10,
      'question': '10. Acıkırsan veya susarsan ne yapacaksın?',
      'icon': '🥪',
      'hint': 'Yemek ve içecek ihtiyacı',
      'options': ['Yanımdaki suyu içeceğim 💧', 'Kafeteryadan sandviç / su alacağım 🥪', 'Etkinlik bitene kadar bekleyeceğim ⏳', 'Yanımdaki atıştırmalığı yiyeceğim 🍎'],
    },
    {
      'step': 11,
      'question': '11. Bir sorun çıkarsa veya kaybolursan kime haber vereceksin?',
      'icon': '🚨',
      'hint': 'Destek ve acil durum planın',
      'options': ['Destek Kişimi (Ailemi) hemen arayacağım 📞', 'İş Koçuma WhatsApp mesajı atacağım 💬', 'En yakın görevli / polisten yardım isteyeceğim 👮', 'Uygulamadaki "Kayboldum!" butonuna basacağım 🆘'],
    },
    {
      'step': 12,
      'question': '12. Eve ne zaman ve nasıl döneceksin?',
      'icon': '🏠',
      'hint': 'Dönüş saatin ve planın',
      'options': ['Etkinlik biter bitmez aynı yolla döneceğim 🚌', 'Ailem gelip beni alacak 🚗', 'En geç saat 18:00\'de evde olacağım 🕕', 'Arkadaşımla birlikte döneceğim 🚶'],
    },
    {
      'step': 13,
      'question': '13. Etkinlikten sonra gününü nasıl değerlendireceksin?',
      'icon': '⭐',
      'hint': 'Günün sonu ve dinlenme',
      'options': ['Evde aileme neler yaptığımı anlatacağım 🗣️', 'Uygulamada "Kendimi Değerlendirme" formunu dolduracağım 📋', 'Dinlenip müzik dinleyeceğim 🎧', 'Erken yatıp güzelce dinleneceğim 🛌'],
    },
  ];

  static Future<List<FreeTimePlan>> loadSavedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('user_free_time_plans');
    if (savedJson == null || savedJson.isEmpty) return [];
    try {
      final list = jsonDecode(savedJson) as List;
      return list.map((item) => FreeTimePlan.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlans(List<FreeTimePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(plans.map((p) => p.toJson()).toList());
    await prefs.setString('user_free_time_plans', jsonStr);
  }
}
