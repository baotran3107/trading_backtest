import 'package:injectable/injectable.dart';

import '../../utils/config.dart';
import 'api_client.dart';
import 'dio_api_client.dart';

@module
abstract class ApiModule {
  @lazySingleton
  ApiClient apiClient() => DioApiClient(
        baseUrl: AppConfig.supabaseBaseUrl,
      );
}
