import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:mustang_core/src/cache/mustang_cache.dart';

/// [MustangStore] provides utility methods to save/lookup instances
/// of any type.
///
/// Only 1 instance of a type exists at any point of time.
class MustangStore {
  // HashMap is used to store objects when large flag is enabled
  static final HashMap<String, Object?> _hashStore = HashMap();

  // Flat to persist the data
  static bool persistent = false;

  // Hive Box Name to store the model data
  static String? hiveBox;

  /// Looks up instance of type [T], if exists. Returns null if instance of
  /// type [T] is not found.
  static T? get<T>() {
    return _hashStore[T.toString()] as T?;
  }

  /// Saves instance [t] after removing, if exists, an instance of [T]
  static void update<T>(T t) {
    assert(
      !(T.toString().endsWith('?')),
      'Mustang store accepts only non-nullable types',
    );
    _hashStore.update(
      T.toString(),
      (_) => t,
      ifAbsent: () => t,
    );
  }

  /// Saves instances [t] and [s] after removing, if exists,
  /// an instance of type [T] and an instance of type [S].
  static void update2<T, S>(T t, S s) {
    assert(
      !(T.toString().endsWith('?') || S.toString().endsWith('?')),
      'Mustang store accepts only non-nullable types',
    );
    update<T>(t);
    update<S>(s);
  }

  /// Saves instances [t], [s], [u] after removing, if exists,
  /// an instance of type [T], instance of type [S] and instance of type [U]
  static void update3<T, S, U>(T t, S s, U u) {
    assert(
      !(T.toString().endsWith('?') ||
          S.toString().endsWith('?') ||
          U.toString().endsWith('?')),
      'Mustang store accepts only non-nullable types',
    );
    update<T>(t);
    update<S>(s);
    update<U>(u);
  }

  /// Saves instances [t], [s], [u], [v] after removing, if exists,
  /// an instance of type [T], instance of type [S], instance of type [U]
  /// and instance of type [V]
  static void update4<T, S, U, V>(T t, S s, U u, V v) {
    assert(
      !(T.toString().endsWith('?') ||
              S.toString().endsWith('?') ||
              U.toString().endsWith('?')) ||
          V.toString().endsWith('?'),
      'Mustang store accepts only non-nullable types',
    );
    update<T>(t);
    update<S>(s);
    update<U>(u);
    update<V>(v);
  }

  /// Removes instance of type [T], if exists
  static void delete<T>() {
    _hashStore.remove(T.toString());
  }

  /// Delete all objects from the store
  static void nuke() async {
    _hashStore.clear();
    if (persistent && hiveBox != null) {
      Box box = Hive.box(hiveBox!);
      if (box.isOpen) {
        await box.deleteAll(box.keys);
      }
    }
  }

  static void config({
    bool isPersistent = false,
    String? storeName,
  }) async {
    persistent = isPersistent;
    hiveBox = storeName;
  }

  /// Writes serialized object to a file
  static Future<void> persistObject(String key, String value) async {
    if (persistent && hiveBox != null) {
      Box box = Hive.box(hiveBox!);
      if (box.isOpen) {
        await box.put(key, value);
      }
    }
  }

  /// Creates directory [boxDir] in the file system to save serialized objects
  /// [storeLocation] is optional for Web
  static Future<void> initPersistence(String? storeLocation) async {
    if (persistent && hiveBox != null) {
      if (storeLocation != null) {
        Hive.init(storeLocation);
      }
      await Hive.openBox(hiveBox!);

      // Cache Initialization
      MustangCache.configCache('${hiveBox}Cache');
      await MustangCache.initCache(storeLocation);
    }
  }

  /// Deserializes the previously serialized string into an object
  /// and makes it available in the MustangStore
  static Future<void> restoreState(
    void Function(
      void Function<T>(T t) update,
      String modelName,
      String jsonStr,
    )
        callback,
    List<String> serializerNames,
  ) async {
    if (persistent && hiveBox != null) {
      Box box = Hive.box(hiveBox!);
      if (box.isOpen) {
        for (dynamic key in box.keys) {
          if (serializerNames.contains(key)) {
            callback(MustangStore.update, key, box.get(key));
          }
        }
      }
    }
  }

  static Future<void> deletePersistedState(List<String> deleteModels) async {
    if (persistent && hiveBox != null) {
      Box box = Hive.box(hiveBox!);
      if (box.isOpen) {
        await box.deleteAll(deleteModels);
      }
    }
  }
}
