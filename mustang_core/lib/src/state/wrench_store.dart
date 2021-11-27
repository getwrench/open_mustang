import 'dart:collection';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:mustang_core/src/cache/wrench_cache.dart';

/// [WrenchStore] provides utility methods to save/lookup instances
/// of any type.
///
/// Only 1 instance of a type exists at any point of time.
class WrenchStore {
  // Flag to switch between List and HashMap
  static bool large = false;

  // List is used to store objects when large flag is disabled
  static final List<Object?> _store = [];

  // HashMap is used to store objects when large flag is enabled
  static final HashMap<String, Object?> _hashStore = HashMap();

  // Flat to persist the data
  static bool persistent = false;

  // Hive Box Name to store the model data
  static String hiveBox = '';

  /// Looks up instance of type [T], if exists. Returns null if instance of
  /// type [T] is not found.
  static T? get<T>() {
    T? t;
    if (large) {
      t = _hashStore[T.toString()] as T?;
    } else {
      t = _store.firstWhere(
        (element) => element is T,
        orElse: () => null,
      ) as T?;
    }
    return t;
  }

  /// Saves instance [t] after removing, if exists, an instance of [T]
  static void update<T>(T t) {
    if (large) {
      _hashStore.update(
        T.toString(),
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
    if (large) {
      _hashStore.remove(T.toString());
    } else {
      _store.removeWhere((element) => element is T);
    }
  }

  /// Delete all objects from the store
  static void nuke() async {
    if (large) {
      _hashStore.clear();
    } else {
      _store.clear();
    }
    if (persistent) {
      Box box = Hive.box(hiveBox);
      if (box.isOpen) {
        await box.deleteAll(box.keys);
      }
    }
  }

  static void config({
    bool isLarge = false,
    bool isPersistent = false,
    String persistentStoreName = '',
  }) async {
    if (isPersistent) {
      assert(
        persistentStoreName.isNotEmpty,
        'Missing persistent directory location',
      );
    }

    large = isLarge;
    persistent = isPersistent;
    hiveBox = persistentStoreName;
  }

  /// Writes serialized object to a file
  static Future<void> persistObject(String key, String value) async {
    if (persistent) {
      Box box = Hive.box(hiveBox);
      if (box.isOpen) {
        await box.put(key, value);
      }
    }
  }

  /// Creates directory [boxDir] in the file system to save serialized objects
  static Future<void> initPersistence([String? storeLocation]) async {
    if (persistent) {
      if (storeLocation != null && (Platform.isIOS || Platform.isAndroid)) {
        Hive.init(storeLocation);
      }
      await Hive.openBox(hiveBox);

      // Cache Initialization
      WrenchCache.configCache('${hiveBox}Cache');
      await WrenchCache.initCache(storeLocation);
    }
  }

  /// Deserializes the previously serialized string into an object
  /// and makes it available in the WrenchStore
  static Future<void> restoreState(
    void Function(
      void Function<T>(T t) update,
      String modelName,
      String jsonStr,
    )
        callback,
    List<String> serializerNames,
  ) async {
    if (persistent) {
      Box box = Hive.box(hiveBox);
      if (box.isOpen) {
        for (dynamic key in box.keys) {
          if (serializerNames.contains(key)) {
            callback(WrenchStore.update, key, box.get(key));
          }
        }
      }
    }
  }

  static Future<void> deletePersistedState(List<String> deleteModels) async {
    if (persistent) {
      Box box = Hive.box(hiveBox);
      if (box.isOpen) {
        await box.deleteAll(deleteModels);
      }
    }
  }
}
