import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';

/// Form Seçenekleri (Word Belgeleri)
enum EvaluationFormType {
  isyeri,
  okul,
  tumGun,
}

/// Soru Giriş Türleri
enum QuestionInputType {
  date,
  yesNo,
  multiChoice,
  singleChoice,
  textVoice,
  time,
}

/// Değerlendirme Sorusu Modeli
class EvalQuestion {
  final String id;
  final String text;
  final QuestionInputType inputType;
  final List<String>? options;
  final List<String>? quickSuggestions;
  final String? followUpIfYes;
  final String? hint;

  const EvalQuestion({
    required this.id,
    required this.text,
    required this.inputType,
    this.options,
    this.quickSuggestions,
    this.followUpIfYes,
    this.hint,
  });
}

/// Sohbet Mesajı Modeli
class ChatMessage {
  final String sender; // 'bot' veya 'user'
  final String text;
  final DateTime timestamp;
  final bool isCelebration;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isCelebration = false,
  });

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isCelebration': isCelebration,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        sender: json['sender'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isCelebration: json['isCelebration'] as bool? ?? false,
      );
}

class SelfEvaluationScreen extends StatefulWidget {
  const SelfEvaluationScreen({super.key});

  @override
  State<SelfEvaluationScreen> createState() => _SelfEvaluationScreenState();
}

