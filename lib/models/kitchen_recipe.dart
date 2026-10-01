import 'package:flutter/material.dart';

/// Kontrol edilebilir malzeme veya mutfak aleti öğesi (görsel destekli)
class RecipeCheckItem {
  final String id;
  final String name;
  final String? amount;
  final IconData icon;
  final String? imagePath; // Görsel anlatım desteği
  bool isChecked;

  RecipeCheckItem({
    required this.id,
    required this.name,
    this.amount,
    this.icon = Icons.check_box_outline_blank_rounded,
    this.imagePath,
    this.isChecked = false,
  });

  RecipeCheckItem copyWith({
    String? id,
    String? name,
    String? amount,
    IconData? icon,
    String? imagePath,
    bool? isChecked,
  }) {
    return RecipeCheckItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

/// Sıralı tarif adımı (fotoğraflı / görselli ve entegre kronometreli)
class RecipeStepItem {
  final int stepNumber;
  final String instruction;
  final String? tip;
  final IconData icon;
  final String? imagePath; // Adım fotoğrafı veya görseli
  final int? timerSeconds;
  final String? timerLabel;

  const RecipeStepItem({
    required this.stepNumber,
    required this.instruction,
    this.tip,
    this.icon = Icons.restaurant_rounded,
    this.imagePath,
    this.timerSeconds,
    this.timerLabel,
  });
}

/// Lezzet +1 Tarif Modeli (Görsel Anlatımlı)
class KitchenRecipe {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final String portions; // Örn: 4 Kişilik
  final String prepTime; // Örn: 25 Dakika
  final String cookTime; // Örn: 25 Dakika
  final String difficulty; // Örn: Kolay
  final IconData icon;
  final Color themeColor;
  final String? coverImagePath; // Tarifin ana bitmiş yemek fotoğrafı
  final List<RecipeCheckItem> ingredients; // Malzemeler (işaretlenebilir)
  final List<RecipeCheckItem> tools; // Araçlar & Materyaller (işaretlenebilir)
  final List<RecipeStepItem> steps; // Adım adım liste
  final List<String> chefTips; // Faydalı Püf Noktaları

  KitchenRecipe({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.portions,
    required this.prepTime,
    required this.cookTime,
    this.difficulty = 'Kolay',
    this.icon = Icons.soup_kitchen_rounded,
    this.themeColor = Colors.orange,
    this.coverImagePath,
    required this.ingredients,
    required this.tools,
    required this.steps,
    this.chefTips = const [],
  });

  /// Malzemelerdeki işaretli oranı
  double get ingredientsProgress {
    if (ingredients.isEmpty) return 1.0;
    final checked = ingredients.where((i) => i.isChecked).length;
    return checked / ingredients.length;
  }

  /// Araçlardaki işaretli oranı
  double get toolsProgress {
    if (tools.isEmpty) return 1.0;
    final checked = tools.where((t) => t.isChecked).length;
    return checked / tools.length;
  }

  /// Toplam hazırlık oranı
  double get totalChecklistProgress {
    final total = ingredients.length + tools.length;
    if (total == 0) return 1.0;
    final checked = ingredients.where((i) => i.isChecked).length +
        tools.where((t) => t.isChecked).length;
    return checked / total;
  }

  bool get isChecklistComplete =>
      ingredients.every((i) => i.isChecked) && tools.every((t) => t.isChecked);
}
