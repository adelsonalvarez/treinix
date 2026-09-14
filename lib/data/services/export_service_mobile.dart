import '../models/user_model.dart';

class ExportService {
  /// Exportação de dados disponível apenas na versão web (LGPD Art. 18, V).
  /// No mobile, orienta o usuário a acessar o app pelo navegador.
  static Future<void> exportUserData(UserModel user) async {
    throw UnsupportedError(
      'Exportação de dados disponível apenas na versão web. '
      'Acesse treinix pelo navegador para exportar seus dados.',
    );
  }
}
