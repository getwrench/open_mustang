import 'package:hive/hive.dart';
import 'package:mustang_core/src/state/wrench_store.dart';

/// [WrenchCache] provides utility methods to save/lookup instances
/// of any type.
///
/// Only one instance of cache store exists for an App.
class WrenchCache {
  /// Hive Box Name to cache the model data
  static String cacheName = '';

  static void configCache(String cacheName) async {
    WrenchCache.cacheName = cacheName;
  }

  /// Creates [storeLocation] in the file system to save serialized objects
  /// [storeLocation] is optional for Web
  static Future<void> initCache(String? storeLocation) async {
    if (storeLocation != null) {
      Hive.init(storeLocation);
    }
    await Hive.openLazyBox(cacheName);
  }

  /// Writes serialized object to a file
  static Future<void> addObject(
    String key,
    String modelKey,
    String modelValue,
  ) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    Map<String, String> value;

    if (lazyBox.isOpen) {
      value = (await lazyBox.get(key))?.cast<String, String>() ?? {};
      value.update(
        modelKey,
        (_) => modelValue,
        ifAbsent: () => modelValue,
      );
      await lazyBox.put(key, value);
    }
  }

  /// Deserializes the previously serialized string into an object and
  /// - updates WrenchStore
  /// - updates Persistence store
  static Future<void> restoreObjects(
    String key,
    void Function(
      void Function<T>(T t) update,
      String modelName,
      String jsonStr,
    )
        callback,
  ) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    if (lazyBox.isOpen) {
      Map<String, String> cacheData =
          (await lazyBox.get(key))?.cast<String, String>() ?? {};
      for (String modelKey in cacheData.keys) {
        WrenchStore.persistObject(modelKey, cacheData[modelKey]!);
        callback(WrenchStore.update, modelKey, cacheData[modelKey]!);
      }
    }
  }

  static Future<void> deleteObjects(String key) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    if (lazyBox.isOpen) {
      await lazyBox.delete(key);
    }
  }

  static bool itemExists(String key) {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    return ((lazyBox.isOpen) && lazyBox.containsKey(key));
  }
}
