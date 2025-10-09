import '../model/candle_model.dart';

abstract class XauusdRepository {
  Future<List<CandleStick>> fetchAllM1();
}
