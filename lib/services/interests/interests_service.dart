import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../models/interest.dart';

/// Ekvivalent InterestsServiceType protokola.
abstract class InterestsServiceType {
  Future<List<Interest>> fetch({required String lang});
  Future<List<Interest>> fetchRandom({required String lang, required int limit});
}

/// Ekvivalent InterestsService.swift — minimalni Supabase REST klijent,
/// bez supabase_flutter paketa, isto kao iOS original (samo http paket).
///
/// [projectUrl] primjer: https://<PROJECT-REF>.supabase.co
class InterestsService implements InterestsServiceType {
  InterestsService({required Uri projectUrl, required String anonKey})
      : _projectUrl = projectUrl,
        _anonKey = anonKey;

  final Uri _projectUrl;
  final String _anonKey;
  final http.Client _client = http.Client();

  @override
  Future<List<Interest>> fetch({required String lang}) async {
    final uri = _projectUrl.replace(
      path: '${_projectUrl.path}/rest/v1/interests',
      queryParameters: {
        'select': 'id,key,icon,sort_order,is_active,name_translations',
        'order': 'sort_order.asc',
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Supabase interests fetch failed: HTTP ${response.statusCode}',
        uri,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    final items = decoded.map((e) => Interest.fromJson(e as Map<String, dynamic>)).toList();

    final active = items.where((i) => i.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return active;
  }

  /// Ekvivalent fetchRandom — client-side Fisher–Yates shuffle pa uzmi N.
  @override
  Future<List<Interest>> fetchRandom({required String lang, required int limit}) async {
    final all = List<Interest>.from(await fetch(lang: lang));
    final random = Random();

    for (var i = all.length - 1; i >= 1; i--) {
      final j = random.nextInt(i + 1);
      if (i != j) {
        final tmp = all[i];
        all[i] = all[j];
        all[j] = tmp;
      }
    }

    if (all.length > limit) {
      return all.sublist(0, limit);
    }
    return all;
  }

  void dispose() => _client.close();
}
