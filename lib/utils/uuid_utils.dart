import 'package:uuid/uuid.dart';

class UuidUtils {
  static const _uuid = Uuid();

  /// Generate a random v4 UUID.
  static String v4() => _uuid.v4();
}
