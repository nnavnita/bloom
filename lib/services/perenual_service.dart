import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloom/data/plant_database.dart';

class PerenualPlant {
  final int id;
  final String commonName;
  final List<String> scientificName;
  final String? cycle;
  final String? watering;
  final List<String> sunlight;
  final String? imageUrl;
  final String? defaultImage;

  const PerenualPlant({
    required this.id,
    required this.commonName,
    required this.scientificName,
    this.cycle,
    this.watering,
    required this.sunlight,
    this.imageUrl,
    this.defaultImage,
  });

  factory PerenualPlant.fromJson(Map<String, dynamic> j) {
    final img = j['default_image'] as Map<String, dynamic>?;
    return PerenualPlant(
      id: j['id'] as int,
      commonName: j['common_name'] as String? ?? 'Unknown',
      scientificName: j['scientific_name'] != null
          ? List<String>.from(j['scientific_name'] as List)
          : [],
      cycle: j['cycle'] as String?,
      watering: j['watering'] as String?,
      sunlight: j['sunlight'] != null ? List<String>.from(j['sunlight'] as List) : [],
      imageUrl: img?['medium_url'] as String? ?? img?['regular_url'] as String?,
      defaultImage: img?['thumbnail'] as String?,
    );
  }

  List<String> get careTips {
    final tips = <String>[];
    if (watering != null) tips.add('Watering: $watering');
    if (sunlight.isNotEmpty) tips.add('Sunlight: ${sunlight.join(", ")}');
    if (cycle != null) tips.add('Growth cycle: $cycle');
    return tips;
  }
}

class SearchResult {
  final List<PerenualPlant> apiResults;
  final List<LocalPlant> localResults;

  const SearchResult({required this.apiResults, required this.localResults});

  bool get isEmpty => apiResults.isEmpty && localResults.isEmpty;
  int get totalCount => apiResults.length + localResults.length;
}

class PerenualService {
  static const _base = 'https://perenual.com/api';
  final String? apiKey;

  const PerenualService({this.apiKey});

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  Future<SearchResult> search(String query) async {
    final localResults = _searchLocal(query);

    if (!hasApiKey || query.isEmpty) {
      return SearchResult(apiResults: [], localResults: localResults);
    }

    try {
      final uri = Uri.parse('$_base/species-list').replace(queryParameters: {
        'key': apiKey!,
        'q': query,
        'page': '1',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List? ?? [];
        final apiResults = items
            .map((e) => PerenualPlant.fromJson(e as Map<String, dynamic>))
            .toList();
        return SearchResult(apiResults: apiResults, localResults: localResults);
      }
    } catch (_) {}

    return SearchResult(apiResults: [], localResults: localResults);
  }

  Future<List<PerenualPlant>> getFeatured() async {
    if (!hasApiKey) return [];

    try {
      final uri = Uri.parse('$_base/species-list').replace(queryParameters: {
        'key': apiKey!,
        'page': '1',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List? ?? [];
        return items
            .map((e) => PerenualPlant.fromJson(e as Map<String, dynamic>))
            .take(20)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  List<LocalPlant> _searchLocal(String query) {
    if (query.isEmpty) return kPlantDatabase;
    final q = query.toLowerCase();
    return kPlantDatabase
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.species.toLowerCase().contains(q))
        .toList();
  }
}
