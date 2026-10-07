class FreeTimeActivityInfo {
  final String title;
  final String emoji;
  final List<String> places;
  final List<String> highlights; // Örn vizyondaki filmler veya sergiler
  final List<String> tips; // İpuçları ve sesli rehberlik

  const FreeTimeActivityInfo({
    required this.title,
    required this.emoji,
    required this.places,
    required this.highlights,
    required this.tips,
  });
}

class FreeTimeActivityInfoService {
  static FreeTimeActivityInfo getInfoFor(String activityTitle) {
    final lower = activityTitle.toLowerCase();

    if (lower.contains('sinema')) {
      return const FreeTimeActivityInfo(
        title: 'Sinema Etkinliği Rehberi',
        emoji: '🎬',
        places: [
          'Kadıköy Sineması (Tarihi Salon)',
          'Paribu Cineverse (AVM Sineması)',
          'Cinetech Sinema Salonları',
          'En Yakın Şehir Sineması',
        ],
        highlights: [
          '🍿 Vizyondaki Popüler Animasyon & Aile Filmleri',
          '🦸 Macera ve Süper Kahraman Filmleri',
          '🌱 Doğa & Hayvanlar Belgeseli',
          '🎭 Sevilen Türk Komedi Filmleri',
        ],
        tips: [
          'Biletini seanstan önce gişeden veya internetten ayırt.',
          'Salona girmeden önce telefonunu sessize al 🔕.',
          'Kendi koltuk numaranı bilet üzerinden kontrol et.',
          'Film başladıktan sonra sessizce izle ve keyif al.',
        ],
      );
    } else if (lower.contains('müze')) {
      return const FreeTimeActivityInfo(
        title: 'Müze & Sergi Rehberi',
        emoji: '🏛️',
        places: [
          'İstanbul Arkeoloji Müzeleri',
          'Rahmi M. Koç Sanayi Müzesi',
          'Pera Müzesi / Resim Sergisi',
          'Panorama Tarih Müzesi',
        ],
        highlights: [
          '🎧 Sesli Rehber (Audio Guide) Kulaklık Desteği',
          '🎫 Öğrenci / Özel Gereksinimli Ücretsiz Giriş & Müzekart',
          '🦕 Tarihi Eserler ve Eski Araçlar Koleksiyonu',
          '🎨 Modern Sanat ve Heykel Galerileri',
        ],
        tips: [
          'Girişte danışmadan sesli rehber kulaklığı isteyebilirsin 🎧.',
          'Tarihi eserlere dokunulmaz, sadece gözle incelenir.',
          'Müze içinde sakin ve alçak sesle konuş.',
          'Yorulursan müze bahçesinde mola verebilirsin.',
        ],
      );
    } else if (lower.contains('kafe')) {
      return const FreeTimeActivityInfo(
        title: 'Kafe & Sohbet Rehberi',
        emoji: '☕',
        places: [
          'Kahve Dünyası',
          'Espressolab / Şehir Kafesi',
          'Belediye Sosyal Tesisleri Kafesi',
          'Park İçi Çay Bahçesi',
        ],
        highlights: [
          '☕ Sıcak Çikolata, Salep veya Bitki Çayı',
          '🥪 Tost, Sandviç veya Poğaça Çeşitleri',
          '🍰 Dilim Kek veya Kurabiye',
          '💧 Soğuk Su ve Limonata',
        ],
        tips: [
          'Kasaya veya garsona güler yüzle "Merhaba" de.',
          'Menüyü inceleyip bütçene uygun bir içecek seç.',
          'Siparişini verdikten sonra "Teşekkür ederim" demeyi unutma.',
        ],
      );
    } else if (lower.contains('bowling')) {
      return const FreeTimeActivityInfo(
        title: 'Bowling Eğlencesi Rehberi',
        emoji: '🎳',
        places: [
          'AVM Bowling Salonu',
          'Gençlik Merkezi Eğlence Alanı',
          'Spor & Bowling Kompleksi',
        ],
        highlights: [
          '👟 Numarana Uygun Özel Bowling Ayakkabısı',
          '⚪ Kolay Kaldırabileceğin Hafif Top (6-8 Numara)',
          '🏆 Otomatik Skor Ekranı ve Eğlenceli Müzik',
        ],
        tips: [
          'Kendi ayakkabını gişeye verip bowling ayakkabısı al.',
          'Topu fırlatırken siyah çizgiyi geçmemeye dikkat et.',
          'Sıran geldiğinde tek bir top at ve sonucunu izle.',
          'Arkadaşın atış yaparken onu alkışla ve destekle 👏.',
        ],
      );
    } else if (lower.contains('park') || lower.contains('piknik')) {
      return const FreeTimeActivityInfo(
        title: 'Park & Doğa Yürüyüşü Rehberi',
        emoji: '🌳',
        places: [
          'Şehir Millet Bahçesi',
          'Gülhane Parkı / Şehir Parkı',
          'Sahil Yürüyüş Parkuru',
          'Ağaçlıklı Dinlenme Alanları',
        ],
        highlights: [
          '🚶 Yürüyüş ve Koşu Parkuru',
          '🪑 Banklar ve Gölgelik Dinlenme Masaları',
          '🐦 Kuşları ve Doğıyı İzleme Noktaları',
          '🚰 Temiz İçme Suyu Çeşmeleri',
        ],
        tips: [
          'Çıkmadan önce hava durumunu kontrol et ☀️.',
          'Yanına su şişesi ve gerekirse şapka al.',
          'Çöplerini mutlaka çöp kutusuna at 🗑️.',
        ],
      );
    } else {
      return const FreeTimeActivityInfo(
        title: 'Serbest Zaman Etkinliği Rehberi',
        emoji: '🎉',
        places: [
          'Yakındaki Kültür ve Yaşam Merkezleri',
          'Şehir Meydanı ve Parklar',
          'Sosyal Alanlar ve AVM',
        ],
        highlights: [
          '🌟 Yeni Deneyimler ve Sosyalleşme',
          '🗣️ Arkadaşlarla ve Aileyle Keyifli Zaman',
          '🧭 Kendi Başına Başarma Özgüveni',
        ],
        tips: [
          'Etkinlik saatinden önce hazırlıklarını tamamla.',
          'Çantana cüzdan, telefon ve anahtarını koymayı unutma.',
          'Herhangi bir sorunda destek kişini aramaktan çekinme 📞.',
        ],
      );
    }
  }
}
