/// Exceptions thrown from the `data` layer (datasources). The
/// repository implementation catches these and translates them into
/// [Failure]s for the domain layer to consume.
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}
