// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:path/path.dart' as path;
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

const String _defaultFileName = 'shared_preferences';

const String _defaultPrefix = 'flutter.';

/// The Windows implementation of [SharedPreferencesStorePlatform].
///
/// This class implements the `package:shared_preferences` functionality for Windows.
class SharedPreferencesWindows extends SharedPreferencesStorePlatform {
  /// Deprecated instance of [SharedPreferencesWindows].
  /// Use [SharedPreferencesStorePlatform.instance] instead.
  @Deprecated('Use `SharedPreferencesStorePlatform.instance` instead.')
  static SharedPreferencesWindows instance = SharedPreferencesWindows();

  /// Registers the Windows implementation.
  static void registerWith() {
    SharedPreferencesStorePlatform.instance = SharedPreferencesWindows();
    // A temporary work-around for having two plugins contained in a single package.
    SharedPreferencesAsyncWindows.registerWith();
  }

  /// Local copy of preferences
  Map<String, Object>? _cachedPreferences;

  /// File system used to store to disk. Exposed for testing only.
  @visibleForTesting
  FileSystem fs = const LocalFileSystem();

  /// The path_provider_windows instance used to find the support directory.
  @visibleForTesting
  PathProviderWindows pathProvider = PathProviderWindows();

  /// Checks for cached preferences and returns them or loads preferences from
  /// file and returns and caches them.
  Future<Map<String, Object>> _readPreferences() async {
    _cachedPreferences ??= await _readFromFile(
      _defaultFileName,
      fs: fs,
      pathProvider: pathProvider,
    );
    return _cachedPreferences!;
  }

  @override
  Future<bool> clear() async {
    return clearWithParameters(ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)));
  }

  @override
  Future<bool> clearWithPrefix(String prefix) async {
    return clearWithParameters(ClearParameters(filter: PreferencesFilter(prefix: prefix)));
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    final PreferencesFilter filter = parameters.filter;

    final Map<String, Object> preferences = await _readPreferences();
    preferences.removeWhere(
      (String key, _) =>
          key.startsWith(filter.prefix) &&
          (filter.allowList == null || filter.allowList!.contains(key)),
    );
    return _writePreferences(preferences, _defaultFileName, fs: fs, pathProvider: pathProvider);
  }

  @override
  Future<Map<String, Object>> getAll() async {
    return getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
    );
  }

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) async {
    return getAllWithParameters(GetAllParameters(filter: PreferencesFilter(prefix: prefix)));
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) async {
    final PreferencesFilter filter = parameters.filter;
    final withPrefix = Map<String, Object>.from(await _readPreferences());
    withPrefix.removeWhere(
      (String key, _) =>
          !(key.startsWith(filter.prefix) && (filter.allowList?.contains(key) ?? true)),
    );
    return withPrefix;
  }

  @override
  Future<bool> remove(String key) async {
    final Map<String, Object> preferences = await _readPreferences();
    preferences.remove(key);
    return _writePreferences(preferences, _defaultFileName, fs: fs, pathProvider: pathProvider);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final Map<String, Object> preferences = await _readPreferences();
    preferences[key] = value;
    return _writePreferences(preferences, _defaultFileName, fs: fs, pathProvider: pathProvider);
  }
}

