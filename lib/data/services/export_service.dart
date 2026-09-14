// Seleciona a implementação correta em tempo de compilação:
//   - web  → export_service_web.dart    (package:web + dart:js_interop)
//   - mobile/desktop → export_service_mobile.dart (não suportado, orienta versão web)
export 'export_service_mobile.dart'
    if (dart.library.js_interop) 'export_service_web.dart';
