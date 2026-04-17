import '../config/api_config.dart';
import '../models/quiz.dart';
import '../models/scheda.dart';
import 'api_client.dart';

class QuizSubmitResult {
  final int quizId;
  final int schedaId;
  final SchedaContenuto scheda;
  QuizSubmitResult({
    required this.quizId,
    required this.schedaId,
    required this.scheda,
  });
}

class QuizService {
  final ApiClient _api;
  QuizService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<QuizSubmitResult> submit(QuizInput input) async {
    final data = await _api.post('/quiz',
        body: input.toJson(), timeout: ApiConfig.aiTimeout);
    final m = Map<String, dynamic>.from(data as Map);
    return QuizSubmitResult(
      quizId: (m['quiz_id'] as num).toInt(),
      schedaId: (m['scheda_id'] as num).toInt(),
      scheda: SchedaContenuto.fromJson(
          Map<String, dynamic>.from(m['scheda'] as Map)),
    );
  }

  Future<List<Quiz>> list() async {
    final data = await _api.get('/quiz');
    final list = data as List;
    return list
        .map((e) => Quiz.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Quiz> get(int id) async {
    final data = await _api.get('/quiz/$id');
    return Quiz.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> delete(int id) => _api.delete('/quiz/$id');
}
