import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'saved_solution.dart';

/// Stores solved boards on the device.
///
/// On device rather than on the gateway, for two reasons. Revision is the use
/// case, and it happens the night before an exam on a connection that may not
/// be there — a saved board has to open with no network at all. And keeping it
/// local means no new authenticated endpoint that could hand one student
/// another student's work.
///
/// The trade-off is real and worth stating: these are lost if the app is
/// reinstalled, and they do not follow a student to a second device. Moving
/// them to the gateway later only needs this class to gain a remote
/// implementation; nothing above it knows where they live.
class SavedSolutionsRepository {
  SavedSolutionsRepository({SharedPreferences? preferences})
    : _preferences = preferences;

  final SharedPreferences? _preferences;

  static const String storageKey = 'student.saved_solutions.v1';

  /// Bounded so a heavy user cannot fill their device storage. Oldest go first.
  static const int maxEntries = 40;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? await SharedPreferences.getInstance();

  /// Newest first. Unreadable storage reads as empty rather than throwing: a
  /// student opening their saved list should never meet a crash.
  Future<List<SavedSolution>> loadAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final items = decoded
        .map(SavedSolution.fromStoredJson)
        .whereType<SavedSolution>()
        .toList();
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  /// Saving the same solution again replaces it, so a student who taps save
  /// twice does not end up with the problem listed twice.
  Future<void> save(SavedSolution solution) async {
    final existing = await loadAll();
    final next = [
      solution,
      ...existing.where((item) => item.id != solution.id),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await _write(next.take(maxEntries).toList(growable: false));
  }

  Future<void> remove(String id) async {
    final remaining = (await loadAll())
        .where((item) => item.id != id)
        .toList(growable: false);
    await _write(remaining);
  }

  Future<bool> contains(String id) async =>
      (await loadAll()).any((item) => item.id == id);

  Future<void> _write(List<SavedSolution> items) async {
    final prefs = await _prefs;
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((item) => item.toStoredJson()).toList()),
    );
  }
}
