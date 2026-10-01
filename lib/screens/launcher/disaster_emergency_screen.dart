import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/disaster_dictionary_data.dart';
import '../../theme/app_theme.dart';

class DisasterEmergencyScreen extends StatefulWidget {
  const DisasterEmergencyScreen({super.key});

  @override
  State<DisasterEmergencyScreen> createState() => _DisasterEmergencyScreenState();
}

class _DisasterEmergencyScreenState extends State<DisasterEmergencyScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late TabController _tabController;

  // Düdük durumu
  bool _isWhistleActive = false;
  Timer? _whistleTimer;

  // Sözlük arama ve filtreleri
  String _searchQuery = '';
  String _selectedCategory = 'TÜMÜ';
  String? _selectedLetter;

  // 5 Temel Afet Eğitimi (Kullanıcı İsteği: Deprem, Yangın, Sel, Trafik Kazası, Kaybolma)
  final List<DisasterCourse> _courses = [
    DisasterCourse(
      id: 'deprem',
      title: 'Deprem Eğitimi',
      shortTitle: 'DEPREM',
      description: 'Sarsıntı anında ne yapmalısın? Çök - Kapan - Tutun hareketi.',
      icon: Icons.shield_rounded,
      color: const Color(0xFFD97706),
      moodleUrl: 'https://afadotizmdown.ogu.edu.tr/moodle/course/view.php?id=2&section=2',
      youtubeUrl: 'https://www.youtube.com/results?search_query=AFAD+özel+gereksinimli+bireyler+deprem+çök+kapan+tutun',
      bookPages: [
        DisasterBookPage(
          pageNumber: 1,
          title: 'Deprem Başladığında Sakin Ol',
          text: 'Yerin sallandığını hissettiğinde korkma, derin nefes al. Panikle koşma ve balkona ya da merdivenlere koşma.',
          imageAsset: 'assets/images/disaster_dict/page_7_img_1.png',
          tip: 'Sakin kalmak ve doğru yere geçmek seni korur.',
        ),
        DisasterBookPage(
          pageNumber: 2,
          title: '1. Adım: ÇÖK!',
          text: 'Sağlam bir koltuk, kanepe veya dayanıklı bir masanın yanına dizlerinin üstüne çök.',
          imageAsset: 'assets/images/disaster_dict/page_32_img_1.png',
          tip: 'Ayakta kalma, hemen yere çökmelisin.',
        ),
        DisasterBookPage(
          pageNumber: 3,
          title: '2. Adım: KAPAN!',
          text: 'Başını ve enseni iki elinle veya bir yastıkla kapat. Hedefini olabildiğince küçült.',
          imageAsset: 'assets/images/disaster_dict/page_32_img_1.png',
          tip: 'Başını korumak en önemli kuraldır.',
        ),
        DisasterBookPage(
          pageNumber: 4,
          title: '3. Adım: TUTUN!',
          text: 'Sarsıntı tamamen bitene kadar sağlam eşyaya tutun. Asla asansöre binme!',
          imageAsset: 'assets/images/disaster_dict/page_31_img_0.png',
          tip: 'Asansör kullanmak tehlikelidir!',
        ),
        DisasterBookPage(
          pageNumber: 5,
          title: 'Toplanma Alanına Çık',
          text: 'Sarsıntı durduktan sonra acil durum çantanı al, merdivenlerden sakince inerek açık toplanma alanına git.',
          imageAsset: 'assets/images/disaster_dict/page_36_img_0.png',
          tip: 'Güvenli açık alanda büyüklerini bekle.',
        ),
      ],
    ),
    DisasterCourse(
      id: 'yangin',
      title: 'Yangın Eğitimi',
      shortTitle: 'YANGIN',
      description: 'Duman ve alev gördüğünde ne yapmalısın? Eğilerek güvenli tahliye.',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFEA580C),
      moodleUrl: 'https://afadotizmdown.ogu.edu.tr/moodle/course/view.php?id=2&section=3',
      youtubeUrl: 'https://www.youtube.com/results?search_query=AFAD+özel+gereksinimli+bireyler+yangın+tahliye',
      bookPages: [
        DisasterBookPage(
          pageNumber: 1,
          title: 'Yangın Gördüğünde Haber Ver',
          text: 'Alev veya duman gördüğünde hemen büyüklerine haber ver veya yangın alarm butonuna bas. 112 İtfaiyeyi ara.',
          imageAsset: 'assets/images/disaster_dict/page_12_img_0.png',
          tip: 'Yangına kendin müdahale etme, yardım çağır.',
        ),
        DisasterBookPage(
          pageNumber: 2,
          title: 'Dumanı İçine Çekme!',
          text: 'Duman yukarı çıkar. Bu yüzden yere yakın kal, dizlerinin ve ellerinin üzerinde eğilerek ilerle.',
          imageAsset: 'assets/images/disaster_dict/page_33_img_0.png',
          tip: 'Yere yakın hava daha temizdir.',
        ),
        DisasterBookPage(
          pageNumber: 3,
          title: 'Ağzını ve Burnunu Kapat',
          text: 'Islak ya da kuru bir bezle veya tişörtünle ağzını ve burnunu kapatarak nefes al.',
          imageAsset: 'assets/images/disaster_dict/page_33_img_0.png',
          tip: 'Duman ciğerlerini rahatsız etmesin.',
        ),
        DisasterBookPage(
          pageNumber: 4,
          title: 'Acil Çıkış ve Merdivenleri Kullan',
          text: 'Asansöre kesinlikle binme! Yangın merdiveni veya acil çıkış kapısından hızlıca dışarı çık.',
          imageAsset: 'assets/images/disaster_dict/page_16_img_0.png',
          tip: 'Acil çıkış kapıları yeşil tabelayla gösterilir.',
        ),
        DisasterBookPage(
          pageNumber: 5,
          title: 'İtfaiye ve Toplanma Alanı',
          text: 'Binadan çıktıktan sonra toplanma alanında bekle. İtfaiyeciler gelip yangını söndürecektir.',
          imageAsset: 'assets/images/disaster_dict/page_40_img_0.png',
          tip: 'İtfaiyeciler üzerinde itfaiye yazan üniforma giyer.',
        ),
      ],
    ),
    DisasterCourse(
      id: 'sel',
      title: 'Sel Eğitimi',
      shortTitle: 'SEL',
      description: 'Aşırı yağmur ve su baskınında ne yapmalısın? Yüksek yere geçiş.',
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF0284C7),
      moodleUrl: 'https://afadotizmdown.ogu.edu.tr/moodle/course/view.php?id=2&section=4',
      youtubeUrl: 'https://www.youtube.com/results?search_query=AFAD+sel+afeti+özel+gereksinimli+eğitim',
      bookPages: [
        DisasterBookPage(
          pageNumber: 1,
          title: 'Sel ve Su Baskını',
          text: 'Çok fazla yağmur yağdığında caddeler ve sokaklar suyla dolabilir. Buna sel denir.',
          imageAsset: 'assets/images/disaster_dict/page_10_img_0.png',
          tip: 'Su hızla yükselebilir, dikkatli ol.',
        ),
        DisasterBookPage(
          pageNumber: 2,
          title: 'Su Birikintisine Girme!',
          text: 'Yerdeki çamurlu ve kirli suların içine asla girme ve suyun derinliğini tahmin etmeye çalışma.',
          imageAsset: 'assets/images/disaster_dict/page_26_img_1.png',
          tip: 'Akıntı seni veya eşyalarını sürükleyebilir.',
        ),
        DisasterBookPage(
          pageNumber: 3,
          title: 'Hemen Yüksek Bir Yere Çık',
          text: 'Bulunduğun alandaki en yüksek tepeye veya binanın üst katlarına güvenle çık.',
          imageAsset: 'assets/images/disaster_dict/page_30_img_1.png',
          tip: 'Sel sırasında yüksek yerlerde güvende olursun.',
        ),
        DisasterBookPage(
          pageNumber: 4,
          title: 'Elektrik Tellerinden Uzak Dur',
          text: 'Kopan elektrik kabloları veya elektrik direklerine sakın dokunma, hemen uzaklaş.',
          imageAsset: 'assets/images/disaster_dict/page_44_img_0.png',
          tip: 'Su elektriği iletir, elektrik tehlikelidir!',
        ),
        DisasterBookPage(
          pageNumber: 5,
          title: 'Kurtarma Ekiplerini Bekle',
          text: 'Yüksek ve güvenli yerde bekle. AFAD ve kurtarma ekipleri bot veya helikopterle yardımına gelecektir.',
          imageAsset: 'assets/images/disaster_dict/page_25_img_0.png',
          tip: '112 Acil Yardım numarasını arayabilirsin.',
        ),
      ],
    ),
    DisasterCourse(
      id: 'trafik_kazasi',
      title: 'Trafik Kazası Eğitimi',
      shortTitle: 'TRAFİK KAZASI',
      description: 'Kaza anında ne yapmalısın? Güvenli bölgede kalma ve 112 çağrısı.',
      icon: Icons.car_crash_rounded,
      color: const Color(0xFF7C3AED),
      moodleUrl: 'https://afadotizmdown.ogu.edu.tr/moodle/course/view.php?id=2&section=5',
      youtubeUrl: 'https://www.youtube.com/results?search_query=özel+gereksinimli+bireyler+trafik+kazası+güvenlik',
      bookPages: [
        DisasterBookPage(
          pageNumber: 1,
          title: 'Kaza Anında Sakin Ol',
          text: 'Araba ya da otobüs bir şeye çarptığında sakin kal. Hemen emniyet kemerini çözüp araçtan inmeye çalışma.',
          imageAsset: 'assets/images/disaster_dict/page_13_img_0.png',
          tip: 'Önce etrafının güvenli olduğundan emin ol.',
        ),
        DisasterBookPage(
          pageNumber: 2,
          title: 'Yol Kenarına / Kaldırıma Geç',
          text: 'Arabadan güvenle indiğinde asla yolun ortasında durma. Kaldırıma veya bariyerlerin arkasına geç.',
          imageAsset: 'assets/images/disaster_dict/page_34_img_0.png',
          tip: 'Gelen diğer arabalara karşı güvende kal.',
        ),
        DisasterBookPage(
          pageNumber: 3,
          title: '112 Acil Çağrı Merkezini Ara',
          text: 'Telefonun varsa 112’yi ara ve kazanın yerini söyle. Yanındaki yetişkinlerden yardım iste.',
          imageAsset: 'assets/images/disaster_dict/page_16_img_1.png',
          tip: '112 numarası ambulans ve polisi hemen yönlendirir.',
        ),
        DisasterBookPage(
          pageNumber: 4,
          title: 'Yaralılara Sağlık Ekibi Gelir',
          text: 'Eğer birisi yaralandıysa sağlık personeli ve ambulans gelene kadar onu gereksiz hareket ettirme.',
          imageAsset: 'assets/images/disaster_dict/page_42_img_0.png',
          tip: 'Ambulans yaralıları hızla hastaneye götürür.',
        ),
        DisasterBookPage(
          pageNumber: 5,
          title: 'Polis ve Sağlık Ekiplerine Güven',
          text: 'Olay yerine gelen polis ve sağlık görevlilerine ailene ait telefon numarasını ver.',
          imageAsset: 'assets/images/disaster_dict/page_41_img_0.png',
          tip: 'Polis ve sağlıkçılar senin güvenliğini sağlar.',
        ),
      ],
    ),
    DisasterCourse(
      id: 'kaybolma',
      title: 'Kaybolma Eğitimi',
      shortTitle: 'KAYBOLMA',
      description: 'Nerede olduğunu bilmediğinde ne yapmalısın? 3 temel güvenlik adımı.',
      icon: Icons.person_pin_circle_rounded,
      color: const Color(0xFFDC2626),
      moodleUrl: 'https://afadotizmdown.ogu.edu.tr/moodle/course/view.php?id=2&section=6',
      youtubeUrl: 'https://www.youtube.com/results?search_query=özel+gereksinimli+kaybolduğunda+ne+yapmalı',
      bookPages: [
        DisasterBookPage(
          pageNumber: 1,
          title: 'Nerede Olduğunu Bilmediğinde',
          text: 'Aileni veya öğretmenini kaybettiğinde korkma. Sakin ol ve bulunduğun yerden daha uzağa koşma.',
          imageAsset: 'assets/images/disaster_dict/page_14_img_0.png',
          tip: 'En güvenli hareket olduğun yerde beklemektir.',
        ),
        DisasterBookPage(
          pageNumber: 2,
          title: '1. Çevredeki Dükkâna Sor',
          text: 'Yakınında bir market, bakkal veya eczane varsa içeri gir. Görevliye adresini veya aileni aramasını söyle.',
          imageAsset: 'assets/images/disaster_dict/page_35_img_0.png',
          tip: 'Esnaf veya görevliler sana hemen destek olur.',
        ),
        DisasterBookPage(
          pageNumber: 3,
          title: '2. Polisten Yardım İste',
          text: 'Çevrende polis veya zabıta üniforması giymiş birini görürsen hemen yanına git ve "Kayboldum" de.',
          imageAsset: 'assets/images/disaster_dict/page_41_img_0.png',
          tip: 'Polis seni korur ve ailene ulaştırır.',
        ),
        DisasterBookPage(
          pageNumber: 4,
          title: '3. Aileni Ara ve Konum Gönder',
          text: 'Telefonundaki "Aileni Ara" butonuna basarak anne ya da babanı ara. Konumun otomatik gönderilecektir.',
          imageAsset: 'assets/images/disaster_dict/page_34_img_1.png',
          tip: 'Mesaj ile nerede olduğun ailene iletilir.',
        ),
        DisasterBookPage(
          pageNumber: 5,
          title: 'Bulunduğun Yerden Asla Ayrılma!',
          text: 'Aileni aradıktan sonra sakın başka yere gitme. Ailen seni aramak için oraya gelecektir.',
          imageAsset: 'assets/images/disaster_dict/page_36_img_0.png',
          tip: 'Olduğun yerde güvenle bekle.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  void _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void _toggleWhistle() {
    if (_isWhistleActive) {
      _whistleTimer?.cancel();
      _tts.stop();
      setState(() => _isWhistleActive = false);
    } else {
      setState(() => _isWhistleActive = true);
      _playWhistleCycle();
      _whistleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _playWhistleCycle();
      });
    }
  }

  void _playWhistleCycle() async {
    await _tts.speak('Düdük! Buradayım, yardım edin!');
  }

  @override
  void dispose() {
    _whistleTimer?.cancel();
    _tts.stop();
    _tabController.dispose();
    super.dispose();
  }

  // --- KİTAP MODU GÖSTERİCİSİ ---
  void _openBookViewer(DisasterCourse course) {
    showDialog(
      context: context,
      builder: (ctx) => _DisasterBookViewerModal(
        course: course,
        onSpeak: _speak,
      ),
    );
  }

  // --- YOUTUBE VİDEO MODU ---
  void _openVideoLauncher(DisasterCourse course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.play_circle_filled_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const Text('YouTube Video ve AFAD Eğitimleri', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Text(
                '${course.title} konusu için AFAD ve ESOGÜ Otizm Down projesinin video modelleme ve farkındalık videolarını izleyebilirsiniz.',
                style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.video_library_rounded),
                label: const Text('YouTube\'da Eğitim Videosu İzle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(course.youtubeUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {}
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.buttonIndigo,
                  side: const BorderSide(color: AppColors.buttonIndigo),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.school_rounded, size: 20),
                label: const Text('AFAD Moodle Eğitim Sayfasını Aç', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(course.moodleUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SÖZLÜK TERİMİ DETAY KARTI ---
  void _openTermDetailModal(DisasterTerm term) {
    _speak('${term.title}. ${term.definition}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.buttonIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    term.category,
                    style: const TextStyle(color: AppColors.buttonIndigo, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _tts.stop();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Büyük Piktogram Görseli
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          term.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Başlık
                    Text(
                      term.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    // Açıklama Metni Kutusu
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        term.definition,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sesli Oku Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonIndigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.volume_up_rounded, size: 24),
                        label: const Text('Sesli Oku / Tekrar Dinle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () => _speak('${term.title}. ${term.definition}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            _whistleTimer?.cancel();
            _tts.stop();
            Navigator.pop(context);
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Afet ve Acil Durum', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.buttonIndigo,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppColors.buttonIndigo,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_rounded), text: 'Afet Eğitimleri'),
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Afet Sözlüğü'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrainingsTab(),
          _buildDictionaryTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: AFET EĞİTİMLERİ (KİTAP & VİDEO)
  // ==========================================
  Widget _buildTrainingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Düdük & 112 Hızlı Butonları
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isWhistleActive ? [Colors.orange.shade800, Colors.red.shade900] : [Colors.red.shade700, Colors.red.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isWhistleActive ? 'Düdük Çalıyor!' : 'Acil Durum Düdüğü',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ses çıkarmak veya yardım çağırmak için bas.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_isWhistleActive ? Icons.stop_rounded : Icons.campaign_rounded, size: 20),
                  label: Text(_isWhistleActive ? 'DURDUR' : 'DÜDÜK'),
                  onPressed: _toggleWhistle,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Başlık
          const Text(
            'Afet ve Acil Durumda Ne Yapacaksın?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aşağıdaki 5 temel afeti hem Kitap hem YouTube Videosu olarak öğrenebilirsin:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // 5 Eğitim Kartı
          ..._courses.map((course) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: course.color.withValues(alpha: 0.25), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: course.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(course.icon, color: course.color, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(course.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // İki Seçenek: Kitap Olarak Oku & YouTube Video İzle
                    Row(
                      children: [
                        // Kitap Butonu
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: course.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 19),
                            label: const Text('Kitap Olarak Oku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _openBookViewer(course),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // YouTube Butonu
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 19, color: Colors.red),
                            label: const Text('YouTube Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _openVideoLauncher(course),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: AFET SÖZLÜĞÜ (ALFABETİK & RESİMLİ)
  // ==========================================
  Widget _buildDictionaryTab() {
    final allTerms = DisasterDictionaryData.terms;

    // Filtreleme
    final filteredTerms = allTerms.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.definition.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'TÜMÜ' || t.category == _selectedCategory;

      final matchesLetter = _selectedLetter == null || t.firstLetter == _selectedLetter;

      return matchesSearch && matchesCategory && matchesLetter;
    }).toList();

    final categories = ['TÜMÜ', 'AFETLER', 'ACİL DURUMLAR', 'GENEL TERİMLER', 'UYGUN EYLEMLER', 'GÜVENİLİR BİNALAR', 'GÜVENİLİR PERSONEL', 'GÜVENİLİR ARAÇLAR', 'UYARI İŞARETLERİ'];
    final letters = DisasterDictionaryData.availableLetters;

    return Column(
      children: [
        // Arama ve Filtre Üst Alanı
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Arama Çubuğu
              TextField(
                decoration: InputDecoration(
                  hintText: 'Sözlükte kelime ara (Deprem, Düdük, AFAD...)',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.buttonIndigo),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 10),

              // Harf Filtresi (Alfabetik Çubuk)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('Tümü', style: TextStyle(fontSize: 12)),
                        selected: _selectedLetter == null,
                        selectedColor: AppColors.buttonIndigo,
                        labelStyle: TextStyle(color: _selectedLetter == null ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() => _selectedLetter = null),
                      ),
                    ),
                    ...letters.map((l) {
                      final isSel = _selectedLetter == l;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(l, style: const TextStyle(fontSize: 12)),
                          selected: isSel,
                          selectedColor: AppColors.buttonIndigo,
                          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          onSelected: (_) => setState(() => _selectedLetter = isSel ? null : l),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Kategori Filtresi
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: AppColors.buttonIndigo.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.buttonIndigo,
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.buttonIndigo : Colors.grey.shade700,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Kelimeler Listesi
        Expanded(
          child: filteredTerms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Aradığınız terim bulunamadı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Farklı bir arama kelimesi veya harf seçebilirsiniz.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredTerms.length,
                  itemBuilder: (context, index) {
                    final term = filteredTerms[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: const [
                          BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openTermDetailModal(term),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Küçük Resim (Piktogram)
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      term.imageAsset,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.image_outlined, size: 28, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Terim Başlığı & Kategori
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.buttonIndigo.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              term.category,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.buttonIndigo),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        term.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        term.definition,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),

                                // Sesli Dinle Butonu
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo),
                                  tooltip: 'Sesli Oku',
                                  onPressed: () => _speak('${term.title}. ${term.definition}'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==========================================
// KİTAP MODU MODALI (DİJİTAL SOSYAL ÖYKÜ KİTABI)
// ==========================================
class _DisasterBookViewerModal extends StatefulWidget {
  final DisasterCourse course;
  final Function(String) onSpeak;

  const _DisasterBookViewerModal({
    required this.course,
    required this.onSpeak,
  });

  @override
  State<_DisasterBookViewerModal> createState() => _DisasterBookViewerModalState();
}

class _DisasterBookViewerModalState extends State<_DisasterBookViewerModal> {
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _speakCurrentPage();
  }

  void _speakCurrentPage() {
    final page = widget.course.bookPages[_currentPageIndex];
    widget.onSpeak('${page.title}. ${page.text}');
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.course.bookPages;
    final currentPage = pages[_currentPageIndex];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst Başlık & Kapat Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: widget.course.color),
                      const SizedBox(width: 8),
                      Text(
                        widget.course.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.course.color),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Sayfa İlerleme Çubuğu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sayfa ${_currentPageIndex + 1} / ${pages.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.buttonIndigo),
                    tooltip: 'Bu Sayfayı Sesli Oku',
                    onPressed: _speakCurrentPage,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Büyük Sayfa Görseli
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    currentPage.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

            // Sayfa Başlığı
            Text(
              currentPage.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            // Sayfa Metni
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentPage.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, height: 1.4, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 10),

            // Önemli İpucu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    currentPage.tip,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // İlerleme Butonları (Önceki & Sonraki)
            Row(
              children: [
                if (_currentPageIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                      label: const Text('Önceki'),
                      onPressed: () {
                        setState(() => _currentPageIndex--);
                        _speakCurrentPage();
                      },
                    ),
                  ),
                if (_currentPageIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.course.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_currentPageIndex == pages.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded, size: 16),
                    label: Text(_currentPageIndex == pages.length - 1 ? 'Tamamla' : 'Sonraki'),
                    onPressed: () {
                      if (_currentPageIndex < pages.length - 1) {
                        setState(() => _currentPageIndex++);
                        _speakCurrentPage();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}

// ==========================================
// MODELLER
// ==========================================
class DisasterCourse {
  final String id;
  final String title;
  final String shortTitle;
  final String description;
  final IconData icon;
  final Color color;
  final String moodleUrl;
  final String youtubeUrl;
  final List<DisasterBookPage> bookPages;

  const DisasterCourse({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.moodleUrl,
    required this.youtubeUrl,
    required this.bookPages,
  });
}

class DisasterBookPage {
  final int pageNumber;
  final String title;
  final String text;
  final String imageAsset;
  final String tip;

  const DisasterBookPage({
    required this.pageNumber,
    required this.title,
    required this.text,
    required this.imageAsset,
    required this.tip,
  });
}
