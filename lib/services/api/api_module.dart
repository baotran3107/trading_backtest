import 'package:injectable/injectable.dart';

import '../../constants/api_constants.dart';
import 'api_client.dart';
import 'dio_api_client.dart';

@module
class ApiModule {
  @lazySingleton
  ApiClient apiClient() => DioApiClient(
        baseUrl: ApiConstants.defaultBaseUrl,
      );
}
