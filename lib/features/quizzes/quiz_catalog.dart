import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class QuizCatalogItem {
  const QuizCatalogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.questionCount,
    required this.durationLabel,
    required this.level,
    required this.progress,
    required this.icon,
    required this.iconColor,
    required this.progressColor,
  });

  factory QuizCatalogItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return QuizCatalogItem(
      id: doc.id,
      title: _string(data['title'], 'Untitled quiz'),
      subtitle: _string(data['subtitle'], ''),
      questionCount: _int(data['questionCount'], 20),
      durationLabel: _string(data['durationLabel'], '30 min'),
      level: _string(data['level'], 'មធ្យម'),
      progress: _progress(data['progress']),
      icon: _icon(data['icon']),
      iconColor: _color(data['iconColor'], const Color(0xFFFFD267)),
      progressColor: _color(data['progressColor'], AppColors.cyan),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final int questionCount;
  final String durationLabel;
  final String level;
  final double progress;
  final IconData icon;
  final Color iconColor;
  final Color progressColor;

  int get progressPercent => (progress * 100).round();

  static String _string(Object? value, String fallback) {
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }

  static int _int(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  static double _progress(Object? value) {
    final numeric = value is num ? value.toDouble() : 0;
    final normalized = numeric > 1 ? numeric / 100 : numeric;
    return normalized.clamp(0, 1).toDouble();
  }

  static Color _color(Object? value, Color fallback) {
    if (value is int) return Color(value);
    if (value is String) {
      final cleaned = value.replaceAll('#', '').replaceAll('0x', '');
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        return Color(cleaned.length <= 6 ? 0xFF000000 | parsed : parsed);
      }
    }
    return fallback;
  }

  static IconData _icon(Object? value) {
    return switch (value) {
      'calculate' => Icons.calculate_rounded,
      'monthly' => Icons.hub_rounded,
      'book' => Icons.menu_book_rounded,
      'practice' => Icons.quiz_outlined,
      _ => Icons.edit_note_rounded,
    };
  }
}

class QuizCatalogRepository {
  const QuizCatalogRepository();

  Stream<List<QuizCatalogItem>> watchQuizzes() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(demoQuizCatalog);
    }

    return FirebaseFirestore.instance
        .collection('quizzes')
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map(QuizCatalogItem.fromFirestore).toList();
      return items.isEmpty ? demoQuizCatalog : items;
    });
  }
}

const demoQuizCatalog = [
  QuizCatalogItem(
    id: 'bac-dup',
    title: 'បាក់ឌុប',
    subtitle: 'វិញ្ញាសារត្រៀមពីឆ្នាំ\n២០១៤-២០២៦',
    questionCount: 20,
    durationLabel: '30 min',
    level: 'មធ្យម',
    progress: 1,
    icon: Icons.edit_note_rounded,
    iconColor: Color(0xFFFFD267),
    progressColor: AppColors.cyan,
  ),
  QuizCatalogItem(
    id: 'semester',
    title: 'ប្រចាំឆមាស',
    subtitle: 'វុិចទ័រ,\nម៉ាទ្រីស, និង\nអាំងតេក្រាល',
    questionCount: 16,
    durationLabel: '25 min',
    level: 'មធ្យម',
    progress: .82,
    icon: Icons.calculate_rounded,
    iconColor: Color(0xFFFFBC55),
    progressColor: Color(0xFFB9B4FF),
  ),
  QuizCatalogItem(
    id: 'monthly',
    title: 'ប្រចាំខែ',
    subtitle: 'ប្រូបាប,\nបំណែងចែកប្រេកង់,\nការសន្និដ្ឋាន',
    questionCount: 12,
    durationLabel: '18 min',
    level: 'ងាយ',
    progress: .45,
    icon: Icons.hub_rounded,
    iconColor: Color(0xFF3EF2A1),
    progressColor: Color(0xFFC9A8FF),
  ),
  QuizCatalogItem(
    id: 'lessons',
    title: 'វិញ្ញាសារតាមមេរៀន',
    subtitle: 'មេរៀនថ្នាក់ទី១២\nតាមទីសៀវភៅពុម្ព',
    questionCount: 24,
    durationLabel: '35 min',
    level: 'លំបាក',
    progress: .45,
    icon: Icons.menu_book_rounded,
    iconColor: Color(0xFFFF4D8D),
    progressColor: Color(0xFFC9A8FF),
  ),
];