/// The Windows implementation of [SharedPreferencesAsyncPlatform].
///
/// This class implements the `package:shared_preferences` functionality for Windows.
base class SharedPreferencesAsyncWindows extends SharedPreferencesAsyncPlatform {
  /// Registers the Windows implementation.
  static void registerWith() {
    SharedPreferencesAsyncPlatform.instance = SharedPreferencesAsyncWindows();
  }

  /// Local copy of preferences
  Map<String, Object>? _cachedPreferences;

  /// File system used to store to disk. Exposed for testing only.
  @visibleForTesting
  FileSystem fs = const LocalFileSystem();

  /// The path_provider_windows instance used to find the support directory.
  @visibleForTesting
  PathProviderWindows pathProvider = PathProviderWindows();

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    return (await getPreferences(parameters, options)).keys.toSet();
  }

  @override
  Future<void> setString(String key, String value, SharedPreferencesOptions options) {
    return _setValue(key, value, options);
  }

  @override
  Future<void> setBool(String key, bool value, SharedPreferencesOptions options) {
    return _setValue(key, value, options);
  }

  @override
  Future<void> setDouble(String key, double value, SharedPreferencesOptions options) {
    return _setValue(key, value, options);
  }

  @override
  Future<void> setInt(String key, int value, SharedPreferencesOptions options) {
    return _setValue(key, value, options);
  }

  @override
  Future<void> setStringList(String key, List<String> value, SharedPreferencesOptions options) {
    return _setValue(key, value, options);
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    final Map<String, Object> data = await _readAll(<String>{key}, options);
    return data[key] as String?;
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async {
    final Map<String, Object> data = await _readAll(<String>{key}, options);
    return data[key] as bool?;
  }

  @override
  Future<double?> getDouble(String key, SharedPreferencesOptions options) async {
    final Map<String, Object> data = await _readAll(<String>{key}, options);
    return data[key] as double?;
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async {
    final Map<String, Object> data = await _readAll(<String>{key}, options);
    return data[key] as int?;
  }

  @override
  Future<List<String>?> getStringList(String key, SharedPreferencesOptions options) async {
    final Map<String, Object> data = await _readAll(<String>{key}, options);
    return (data[key] as List<Object?>?)?.cast<String>().toList();
  }

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final SharedPreferencesWindowsOptions windowsOptions =
        SharedPreferencesWindowsOptions.fromSharedPreferencesOptions(options);
    final PreferencesFilters filter = parameters.filter;
    final Map<String, Object> preferences = await _readPreferences(windowsOptions.fileName);
    preferences.removeWhere(
      (String key, _) => filter.allowList == null || filter.allowList!.contains(key),
    );
    await _writePreferences(
      preferences,
      windowsOptions.fileName,
      fs: fs,
      pathProvider: pathProvider,
    );
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    return _readAll(parameters.filter.allowList, options);
  }

  /// Reloads preferences from file.
  @visibleForTesting
  Future<void> reload(SharedPreferencesWindowsOptions options) async {
    _cachedPreferences = await _readFromFile(options.fileName);
  }

  Future<Map<String, Object>> _readAll(
    Set<String>? allowList,
    SharedPreferencesOptions options,
  ) async {
    final SharedPreferencesWindowsOptions windowsOptions =
        SharedPreferencesWindowsOptions.fromSharedPreferencesOptions(options);
    final prefs = Map<String, Object>.from(await _readPreferences(windowsOptions.fileName));
    prefs.removeWhere((String key, _) => !(allowList?.contains(key) ?? true));
    return prefs;
  }

  Future<void> _setValue(String key, Object value, SharedPreferencesOptions options) async {
    final SharedPreferencesWindowsOptions windowsOptions =
        SharedPreferencesWindowsOptions.fromSharedPreferencesOptions(options);
    final Map<String, Object> preferences = await _readPreferences(windowsOptions.fileName);
    preferences[key] = value;
    await _writePreferences(
      preferences,
      windowsOptions.fileName,
      fs: fs,
      pathProvider: pathProvider,
    );
  }

  /// Checks for cached preferences and returns them or loads preferences from
  /// file and returns and caches them.
  Future<Map<String, Object>> _readPreferences(String fileName) async {
    _cachedPreferences ??= await _readFromFile(fileName, fs: fs, pathProvider: pathProvider);
    return _cachedPreferences!;
  }
}

/// Gets the file where the preferences are stored.
///
/// Telosnex fork: the file is in Local AppData (path_provider's cache path,
/// `%LOCALAPPDATA%\<company>\<product>`), not Roaming AppData (the support
/// path). Roaming profiles copy Roaming AppData to the user's other PCs and
/// Folder Redirection shares it between PCs signed in at once; preferences
/// often hold state that belongs to one PC. A file left in Roaming AppData by
/// the upstream plugin is moved here once per process.
Future<File?> _getLocalDataFile(
  String fileName, {
  FileSystem fs = const LocalFileSystem(),
  PathProviderWindows? pathProvider,
}) {
  final Map<String, Future<File?>> resolved =
      _resolvedFiles[fs] ??= <String, Future<File?>>{};
  return resolved[fileName] ??= _resolveLocalDataFile(
    fileName,
    fs: fs,
    pathProvider: pathProvider ?? PathProviderWindows(),
  );
}

