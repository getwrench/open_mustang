import 'dart:collection';

/// [WrenchStore] provides utility methods to save/lookup instances
/// of any type.
///
/// Only 1 instance of a type exists at any point of time.
class WrenchStore {
  /// Looks up instance of type [T], if exists. Returns null if instance of
  /// type [T] is not found.
  static T get<T>() {
    return _store.firstWhere((element) => element is T, orElse: () => null);
  }

  /// Saves instance [t] after removing, if exists, an instance of [T]
  static void update<T>(T t) {
    _store.removeWhere((element) => element is T);
    _store.add(t);
  }

  /// Saves instances [t] and [s] after removing, if exists,
  /// an instance of type [T] and an instance of type [S].
  static void update2<T, S>(T t, S s) {
    update<T>(t);
    update<S>(s);
  }

  /// Saves instances [t], [s], [u] after removing, if exists,
  /// an instance of type [T], instance of type [S] and instance of type [U]
  static void update3<T, S, U>(T t, S s, U u) {
    update<T>(t);
    update<S>(s);
    update<U>(u);
  }

  /// Saves instances [t], [s], [u], [v] after removing, if exists,
  /// an instance of type [T], instance of type [S], instance of type [U]
  /// and instance of type [V]
  static void update4<T, S, U, V>(T t, S s, U u, V v) {
    update<T>(t);
    update<S>(s);
    update<U>(u);
    update<V>(v);
  }

  /// Removes instance of type [T], if exists
  static void delete<T>() {
    _store.removeWhere((element) => element is T);
  }

  // removes all objects from the store
  static void nuke() {
    _store.clear();
  }

  static final HashSet<Object> _store = HashSet();
}
