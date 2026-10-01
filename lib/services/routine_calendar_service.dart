import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_activity.dart';

class RoutineCalendarService {
  static const String _storagePrefix = 'weekly_routine_cal_v2_';

  static const List<String> dayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static const List<String> monthNamesTr = [
    '',
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
    'Aralık',
  ];

  static const List<String> slotKeys = [
    'before_lunch', // 0: Öğle yemeğinden önce
    'lunch_meal',   // 1: Öğle yemeği (kilitli)
    'after_lunch',  // 2: Öğle yemeğinden sonra
    'dinner_meal',  // 3: Akşam yemeği (kilitli)
    'after_dinner', // 4: Akşam yemeğinden sonra
  ];

  static const List<String> slotTitles = [
    'Öğle yemeğinden önce',
    'Öğle yemeği 🍲',
    'Öğle yemeğinden sonra',
    'Akşam yemeği 🥗',
    'Akşam yemeğinden sonra',
  ];

  static bool isMealSlot(int slotIndex) => slotIndex == 1 || slotIndex == 3;

  /// Belirli bir haftanın başlangıç tarihini (Pazartesi) döndürür
  static DateTime getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Gün ve tarih formatı: "Perşembe: 24 Eylül" (Gün önce yazılır)
  static String formatDayHeader(DateTime monday, int dayIndex) {
    final dayDate = monday.add(Duration(days: dayIndex));
    final dayName = dayNames[dayIndex];
    final monthName = monthNamesTr[dayDate.month];
    return '$dayName: ${dayDate.day} $monthName';
  }

  /// Haftalık takvim verilerini yükler
  /// Dönen yapı: dayIndex (0..6) -> slotIndex (0..4) -> List<CalendarActivity> (en fazla 3)
  static Future<Map<int, Map<int, List<CalendarActivity>>>> loadWeekSchedule(DateTime monday) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = '$_storagePrefix${monday.year}_${monday.month}_${monday.day}';
    final savedJson = prefs.getString(weekKey);

    final Map<int, Map<int, List<CalendarActivity>>> result = {};
    for (int d = 0; d < 7; d++) {
      result[d] = {
        0: [],
        1: [
          const CalendarActivity(
            id: 'ogle_yemegi',
            title: 'Öğle Yemeği Zamanı 🍲',
            group: 'EV',
            groupName: 'Yemek',
            emoji: '🍲',
            icon: Icons.restaurant_rounded,
            color: Color(0xFFF97316),
          ),
        ],
        2: [],
        3: [
          const CalendarActivity(
            id: 'aksam_yemegi',
            title: 'Akşam Yemeği Zamanı 🥗',
            group: 'EV',
            groupName: 'Yemek',
            emoji: '🥗',
            icon: Icons.dinner_dining_rounded,
            color: Color(0xFF10B981),
          ),
        ],
        4: [],
      };
    }

    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        for (int d = 0; d < 7; d++) {
          final dayMap = decoded[d.toString()];
          if (dayMap is Map) {
            for (int s in [0, 2, 4]) {
              final slotList = dayMap[s.toString()];
              if (slotList is List) {
                result[d]![s] = slotList
                    .take(3)
                    .map((item) => CalendarActivity.fromJson(Map<String, dynamic>.from(item as Map)))
                    .toList();
              }
            }
          }
        }
      } catch (_) {}
    }

    return result;
  }

  /// Haftalık takvim verilerini kaydeder
  static Future<void> saveWeekSchedule(DateTime monday, Map<int, Map<int, List<CalendarActivity>>> schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = '$_storagePrefix${monday.year}_${monday.month}_${monday.day}';

    final Map<String, dynamic> toSave = {};
    for (int d = 0; d < 7; d++) {
      final slotMap = schedule[d] ?? {};
      toSave[d.toString()] = {
        '0': (slotMap[0] ?? []).map((a) => a.toJson()).toList(),
        '2': (slotMap[2] ?? []).map((a) => a.toJson()).toList(),
        '4': (slotMap[4] ?? []).map((a) => a.toJson()).toList(),
      };
    }

    await prefs.setString(weekKey, jsonEncode(toSave));
  }

  /// Bu haftaki Serbest Zaman (SZ) etkinliklerini listeler
  static Future<List<Map<String, dynamic>>> getFreeTimeActivitiesForWeek(DateTime monday) async {
    final schedule = await loadWeekSchedule(monday);
    final List<Map<String, dynamic>> szList = [];

    for (int d = 0; d < 7; d++) {
      for (int s in [0, 2, 4]) {
        final tasks = schedule[d]?[s] ?? [];
        for (int order = 0; order < tasks.length; order++) {
          final task = tasks[order];
          if (task.isFreeTime) {
            szList.add({
              'dayIndex': d,
              'dayTitle': formatDayHeader(monday, d),
              'slotIndex': s,
              'slotTitle': slotTitles[s],
              'order': order + 1,
              'activity': task,
            });
          }
        }
      }
    }

    return szList;
  }
}
