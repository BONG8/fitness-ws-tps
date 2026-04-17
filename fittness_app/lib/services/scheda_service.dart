import '../models/scheda.dart';
import 'api_client.dart';

class SchedaService {
  final ApiClient _api;
  SchedaService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<SchedaListItem>> list() async {
    final data = await _api.get('/schede');
    final list = data as List;
    return list
        .map((e) => SchedaListItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Scheda> get(int id) async {
    final data = await _api.get('/schede/$id');
    return Scheda.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> delete(int id) => _api.delete('/schede/$id');
}
