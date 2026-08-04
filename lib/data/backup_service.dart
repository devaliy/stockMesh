import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

import '../core/result.dart';
import '../domain/inventory_service.dart';
import 'db/daos/app_state_dao.dart';
import 'db/database.dart';

/// Encrypted backup/restore (design.md §7).
///
/// File layout: `SMBK1` magic · 16-byte PBKDF2 salt · 12-byte AES-GCM nonce
/// · 16-byte MAC · ciphertext. The plaintext is a zip holding one JSON dump
/// of every table. The key derives from the Admin PIN via PBKDF2-HMAC-SHA256
/// (200k rounds) — losing the PIN means losing the backup, which is the
/// accepted trade for a fully offline product.
class BackupService {
  BackupService(this._db);

  static const _magic = [0x53, 0x4D, 0x42, 0x4B, 0x31]; // "SMBK1"
  static const _iterations = 200000;

  final AppDatabase _db;

  Future<SecretKey> _deriveKey(String adminPin, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: adminPin, nonce: salt);
  }

  Future<Uint8List> createBackup(String adminPin) async {
    final dump = await _dumpTables();
    final json = utf8.encode(jsonEncode(dump));

    final archive = Archive()
      ..addFile(ArchiveFile('stockmesh.json', json.length, json));
    final zipped = ZipEncoder().encode(archive);

    final algorithm = AesGcm.with256bits();
    final salt = algorithm.newNonce() + algorithm.newNonce(); // 24 → trim 16
    final saltBytes = salt.sublist(0, 16);
    final key = await _deriveKey(adminPin, saltBytes);
    final box = await algorithm.encrypt(zipped, secretKey: key);

    final out = BytesBuilder()
      ..add(_magic)
      ..add(saltBytes)
      ..add(box.nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    await _db.appStateDao.setInt(
        StateKeys.lastBackupAt, DateTime.now().millisecondsSinceEpoch);
    return out.toBytes();
  }

  Future<Result<String>> restoreBackup(
      Uint8List bytes, String adminPin) async {
    if (bytes.length < 5 + 16 + 12 + 16 + 1) {
      return const Err('That file is not a StockMesh backup.');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        return const Err('That file is not a StockMesh backup.');
      }
    }
    final salt = bytes.sublist(5, 21);
    final nonce = bytes.sublist(21, 33);
    final mac = bytes.sublist(33, 49);
    final cipherText = bytes.sublist(49);

    final algorithm = AesGcm.with256bits();
    final key = await _deriveKey(adminPin, salt);
    final List<int> zipped;
    try {
      zipped = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      return const Err('Wrong PIN for this backup.');
    }

    final Map<String, dynamic> dump;
    try {
      final archive = ZipDecoder().decodeBytes(zipped);
      final file = archive.findFile('stockmesh.json');
      if (file == null) return const Err('Backup is damaged.');
      dump = jsonDecode(utf8.decode(file.content as List<int>))
          as Map<String, dynamic>;
    } catch (_) {
      return const Err('Backup is damaged.');
    }

    await _loadTables(dump);
    // Rebuild the projection from the restored log (§7) — the projection in
    // the file is ignored on purpose: events are the only truth.
    await InventoryService(_db).rebuildProjection();
    final business =
        (dump['app_state'] as Map<String, dynamic>?)?['business_name'];
    return Ok(business is String ? business : '');
  }

  Future<Map<String, dynamic>> _dumpTables() async {
    final products = await _db.productsDao.getAll();
    final events = await _db.eventsDao.allEvents();
    final devices = await _db.devicesDao.getAll();
    final staff = await _db.staffDao.getAll();
    final state = await _db.appStateDao.getAll();

    return {
      'version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'products': [for (final p in products) p.toJson()],
      'stock_events': [for (final e in events) e.toJson()],
      'devices': [for (final d in devices) d.toJson()],
      'staff': [for (final s in staff) s.toJson()],
      'app_state': state,
    };
  }

  Future<void> _loadTables(Map<String, dynamic> dump) async {
    List<Map<String, dynamic>> rows(String key) =>
        [for (final r in (dump[key] as List? ?? const [])) (r as Map).cast<String, dynamic>()];

    await _db.transaction(() async {
      await _db.delete(_db.stockEvents).go();
      await _db.delete(_db.stockLevels).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.staff).go();
      await _db.delete(_db.devices).go();
      await _db.delete(_db.appState).go();

      for (final row in rows('products')) {
        await _db
            .into(_db.products)
            .insert(Product.fromJson(row).toCompanion(false));
      }
      for (final row in rows('stock_events')) {
        await _db
            .into(_db.stockEvents)
            .insert(StockEvent.fromJson(row).toCompanion(false));
      }
      for (final row in rows('staff')) {
        await _db
            .into(_db.staff)
            .insert(StaffData.fromJson(row).toCompanion(false));
      }
      // Old client pairings are invalid after restore (§7): only the HUB
      // row survives with a secret; every other device must re-pair.
      for (final row in rows('devices')) {
        final device = Device.fromJson(row);
        await _db.into(_db.devices).insert(
              (device.role == 'HUB'
                      ? device
                      : device.copyWith(isRevoked: true))
                  .toCompanion(false),
            );
      }
      final state = (dump['app_state'] as Map?)?.cast<String, String>() ??
          const <String, String>{};
      for (final entry in state.entries) {
        await _db.appStateDao.set(entry.key, entry.value);
      }
      // Restore always lands on the Hub role (§7).
      await _db.appStateDao.set(StateKeys.role, 'HUB');
    });
  }
}