class _SelfEvaluationScreenState extends State<SelfEvaluationScreen>
    with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  EvaluationFormType? _activeFormType;
  List<EvalQuestion> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isWaitingForFollowUp = false;

  final List<ChatMessage> _messages = [];
  final Map<String, dynamic> _answers = {};

  bool _isListening = false;
  bool _sttAvailable = false;
  bool _isBotTyping = false;
  bool _soundEnabled = true;

  // Çoklu seçim geçici durumu
  final Set<String> _selectedMultiOptions = {};
  final TextEditingController _otherTextController = TextEditingController();
  bool _isOtherSelected = false;

  // Tarih sorusu geçici durumu
  DateTime _selectedDate = DateTime.now();

  late AnimationController _micPulseController;

  @override
  void initState() {
    super.initState();
    _initServices();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  Future<void> _initServices() async {
    await _tts.initialize();
    try {
      final available = await _speech.initialize(
        onError: (err) => debugPrint('STT Hata: $err'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              _micPulseController.stop();
              setState(() => _isListening = false);
            }
          }
        },
      );
      if (mounted) {
        setState(() => _sttAvailable = available);
      }
    } catch (e) {
      debugPrint('STT Başlatma Hatası: $e');
    }
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _otherTextController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // FORM SEÇİMİ VE SORU LİSTELERİ (3 Word Dosyası)
  // ─────────────────────────────────────────────────────────────

  void _startForm(EvaluationFormType type) {
    setState(() {
      _activeFormType = type;
      _currentQuestionIndex = 0;
      _isWaitingForFollowUp = false;
      _messages.clear();
      _answers.clear();
      _selectedMultiOptions.clear();
      _isOtherSelected = false;
      _otherTextController.clear();
      _textController.clear();
      _selectedDate = DateTime.now();

      switch (type) {
        case EvaluationFormType.isyeri:
          _currentQuestions = _getIsyeriQuestions();
          break;
        case EvaluationFormType.okul:
          _currentQuestions = _getOkulQuestions();
          break;
        case EvaluationFormType.tumGun:
          _currentQuestions = _getTumGunQuestions();
          break;
      }
    });

    // Açılış selamlama mesajı
    String welcomeMsg = '';
    switch (type) {
      case EvaluationFormType.isyeri:
        welcomeMsg =
            'Merhaba! 🏢 Bugün iş yerinde gününün nasıl geçtiğini birlikte değerlendirelim. Sorularımı yanıtlamaya hazır mısın?';
        break;
      case EvaluationFormType.okul:
        welcomeMsg =
            'Merhaba! 🎒 Bugün okulda gününün nasıl geçtiğini birlikte değerlendirelim. Sorularımı sırayla yanıtlayalım!';
        break;
      case EvaluationFormType.tumGun:
        welcomeMsg =
            'Merhaba! ☀️ Bugün gününün nasıl geçtiğini adım adım değerlendirelim. Hazırsan başlayalım!';
        break;
    }

    _addBotMessage(welcomeMsg, speak: true).then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _askCurrentQuestion();
      });
    });
  }

  // 1. İŞYERİ GÖZLEM FORMU
  List<EvalQuestion> _getIsyeriQuestions() {
    return const [
      EvalQuestion(
        id: 'is_tarih',
        text: 'Tarihi Seç:',
        inputType: QuestionInputType.date,
      ),
      EvalQuestion(
        id: 'is_yer_adi',
        text: 'Çalıştığım yerin adı nedir?',
        inputType: QuestionInputType.textVoice,
        hint: 'Örn: ABC Market, Ofis, Kafe...',
      ),
      EvalQuestion(
        id: 'is_mesai_saatleri',
        text: 'Mesai saatlerim nasıldı?',
        inputType: QuestionInputType.textVoice,
        quickSuggestions: ['08:00 - 17:00', '08:30 - 17:30', '09:00 - 18:00', 'Vardiyalı'],
        hint: 'Mesai başlangıç ve bitiş saatlerini belirt...',
      ),
      EvalQuestion(
        id: 'is_gelis_saati',
        text: 'Bugün işe saat kaçta geldim?',
        inputType: QuestionInputType.time,
        quickSuggestions: ['08:00', '08:15', '08:30', '08:45', '09:00'],
      ),
      EvalQuestion(
        id: 'is_vaktinde_geldim_mi',
        text: 'Bugün işe vaktinde geldim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_mesaiye_uydum_mu',
        text: 'Bugün mesai saatlerime uydum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_tamamlanan_isler',
        text: 'Bugün hangi işleri tamamladım?',
        inputType: QuestionInputType.textVoice,
        quickSuggestions: [
          'Masa Düzenleme',
          'Dosyalama',
          'Temizlik',
          'Koli Taşıma',
          'Müşteri Karşılama',
          'Veri Girişi'
        ],
        hint: 'Tamamladığın işleri yaz veya mikrofonla anlat...',
      ),
      EvalQuestion(
        id: 'is_her_seyi_yaptim_mi',
        text: 'Bugün işte yapmam gereken her şeyi yaptım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_yapilan_is_nasildi',
        text: 'Bugün yaptığım iş nasıldı? (Birden fazla seçebilirsiniz)',
        inputType: QuestionInputType.multiChoice,
        options: [
          'Kolaydı',
          'Zordu',
          'Eğlenceliydi',
          'İlginçti',
          'Yorucuydu',
          'Sıkıcıydı',
          'Diğer'
        ],
      ),
      EvalQuestion(
        id: 'is_zorluk_cektim_mi',
        text: 'Bugün işimi yaparken zorluk çektim mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Zorlandığınız işleri yazınız veya sesli söyleyiniz:',
      ),
      EvalQuestion(
        id: 'is_zorluk_cozum',
        text: 'Bugün işimde karşılaştığım zorlukları nasıl çözdüm?',
        inputType: QuestionInputType.singleChoice,
        options: [
          'Karşılaştığım zorluğu çözemedim',
          'Kendi başıma çözdüm.',
          'İş arkadaşımın yardımıyla çözdüm.',
          'Müdürümün yardımıyla çözdüm.',
          'İş koçumun yardımıyla çözdüm.',
          'Ailemin yardımıyla çözdüm.',
        ],
      ),
      EvalQuestion(
        id: 'is_kiminle_calistim',
        text: 'Bugün kiminle çalıştım? (İsim yazabilir veya söyleyebilirsin)',
        inputType: QuestionInputType.textVoice,
        hint: 'Birlikte çalıştığın çalışma arkadaşlarının isimleri...',
      ),
      EvalQuestion(
        id: 'is_arkadas_yardim_istedi_mi',
        text: 'Bugün herhangi bir iş arkadaşım benden yardım istedi mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Arkadaşın senden ne istedi yazınız:',
      ),
      EvalQuestion(
        id: 'is_arkadas_gorev_verdi_mi',
        text: 'Bugün iş arkadaşlarından biri sana bir görev verdi mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Hangi görev verildiğini yazınız:',
      ),
      EvalQuestion(
        id: 'is_gorevi_yerine_getirdim_mi',
        text: 'Bugün iş arkadaşımın benden istediği görevi yerine getirdim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_elestiri_aldim_mi',
        text: 'Bugün eleştiri aldım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_sinirlendim_mi',
        text: 'Bugün iş yerinde hiç sinirlendim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_yoruldum_mu',
        text: 'Bugün iş yerinde yoruldum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_stres_oldum_mu',
        text: 'Bugün iş yerinde stres oldum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_memnun_kaldim_mi',
        text: 'Bugün iş yerimde geçirdiğim günden memnun kaldım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'is_en_cok_neyi_sevdim',
        text: 'Bugün işimle ilgili en çok neyi sevdim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Seni en çok mutlu eden şeyi yaz...',
      ),
      EvalQuestion(
        id: 'is_neyi_sevmedim',
        text: 'Bugün iş yerimdeki neyi sevmedim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Hoşuna gitmeyen veya rahatsız olduğun bir an...',
      ),
      EvalQuestion(
        id: 'is_ne_yapilsa_daha_iyi',
        text: 'İş yerimde ne yapılsa daha iyi çalışabilirim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Sana yardımcı olacak önerilerin...',
      ),
    ];
  }

  // 2. OKUL GÖZLEM FORMU
  List<EvalQuestion> _getOkulQuestions() {
    return const [
      EvalQuestion(
        id: 'okul_tarih',
        text: 'Tarihi Seç:',
        inputType: QuestionInputType.date,
      ),
      EvalQuestion(
        id: 'okul_vaktinde_gittim_mi',
        text: 'Bugün okula vaktinde gittim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_derslere_saatinde_girdim_mi',
        text: 'Bugün derslere saatinde girdim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_hangi_dersler_vardi',
        text: 'Bugün hangi derslerim vardı?',
        inputType: QuestionInputType.textVoice,
        quickSuggestions: [
          'Türkçe',
          'Matematik',
          'Resim',
          'Beden Eğitimi',
          'Müzik',
          'Fen Bilimleri',
          'Sosyal Bilgiler'
        ],
        hint: 'Derslerini yaz veya sesli söyle...',
      ),
      EvalQuestion(
        id: 'okul_tum_derslere_girdim_mi',
        text: 'Bugün tüm derslere girdim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_dersler_nasildi',
        text: 'Bugün derslerim nasıldı? (Tek tek veya birden fazla seçebilirsin)',
        inputType: QuestionInputType.multiChoice,
        options: [
          'Kolaydı',
          'Zordu',
          'Eğlenceliydi',
          'İlginçti',
          'Yorucuydu',
          'Sıkıcıydı',
          'Diğer'
        ],
      ),
      EvalQuestion(
        id: 'okul_zorluk_cektim_mi',
        text: 'Bugün derslerde zorluk çektim mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Zorlandığınız dersleri yazınız veya sesli söyleyiniz:',
      ),
      EvalQuestion(
        id: 'okul_zorluk_cozum',
        text: 'Bugün okulda karşılaştığım zorlukları nasıl çözdüm?',
        inputType: QuestionInputType.singleChoice,
        options: [
          'Karşılaştığım zorluğu çözemedim',
          'Kendi başıma çözdüm.',
          'Sınıf arkadaşlarımın yardımıyla çözdüm.',
          'Okul Müdürümün yardımıyla çözdüm.',
          'Öğretmenimin yardımıyla çözdüm.',
          'Ailemin yardımıyla çözdüm.',
        ],
      ),
      EvalQuestion(
        id: 'okul_arkadas_yardim_istedi_mi',
        text: 'Bugün bir okul arkadaşım benden yardım istedi mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Arkadaşının ne yardım istediğini yazınız:',
      ),
      EvalQuestion(
        id: 'okul_ogretmen_gorev_verdi_mi',
        text: 'Bugün öğretmenlerimden biri bana bir görev verdi mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Hangi görev verildiğini yazınız:',
      ),
      EvalQuestion(
        id: 'okul_gorevi_yerine_getirdim_mi',
        text: 'Bugün öğretmenimin benden istediği görevi yerine getirdim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_elestiri_aldim_mi',
        text: 'Bugün eleştiri aldım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_sinirlendim_mi',
        text: 'Bugün okulda hiç sinirlendim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_yoruldum_mu',
        text: 'Bugün okulda yoruldum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_stres_oldum_mu',
        text: 'Bugün okulda stres oldum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_memnun_kaldim_mi',
        text: 'Bugün okulda geçirdiğim vakitten memnun kaldım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'okul_arkadaslarim',
        text: 'Bugün okulda hangi arkadaşlarımla vakit geçirdim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Görüştüğün arkadaşlarının isimleri...',
      ),
      EvalQuestion(
        id: 'okul_en_cok_neyi_sevdim',
        text: 'Bugün okulumla ilgili en çok neyi sevdim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Okuldaki en güzel anın...',
      ),
      EvalQuestion(
        id: 'okul_neyi_sevmedim',
        text: 'Bugün okulumdaki neyi sevmedim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Seni üzen veya canını sıkan bir şey...',
      ),
      EvalQuestion(
        id: 'okul_ogretmen_onerisi',
        text: 'Öğretmenim ne yaparsa dersleri daha iyi anlarım?',
        inputType: QuestionInputType.textVoice,
        hint: 'Öğretmenine önerin veya fikirlerin...',
      ),
    ];
  }

  // 3. TÜM GÜN GÖZLEM FORMU
  List<EvalQuestion> _getTumGunQuestions() {
    return const [
      EvalQuestion(
        id: 'gun_tarih',
        text: 'Tarihi Seç:',
        inputType: QuestionInputType.date,
      ),
      EvalQuestion(
        id: 'gun_kacta_uyandim',
        text: 'Bugün kaçta uyandım?',
        inputType: QuestionInputType.time,
        quickSuggestions: ['07:00', '07:30', '08:00', '08:30', '09:00', '09:30'],
      ),
      EvalQuestion(
        id: 'gun_neler_yaptim',
        text: 'Bugün neler yaptım? (Sesli yazdırma yapabilirsin)',
        inputType: QuestionInputType.textVoice,
        hint: 'Gün içindeki önemli aktivitelerini anlat...',
      ),
      EvalQuestion(
        id: 'gun_her_seyi_yaptim_mi',
        text: 'Bugün yapmam gereken her şeyi yaptım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_nasil_gecti',
        text: 'Bugün nasıldı? (Birden fazla seçebilirsiniz)',
        inputType: QuestionInputType.multiChoice,
        options: [
          'Kolaydı',
          'Zordu',
          'Eğlenceliydi',
          'İlginçti',
          'Yorucuydu',
          'Sıkıcıydı',
          'Diğer'
        ],
      ),
      EvalQuestion(
        id: 'gun_zorlandigim_sey',
        text: 'Bugün yapmakta zorlandığın bir şey oldu mu?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Zorlandığın şeyleri yazınız veya sesli söyleyiniz:',
      ),
      EvalQuestion(
        id: 'gun_zorluk_cozum',
        text: 'Bugün karşılaştığım zorlukları nasıl çözdüm?',
        inputType: QuestionInputType.singleChoice,
        options: [
          'Karşılaştığım zorluğu çözemedim',
          'Kendi başıma çözdüm.',
          'Bir arkadaşımın yardımıyla çözdüm.',
          'Müdürümün yardımıyla çözdüm.',
          'İş koçumun yardımıyla çözdüm.',
          'Ailemin yardımıyla çözdüm.',
        ],
      ),
      EvalQuestion(
        id: 'gun_kiminle_vakit_gecirdim',
        text: 'Bugün kiminle vakit geçirdim? (İsim yazabilir veya söyleyebilirsin)',
        inputType: QuestionInputType.textVoice,
        hint: 'Birlikte olduğun kişilerin isimleri...',
      ),
      EvalQuestion(
        id: 'gun_yardim_istendi_mi',
        text: 'Bugün biri benden yardım istedi mi?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Ne istediğini yazınız:',
      ),
      EvalQuestion(
        id: 'gun_evde_gorev_var_miydi',
        text: 'Bugün evde bir görevim var mıydı?',
        inputType: QuestionInputType.yesNo,
        followUpIfYes: 'Hangi görev olduğunu yazınız:',
      ),
      EvalQuestion(
        id: 'gun_ev_gorevini_yaptim_mi',
        text: 'Bugün evdeki görevimi yaptım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_elestiri_aldim_mi',
        text: 'Bugün eleştiri aldım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_sinirlendim_mi',
        text: 'Bugün hiç sinirlendim mi?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_yoruldum_mu',
        text: 'Bugün yoruldum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_stres_oldum_mu',
        text: 'Bugün stres oldum mu?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_memnun_kaldim_mi',
        text: 'Bugün geçirdiğim günden memnun kaldım mı?',
        inputType: QuestionInputType.yesNo,
      ),
      EvalQuestion(
        id: 'gun_en_cok_neyi_sevdim',
        text: 'Bugünle ilgili en çok neyi sevdim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Günün en parlak anını paylaş...',
      ),
      EvalQuestion(
        id: 'gun_neyi_sevmedim',
        text: 'Bugünle ilgili neyi sevmedim?',
        inputType: QuestionInputType.textVoice,
        hint: 'Hoşuna gitmeyen bir detayı yaz...',
      ),
      EvalQuestion(
        id: 'gun_yarin_ne_daha_iyi',
        text: 'Yarın neyi daha iyi yapmak istiyorum?',
        inputType: QuestionInputType.textVoice,
        hint: 'Yarın için hedefin veya dileğin...',
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT AKIŞI VE MESAJLAŞMA
  // ─────────────────────────────────────────────────────────────

  Future<void> _addBotMessage(String text, {bool speak = true}) async {
    setState(() => _isBotTyping = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _isBotTyping = false;
      _messages.add(ChatMessage(
        sender: 'bot',
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    if (speak && _soundEnabled) {
      _tts.speak(text);
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        sender: 'user',
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _askCurrentQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length) {
      final q = _currentQuestions[_currentQuestionIndex];
      _addBotMessage(q.text, speak: true);
    } else {
      _finishEvaluation();
    }
  }

  // Kullanıcı Yanıtını İşleme
  void _submitAnswer(String answerText, {dynamic rawValue}) {
    if (_currentQuestionIndex >= _currentQuestions.length) return;
    final q = _currentQuestions[_currentQuestionIndex];

    _addUserMessage(answerText);
    _answers[q.id] = rawValue ?? answerText;

    // Özel Evet/Hayır durumunda ek soru (Follow-up) var mı?
    if (!_isWaitingForFollowUp &&
        answerText == 'Evet' &&
        q.followUpIfYes != null &&
        q.followUpIfYes!.isNotEmpty) {
      _isWaitingForFollowUp = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        _addBotMessage(q.followUpIfYes!, speak: true);
      });
      return;
    }

    // Normal akış veya ek sorunun yanıtı tamamlandıysa bir sonraki soruya geç
    _isWaitingForFollowUp = false;
    _textController.clear();
    _selectedMultiOptions.clear();
    _isOtherSelected = false;
    _otherTextController.clear();

    _currentQuestionIndex++;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _askCurrentQuestion();
      }
    });
  }

  // Değerlendirme Tamamlandı
  Future<void> _finishEvaluation() async {
    final formName = _getFormName(_activeFormType);
    final completionMsg =
        'Tebrik ederim! 🌟 $formName formunu harika bir şekilde tamamladın. Kendini böyle açık ve samimi ifade ettiğin için seninle gurur duyuyorum!';

    setState(() {
      _messages.add(ChatMessage(
        sender: 'bot',
        text: completionMsg,
        timestamp: DateTime.now(),
        isCelebration: true,
      ));
    });
    _scrollToBottom();

    if (_soundEnabled) {
      _tts.speak(completionMsg);
    }

    await _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('self_evaluations_history') ?? [];

      final record = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'formType': _activeFormType?.name ?? 'genel',
        'formTitle': _getFormName(_activeFormType),
        'date': DateTime.now().toIso8601String(),
        'answers': _answers,
      };

      historyList.insert(0, jsonEncode(record));
      // Son 30 kaydı tut
      if (historyList.length > 30) {
        historyList.removeRange(30, historyList.length);
      }
      await prefs.setStringList('self_evaluations_history', historyList);
    } catch (e) {
      debugPrint('Kayıt Hatası: $e');
    }
  }

  String _getFormName(EvaluationFormType? type) {
    switch (type) {
      case EvaluationFormType.isyeri:
        return 'İşyeri';
      case EvaluationFormType.okul:
        return 'Okul';
      case EvaluationFormType.tumGun:
        return 'Tüm Gün';
      default:
        return 'Gözlem';
    }
  }

  // Sesli Konuşmayı Başlat / Durdur
  void _toggleListening() async {
    if (!_sttAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mikrofon servisi hazır değil. Klavyeden yazabilirsiniz.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      _micPulseController.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _micPulseController.repeat(reverse: true);
      try {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            cancelOnError: false,
            partialResults: true,
          ),
        );
      } catch (e) {
        debugPrint('STT Dinleme Hatası: $e');
        _micPulseController.stop();
        setState(() => _isListening = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ─────────────────────────────────────────────────────────────
  // ARAYÜZ (BUILD)
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_activeFormType != null) {
              _showExitConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _activeFormType == null
              ? 'Kendimi Değerlendiriyorum'
              : '${_getFormName(_activeFormType)} Değerlendirmesi',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_activeFormType != null) ...[
            IconButton(
              icon: Icon(
                _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _soundEnabled ? const Color(0xFF2563EB) : Colors.grey,
              ),
              tooltip: _soundEnabled ? 'Ses Açık' : 'Ses Kapalı',
              onPressed: () {
                setState(() => _soundEnabled = !_soundEnabled);
                if (!_soundEnabled) _tts.stop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded, color: Colors.blueGrey),
              tooltip: 'Formu Yeniden Başlat',
              onPressed: () => _showRestartConfirmation(),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF2563EB)),
              tooltip: 'Geçmiş Değerlendirmelerim',
              onPressed: _showHistorySheet,
            ),
          ],
        ],
        bottom: _activeFormType != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: _currentQuestions.isEmpty
                      ? 0
                      : (_currentQuestionIndex / _currentQuestions.length).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  minHeight: 4,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: _activeFormType == null
            ? _buildSelectionScreen()
            : _buildChatScreen(),
      ),
    );
  }

  // ─── 1. FORM SEÇİM EKRANI (İŞ, OKUL, GÜN) ───
  Widget _buildSelectionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hoşgeldin Başlığı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💬', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugün Günün Nasıl Geçti?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Aşağıdan değerlendirmek istediğin alanı seç, asistanınla birlikte sohbet ederek dolduralım.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3B82F6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Lütfen Bir Alan Seç:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // 1. BUTON: İŞYERİ
          _buildFormCard(
            title: 'İş',
            subtitle: 'İşyerinde Günüm Nasıl Geçti?',
            description: 'Mesai saatleri, iş görevleri, iş arkadaşları ve çalışma deneyimleri',
            icon: Icons.business_center_rounded,
            emoji: '🏢',
            colors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
            badgeText: '23 Soru • İşyeri Formu',
            onTap: () => _startForm(EvaluationFormType.isyeri),
          ),
          const SizedBox(height: 16),

          // 2. BUTON: OKUL
          _buildFormCard(
            title: 'Okul',
            subtitle: 'Okulda Günüm Nasıl Geçti?',
            description: 'Dersler, ödevler, okul arkadaşları ve öğretmenlerle iletişim',
            icon: Icons.school_rounded,
            emoji: '🎒',
            colors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
            badgeText: '20 Soru • Okul Formu',
            onTap: () => _startForm(EvaluationFormType.okul),
          ),
          const SizedBox(height: 16),

          // 3. BUTON: GÜN
          _buildFormCard(
            title: 'Gün',
            subtitle: 'Günüm Nasıl Geçti?',
            description: 'Sabah uyanışı, günlük hedefler, ev görevleri ve duygular',
            icon: Icons.wb_sunny_rounded,
            emoji: '☀️',
            colors: [const Color(0xFF059669), const Color(0xFF10B981)],
            badgeText: '19 Soru • Tüm Gün Formu',
            onTap: () => _startForm(EvaluationFormType.tumGun),
          ),
          const SizedBox(height: 28),

          // Geçmiş Değerlendirmeler Butonu
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
            ),
            icon: const Icon(Icons.history_edu_rounded, color: Color(0xFF475569)),
            label: const Text(
              'Önceki Değerlendirmelerimi İncele 📋',
              style: TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onPressed: _showHistorySheet,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String emoji,
    required List<Color> colors,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: colors.first.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst Renkli Şerit & Başlık
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),

              // Açıklama & Badge
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.first.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: colors.first,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Başlat',
                              style: TextStyle(
                                color: colors.first,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.play_circle_fill_rounded, color: colors.first, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 2. CHAT BOX EKRANI ───
  Widget _buildChatScreen() {
    final bool isCompleted = _currentQuestionIndex >= _currentQuestions.length;

    return Column(
      children: [
        // Soru Sayacı Başlığı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 16),
              const SizedBox(width: 8),
              Text(
                isCompleted
                    ? 'Değerlendirme Tamamlandı 🎉'
                    : 'Soru ${(_currentQuestionIndex + 1).clamp(1, _currentQuestions.length)} / ${_currentQuestions.length}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Text(
                _getFormName(_activeFormType),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Mesaj Listesi
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: _messages.length + (_isBotTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _messages.length) {
                return _buildMessageBubble(_messages[index]);
              } else {
                return _buildTypingIndicator();
              }
            },
          ),
        ),

        // Dinamik Giriş Kontrol Alanı
        if (!isCompleted)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: _buildInteractiveInputControl(),
          )
        else
          _buildCompletionBar(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isBot = msg.sender == 'bot';

    if (msg.isCelebration) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF59E0B)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🌟 🏆 🌟', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              msg.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Değerlendirmeyi İncele ve Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                _showSummaryDialog();
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
              child: const Text('🤖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : const Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isBot ? 4 : 18),
                  bottomRight: Radius.circular(isBot ? 18 : 4),
                ),
                border: isBot ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isBot ? const Color(0xFF1E293B) : Colors.white,
                            height: 1.35,
                            fontWeight: isBot ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isBot) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _tts.speak(msg.text),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            size: 18,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.person, color: Color(0xFF1D4ED8), size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
            child: const Text('🤖', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Yazıyor', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                SizedBox(width: 4),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DİNAMİK SORU GİRİŞ KONTROLLERİ
  // ─────────────────────────────────────────────────────────────

  Widget _buildInteractiveInputControl() {
    if (_currentQuestionIndex >= _currentQuestions.length) {
      return const SizedBox.shrink();
    }

    final q = _currentQuestions[_currentQuestionIndex];

    // Eğer Evet dendiği için açılan takip sorusundaysak, metin/ses girişi göster
    if (_isWaitingForFollowUp) {
      return _buildTextVoiceInput(
        hintText: 'Ayrıntıları yaz veya mikrofonla anlat...',
        quickChips: null,
      );
    }

    switch (q.inputType) {
      case QuestionInputType.date:
        return _buildDateInput();
      case QuestionInputType.yesNo:
        return _buildYesNoInput();
      case QuestionInputType.multiChoice:
        return _buildMultiChoiceInput(q.options ?? []);
      case QuestionInputType.singleChoice:
        return _buildSingleChoiceInput(q.options ?? []);
      case QuestionInputType.time:
        return _buildTimeInput(q.quickSuggestions);
      case QuestionInputType.textVoice:
        return _buildTextVoiceInput(
          hintText: q.hint ?? 'Cevabını yaz veya sesle söyle...',
          quickChips: q.quickSuggestions,
        );
    }
  }

  // 1. TARİH SEÇİCİ
  Widget _buildDateInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                ),
                icon: const Icon(Icons.edit_calendar_rounded),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Bu Tarihle Devam Et',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                _submitAnswer(_formatDate(_selectedDate));
              },
            ),
          ),
        ],
      ),
    );
  }

  // 2. EVET / HAYIR SEÇİMİ
  Widget _buildYesNoInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 24),
              label: const Text(
                'Evet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _submitAnswer('Evet'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
              icon: const Icon(Icons.cancel_rounded, size: 24),
              label: const Text(
                'Hayır',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _submitAnswer('Hayır'),
            ),
          ),
        ],
      ),
    );
  }

  // 3. ÇOKLU SEÇİM (KOLAYDI, ZORDU, EĞLENCELİYDİ, VB.)
  Widget _buildMultiChoiceInput(List<String> options) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = _selectedMultiOptions.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: isSelected,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                selectedColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFFF1F5F9),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedMultiOptions.add(opt);
                      if (opt == 'Diğer') _isOtherSelected = true;
                    } else {
                      _selectedMultiOptions.remove(opt);
                      if (opt == 'Diğer') _isOtherSelected = false;
                    }
                  });
                },
              );
            }).toList(),
          ),

          // "Diğer" seçildiyse açıklama kutusu
          if (_isOtherSelected) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otherTextController,
              decoration: InputDecoration(
                hintText: 'Diğer seçeneğini açıkla...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],

          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _selectedMultiOptions.isEmpty
                ? null
                : () {
                    final selectedList = _selectedMultiOptions.toList();
                    if (_isOtherSelected && _otherTextController.text.trim().isNotEmpty) {
                      selectedList.remove('Diğer');
                      selectedList.add('Diğer (${_otherTextController.text.trim()})');
                    }
                    _submitAnswer(selectedList.join(', '));
                  },
            child: const Text('Seçimleri Gönder ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // 4. TEKİL SEÇİM LİSTESİ (ZORLUK ÇÖZÜM YÖNTEMLERİ)
  Widget _buildSingleChoiceInput(List<String> options) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(14),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final opt = options[index];
          return InkWell(
            onTap: () => _submitAnswer(opt),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. SAAT GİRİŞİ (UYANMA / İŞE GELİŞ)
  Widget _buildTimeInput(List<String>? quickTimes) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quickTimes != null && quickTimes.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: quickTimes.map((timeStr) {
                return ActionChip(
                  label: Text(timeStr),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onPressed: () => _submitAnswer(timeStr),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Örn: 08:30...',
                    prefixIcon: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    _submitAnswer(text);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. METİN VE SESLİ YAZDIRMA (SESLİ GİRİŞ / SPEECH-TO-TEXT)
  Widget _buildTextVoiceInput({
    required String hintText,
    List<String>? quickChips,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hızlı Öneri Çipleri (Dersler, iş görevleri vb.)
          if (quickChips != null && quickChips.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickChips.map((chipText) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 8),
                    child: ActionChip(
                      label: Text(chipText),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        final current = _textController.text.trim();
                        if (current.isEmpty) {
                          _textController.text = chipText;
                        } else {
                          _textController.text = '$current, $chipText';
                        }
                        setState(() {});
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          Row(
            children: [
              // Mikrofon Butonu (Sesli Yazdırma)
              AnimatedBuilder(
                animation: _micPulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3 * _micPulseController.value),
                                blurRadius: 10 * _micPulseController.value,
                                spreadRadius: 4 * _micPulseController.value,
                              ),
                            ]
                          : [],
                    ),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _isListening ? const Color(0xFFEF4444) : const Color(0xFFEFF6FF),
                        foregroundColor:
                            _isListening ? Colors.white : const Color(0xFF2563EB),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
                      tooltip: _isListening ? 'Dinleniyor (Dokunup Durdur)' : 'Sesli Yazdır',
                      onPressed: _toggleListening,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Metin Giriş Alanı
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Seni dinliyorum, konuş...' : hintText,
                    hintStyle: TextStyle(
                      color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: _isListening ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isListening ? const Color(0xFFF87171) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (val) {
                    final text = val.trim();
                    if (text.isNotEmpty) _submitAnswer(text);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Gönder Butonu
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    if (_isListening) _toggleListening();
                    _submitAnswer(text);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. TAMAMLANMA ALTI BARI
  Widget _buildCompletionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Başa Dön'),
              onPressed: () => setState(() => _activeFormType = null),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Özeti Gör 📋', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _showSummaryDialog,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL VE DİYALOGLAR (ÖZET, GEÇMİŞ, ONAYLAR)
  // ─────────────────────────────────────────────────────────────

  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 26),
            const SizedBox(width: 8),
            Text(
              '${_getFormName(_activeFormType)} Değerlendirme Özeti',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _answers.isEmpty
              ? const Text('Henüz kaydedilmiş bir yanıt bulunmuyor.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _answers.entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final entry = _answers.entries.elementAt(i);
                    final matchedQ = _currentQuestions.cast<EvalQuestion?>().firstWhere(
                          (q) => q?.id == entry.key,
                          orElse: () => null,
                        );
                    final title = matchedQ?.text ?? entry.key;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _activeFormType = null);
            },
            child: const Text('Tamamla ve Ana Ekrana Dön'),
          ),
        ],
      ),
    );
  }

  void _showHistorySheet() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('self_evaluations_history') ?? [];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    const Text(
                      'Geçmiş Değerlendirmelerim',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: rawList.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz tamamlanmış bir değerlendirme yok.\nBir form seçip başlayabilirsin! 🌟',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: rawList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          try {
                            final item = jsonDecode(rawList[i]) as Map<String, dynamic>;
                            final title = item['formTitle'] ?? 'Değerlendirme';
                            final dateStr = item['date'] ?? '';
                            final answers = item['answers'] as Map<String, dynamic>? ?? {};

                            DateTime? dt;
                            try {
                              dt = DateTime.parse(dateStr);
                            } catch (_) {}

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      Text(
                                        dt != null ? _formatDate(dt) : '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${answers.length} soru yanıtlandı.',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            );
                          } catch (_) {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Formdan Çıkılsın mı?'),
        content: const Text(
          'Mevcut değerlendirme sohbetinden çıkıp alan seçimine dönmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Devam Et'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _activeFormType = null);
            },
            child: const Text('Evet, Çık'),
          ),
        ],
      ),
    );
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Yeniden Başlat'),
        content: const Text('Bu formun sorularını baştan yanıtlamak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (_activeFormType != null) {
                _startForm(_activeFormType!);
              }
            },
            child: const Text('Baştan Başla'),
          ),
        ],
      ),
    );
  }
}