/// Resolved files per file system, so the Roaming check runs once.
final Expando<Map<String, Future<File?>>> _resolvedFiles =
    Expando<Map<String, Future<File?>>>();

Future<File?> _resolveLocalDataFile(
  String fileName, {
  required FileSystem fs,
  required PathProviderWindows pathProvider,
}) async {
  final String? localDirectory = await pathProvider.getApplicationCachePath();
  if (localDirectory == null) {
    return null;
  }
  // No path.canonicalize: it lowercases, and a redirected Roaming AppData can
  // be on a case-sensitive share where the lowercased path does not exist.
  final File local = fs.file(path.join(localDirectory, '$fileName.json'));
  File? roaming;
  try {
    final String? roamingDirectory =
        await pathProvider.getApplicationSupportPath();
    if (roamingDirectory != null) {
      roaming = fs.file(path.join(roamingDirectory, '$fileName.json'));
      if (!path.equals(roaming.path, local.path)) {
        await moveRoamingFile(roaming, local);
      }
    }
  } catch (e) {
    debugPrint('Moving $fileName.json to Local AppData failed: $e');
    // Keep using the old file this run rather than starting empty.
    if (roaming != null && !local.existsSync() && roaming.existsSync()) {
      return roaming;
    }
  }
  return local;
}

/// Moves [roaming] to [local]. If [local] already exists it wins and
/// [roaming] is only deleted. Copies rather than renames, because a
/// redirected Roaming AppData is often on another volume.
@visibleForTesting
Future<void> moveRoamingFile(File roaming, File local) async {
  if (!roaming.existsSync()) {
    return;
  }
  if (!local.existsSync()) {
    local.parent.createSync(recursive: true);
    final File tmp = local.fileSystem.file('${local.path}.tmp');
    await roaming.copy(tmp.path);
    await tmp.rename(local.path);
  }
  await roaming.delete();
}

/// Gets the preferences from the stored file.
Future<Map<String, Object>> _readFromFile(
  String fileName, {
  FileSystem fs = const LocalFileSystem(),
  PathProviderWindows? pathProvider,
}) async {
  var preferences = <String, Object>{};
  final File? localDataFile = await _getLocalDataFile(fileName, fs: fs, pathProvider: pathProvider);
  if (localDataFile != null && localDataFile.existsSync()) {
    final String stringMap = localDataFile.readAsStringSync();
    if (stringMap.isNotEmpty) {
      final Object? data = json.decode(stringMap);
      if (data is Map) {
        preferences = data.cast<String, Object>();
      }
    }
  }
  return preferences;
}

/// Writes the cached preferences to disk. Returns [true] if the operation
/// succeeded.
Future<bool> _writePreferences(
  Map<String, Object> preferences,
  String fileName, {
  FileSystem fs = const LocalFileSystem(),
  PathProviderWindows? pathProvider,
}) async {
  try {
    final File? localDataFile = await _getLocalDataFile(
      fileName,
      fs: fs,
      pathProvider: pathProvider,
    );
    if (localDataFile == null) {
      debugPrint('Unable to determine where to write preferences.');
      return false;
    }
    if (!localDataFile.existsSync()) {
      localDataFile.createSync(recursive: true);
    }
    final String stringMap = json.encode(preferences);
    localDataFile.writeAsStringSync(stringMap);
  } catch (e) {
    debugPrint('Error saving preferences to disk: $e');
    return false;
  }
  return true;
}

/// Windows specific SharedPreferences Options.
class SharedPreferencesWindowsOptions extends SharedPreferencesOptions {
  /// Constructor for SharedPreferencesWindowsOptions.
  const SharedPreferencesWindowsOptions({
    this.fileName = 'shared_preferences', // Same as current defaults.
  });

  /// The name of the file to store preferences in.
  final String fileName;

  /// Returns a new instance of [SharedPreferencesWindowsOptions] from an existing
  /// [SharedPreferencesOptions].
  static SharedPreferencesWindowsOptions fromSharedPreferencesOptions(
    SharedPreferencesOptions options,
  ) {
    if (options is SharedPreferencesWindowsOptions) {
      return options;
    }
    return const SharedPreferencesWindowsOptions();
  }
}
