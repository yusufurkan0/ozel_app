# 🌟 Özel Yaşam Rehberi (ozel_app)

> **Down sendromlu ve özel gereksinimli bireyler için geliştirilmiş; günlük rutinleri, zaman yönetimini, finansal okuryazarlığı, acil durum güvenliğini ve Makaton destekli alternatif iletişimi kolaylaştıran modern mobil uygulama.**

---

## 📱 Proje Hakkında

**Özel Yaşam Rehberi**, özel eğitim alan bireylerin günlük yaşamlarını bağımsız ve güvenli bir şekilde sürdürebilmelerini desteklemek amacıyla hazırlanmıştır. Uygulama, bilişsel yükü en aza indiren yüksek kontrastlı blok renk tasarımı, görsel semboller, Türkçe ses sentezi (TTS), haptik titreşim geri bildirimleri ve özelleştirilebilir modüllerle donatılmıştır.

---

## 🚀 Öne Çıkan Modüller ve Özellikler

### 1. 📅 Takvim & Günlük Plan (52 Hafta)
- Yılın 52 haftası boyunca ileri/geri gezinebilme.
- 3 temel renk kategorisi ile görsel zaman blokları:
  - 🔴 **Kırmızı:** İş, okul ve kurs zamanı
  - 🔵 **Mavi:** Evdeki dinlenme zamanı
  - 🟢 **Yeşil:** Serbest eğlence ve hobi zamanı
- Sabah, Öğlen ve Akşam olmak üzere 3 zaman dilimi.
- Kullanıcıya özel dinamik not ekleme ve düzenleme.

### 2. ⏱️ Arka Planda Çalışan Titreşimli ve Sesli Kronometre
- Kadran üzerinden görsel ilerleme ve dijital geri sayım.
- **Arka Plan Kalıcılığı:** Uygulamadan çıkılsa veya başka modüle geçilse dahi gerçek zamanlı sayaç saymaya devam eder.
- **Titreşim ve Alarm:** Süre bittiğinde aralıksız haptik titreşim (`HapticFeedback`) ve yüksek sesli dijital buzzer alarmı (`alarm_buzzer.wav`) çalar.
- Ana ekrandan ve zamanlayıcı ekranından tek tuşla alarm durdurma desteği.

### 3. 💵 Gerçek Türk Lirası ile Nakit Para Defteri
- Orijinal yüksek çözünürlüklü Türk Lirası görselleri:
  - 🪙 **1 TL Madeni Para**
  - 💶 **5 TL, 10 TL, 20 TL, 50 TL, 100 TL ve 200 TL Banknotlar**
- Dokunarak tam ekran yakınlaştırma (Zoom) ve parayı detaylı inceleme modu.
- Adet artırıp azaltarak toplam nakit tutarını otomatik hesaplama ve bütçe yönetimi.

### 4. 💳 Kredi Kartı Defteri & Bütçe Yönetimi
- Dijital harcama ve kart limit takibi.

### 5. 🆘 Kaybolma & Acil Durum Rehberi
- Kullanıcıya ait ad, acil durum telefon numarası ve özel notlar.
- Tek dokunuşla sesli yardım çağrısı yapabilme.
- Kesinlikle sahte veri içermez; tüm bilgiler kullanıcı tarafından girilir ve güvenle yerel hafızada (`SharedPreferences`) saklanır.

### 6. 👥 Önemli Kişiler Rehberi
- Aile, öğretmen ve doktor iletişim kayıtlarını ekleme, düzenleme ve arama.
- Tamamen boş başlar, kullanıcının gerçek kişileri kaydetmesine olanak tanır.

### 7. 🚨 Afet ve Acil Durum Modülü
- Deprem, yangın vb. afet durumları için acil durum düdüğü, fener ve güvenlik adımları.

### 8. 📋 Görev Listesi & Günlük Rutin Takipçisi
- Günlük rutinlerin adım adım tamamlanması ve yıldız kazanma sistemi.

### 9. 😊 Kendini Değerlendirme & Duygu Takibi
- Duygu durumunu Makaton sembolleri ile ifade etme ve gün sonu değerlendirmesi.

### 10. 🍳 Mutfak Güvenliği
- Mutfakta ocak, bıçak, sıcak yüzeyler için görsel güvenlik kuralları.

### 11. 🎮 Oyun ve Sosyal Öyküler
- Sosyal durumlara hazırlık öyküleri ve eğitici mini oyunlar.

### 12. 🎨 Serbest Zaman Planlayıcısı
- Dinlenme, müzik ve oyun saatlerini organize etme.

---

## 🛠️ Teknolojiler ve Kütüphaneler

- **Framework:** Flutter 3.x (Dart 3.x)
- **Durum Yönetimi (State Management):** `provider`
- **Yerel Depolama (Local Persistence):** `shared_preferences`, `sqflite`
- **Ses & Titreşim:** `audioplayers`, `flutter_tts`, `HapticFeedback`
- **Erişilebilirlik:** Neumorphic ve blok-renk tabanlı kontrast arayüz
- **Test:** Kapsamlı birim ve widget test paketi (57+ test)

---

## 📦 Kurulum ve Çalıştırma

1. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

2. **Testleri çalıştırın:**
   ```bash
   flutter test
   ```

3. **Uygulamayı başlatın:**
   ```bash
   flutter run
   ```

---

## 📄 Lisans
Bu proje özel eğitim ve rehabilitasyon desteği amacıyla geliştirilmiştir.
