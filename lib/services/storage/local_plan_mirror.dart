import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/itinerary.dart';

/// Ekvivalent LocalPlanMirror sa iOS-a — JSON fajlovi po planu na disku
/// (Application Documents Directory), za offline pristup kad Firestore
/// nije dostupan. Isti naming pattern kao iOS: "plan_<id>.json".
class LocalPlanMirror {
  LocalPlanMirror._();

  static const String _dirName = 'plans';
  static const String _prefix = 'plan_';
  static const String _suffix = '.json';

  static Future<Directory> _plansDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _fileFor(String planId) async {
    final dir = await _plansDir();
    return File('${dir.path}/$_prefix$planId$_suffix');
  }

  static Future<void> save(String planId, ItineraryResponse itinerary) async {
    final file = await _fileFor(planId);
    await file.writeAsString(jsonEncode(itinerary.toJson()));
  }

  static Future<void> delete(String planId) async {
    final file = await _fileFor(planId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Čita folder i parsira "plan_<id>.json" -> id, za sve fajlove koji
  /// prate naming pattern (ignoriše bilo šta drugo što bi se tu našlo).
  static Future<List<String>> allPlanIds() async {
    final dir = await _plansDir();
    final entries = await dir.list().toList();

    final ids = <String>[];
    for (final entry in entries) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      if (!name.startsWith(_prefix) || !name.endsWith(_suffix)) continue;
      final id = name.substring(_prefix.length, name.length - _suffix.length);
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  static Future<ItineraryResponse?> load(String planId) async {
    final file = await _fileFor(planId);
    if (!await file.exists()) return null;
    final source = await file.readAsString();
    return ItineraryResponse.fromJsonString(source);
  }
}
