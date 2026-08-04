/// Minimal Result type for operations that fail for expected, user-facing
/// reasons (validation, auth) — exceptions stay reserved for bugs and I/O.
sealed class Result<T> {
  const Result();

  R when<R>({required R Function(T value) ok, required R Function(String message) err}) {
    final self = this;
    return switch (self) {
      Ok<T>(:final value) => ok(value),
      Err<T>(:final message) => err(message),
    };
  }

  bool get isOk => this is Ok<T>;

  T get requireValue => (this as Ok<T>).value;
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}
