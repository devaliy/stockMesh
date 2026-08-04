import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart';
import 'package:stockmesh/data/db/database.dart';

var _sqliteConfigured = false;

/// Points the sqlite3 loader at a project-local DLL on Windows hosts where
/// sqlite3 is not on PATH. No-op elsewhere.
void configureSqliteForTests() {
  if (_sqliteConfigured) return;
  _sqliteConfigured = true;
  if (!Platform.isWindows) return;
  final local = File('${Directory.current.path}/test/fixtures/sqlite3.dll');
  if (local.existsSync()) {
    open.overrideFor(
        OperatingSystem.windows, () => DynamicLibrary.open(local.path));
  }
}

/// Fresh in-memory database per test — the same schema the app ships.
/// Multi-node sync tests intentionally open several databases at once.
AppDatabase testDb() {
  configureSqliteForTests();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase.withExecutor(NativeDatabase.memory());
}
