import 'dart:collection';

/// [WrenchStore] provides utility methods to save/lookup instances
/// of any type.
///
/// Only 1 instance of a type exists at any point of time.
class WrenchStore {
  /// Looks up instance of type [T], if exists. Returns null if instance of
  /// type [T] is not found.
  static T get<T>() {
    T t;
    if (_largeStore) {
      int typeHash = _getTypeHash(T.toString());
      t = _hashStore[typeHash];
    } else {
      t = _store.firstWhere(
        (element) => element is T,
        orElse: () => null,
      );
    }
    return t;
  }

  /// Saves instance [t] after removing, if exists, an instance of [T]
  static void update<T>(T t) {
    if (_largeStore) {
      int typeHash = _getTypeHash(T.toString());
      _hashStore.update(
        typeHash,
        (_) => t,
        ifAbsent: () => t,
      );
    } else {
      int objectIndex = _store.indexWhere((element) => element is T);
      if (objectIndex != -1) {
        _store.insert(objectIndex, t);
      } else {
        _store.add(t);
      }
    }
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
    if (_largeStore) {
      int typeHash = _getTypeHash(T.toString());
      _hashStore.remove(typeHash);
    } else {
      _store.removeWhere((element) => element is T);
    }
  }

  // removes all objects from the store
  static void nuke() {
    if (_largeStore) {
      _hashStore.clear();
    } else {
      _store.clear();
    }
  }

  static void largeStore(bool status) {
    nuke();
    _largeStore = status;
  }

  static int _getTypeHash(String typeStr) {
    return _jf(_jc(0, typeStr.hashCode));
  }

  // Source: built_value library
  static int _jc(int hash, int value) {
    // Jenkins hash "combine".
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  // Source: built_value library
  static int _jf(int hash) {
    // Jenkins hash "finish".
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  // Flag to switch between List and HashMap
  static bool _largeStore = true;

  // List is used to store objects when _largeStore flag is disabled
  static final List<Object> _store = [];

  // HashMap is used to store objects when _largeStore flag is enabled
  static final HashMap<int, Object> _hashStore = HashMap();
}
