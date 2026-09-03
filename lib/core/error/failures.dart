/// Base class for all failures that can be thrown/returned from the
/// domain & data layers. Keeping this in `core` allows both layers to
/// depend on it without violating Clean Architecture boundaries.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Thrown when user-provided input does not pass business validation
/// rules (e.g. weight <= 0, empty address, no waste type selected).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Thrown when the data source (mock/local or, later, remote API)
/// fails to fulfil a request.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Thrown when a locally cached/in-memory resource cannot be found.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Thrown when authentication (login/register) fails.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
