import 'package:flutter/widgets.dart';
import '../models/makaton_item.dart';

/// Saat + kullanım bazlı tahmin edici sıralama motoru.
class PredictiveEngine extends ChangeNotifier {
  List<MakatonItem> _items = [];
  List<MakatonItem> get items => _items;

  MakatonCategory? _activeCategory;
  MakatonCategory? get activeCategory => _activeCategory;

  void initialize() {
    _items = MakatonItem.all();
    sortItems();
  }

  void syncCustomItems(List<MakatonItem> customItems) {
    final base = MakatonItem.all();
    // avoid duplicates
    final customIds = customItems.map((e) => e.id).toSet();
    _items = [
      ...base.where((b) => !customIds.contains(b.id)),
      ...customItems,
    ];
    final slot = MakatonItem.getCurrentSlot();
    _items.sort((a, b) => _score(b, slot).compareTo(_score(a, slot)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setCategory(MakatonCategory? cat) {
    _activeCategory = cat;
    notifyListeners();
  }

  /// Filtrelenmiş öğeler (aktif kategoriye göre).
  List<MakatonItem> get filteredItems {
    if (_activeCategory == null) return _items;
    return _items.where((i) => i.category == _activeCategory).toList();
  }

  void sortItems() {
    final slot = MakatonItem.getCurrentSlot();
    _items.sort((a, b) => _score(b, slot).compareTo(_score(a, slot)));
    notifyListeners();
  }

  double _score(MakatonItem item, TimeSlot slot) {
    double s = 0;
    if (item.preferredSlots.contains(slot)) s += 3.0;
    s += (item.tapCount / 10).clamp(0.0, 3.0);
    return s;
  }

  void recordTap(String itemId) {
    final i = _items.indexWhere((e) => e.id == itemId);
    if (i != -1) {
      _items[i].tapCount++;
      sortItems();
    }
  }

  String get currentSlotLabel {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 11) return 'Sabah';
    if (h >= 11 && h < 15) return 'Öğle';
    if (h >= 15 && h < 18) return 'Öğleden Sonra';
    if (h >= 18 && h < 21) return 'Akşam';
    return 'Gece';
  }
}
