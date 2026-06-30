import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taif_alamin/data/database/database_service.dart';
import 'package:taif_alamin/presentation/cubits/backup_cubit/backup_state.dart';

class BackupCubit extends Cubit<BackupState> {
  BackupCubit() : super(const BackupState());

  static const _dbTypeGroup = XTypeGroup(
    label: 'قاعدة بيانات',
    extensions: ['db'],
  );

  /// Copy the live database file to a location the user picks.
  ///
  /// The connection is closed first so any pending writes are flushed to the
  /// main file (important under WAL), then re-opened — transparent to the rest
  /// of the app since every repository goes through [DatabaseService]'s static
  /// methods rather than holding a [Database] reference.
  Future<void> backup() async {
    final now = DateTime.now();
    final stamp =
        '${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}-${_two(now.minute)}';

    final location = await getSaveLocation(
      suggestedName: 'taif_alamin_backup_$stamp.db',
      acceptedTypeGroups: const [_dbTypeGroup],
    );
    if (location == null) return; // user cancelled — keep state untouched

    emit(
      state.copyWith(
        status: BackupStatus.working,
        operation: BackupOperation.backup,
      ),
    );

    try {
      final dbPath = await DatabaseService.databasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        _fail('لم يتم العثور على قاعدة البيانات الحالية.');
        return;
      }

      var destPath = location.path;
      if (!destPath.toLowerCase().endsWith('.db')) destPath = '$destPath.db';

      await DatabaseService.close();
      try {
        await dbFile.copy(destPath);
      } finally {
        await DatabaseService.reopen();
      }

      emit(
        state.copyWith(
          status: BackupStatus.success,
          operation: BackupOperation.backup,
          path: destPath,
          message: 'تم إنشاء النسخة الاحتياطية بنجاح.',
        ),
      );
    } catch (e) {
      _fail('فشل إنشاء النسخة الاحتياطية: $e');
    }
  }

  /// Replace the live database with a backup file the user picks.
  ///
  /// The current database is **not deleted** — it is renamed to
  /// `taif_alamin.db.pak` (any previous `.pak` is overwritten). On Windows the
  /// open connection holds a lock on the file, so it must be closed before the
  /// rename/replace, then re-opened on the new file afterwards.
  Future<void> restore() async {
    final source = await openFile(acceptedTypeGroups: const [_dbTypeGroup]);
    if (source == null) return; // user cancelled

    emit(
      state.copyWith(
        status: BackupStatus.working,
        operation: BackupOperation.restore,
      ),
    );

    try {
      final dbPath = await DatabaseService.databasePath();

      // Release the Windows file lock before touching the file on disk.
      await DatabaseService.close();

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final pakPath = '$dbPath.pak'; // taif_alamin.db -> taif_alamin.db.pak
        final pakFile = File(pakPath);
        if (await pakFile.exists()) {
          // rename() can't overwrite an existing target on Windows.
          await pakFile.delete();
        }
        await dbFile.rename(pakPath);
      }

      await File(source.path).copy(dbPath);

      // Bring the newly restored database online.
      await DatabaseService.reopen();

      emit(
        state.copyWith(
          status: BackupStatus.success,
          operation: BackupOperation.restore,
          path: source.path,
          message:
              'تمت الاستعادة بنجاح. النسخة القديمة محفوظة باسم taif_alamin.db.pak',
        ),
      );
    } catch (e) {
      // Try to leave the app with a working connection no matter what.
      try {
        await DatabaseService.reopen();
      } catch (_) {}
      _fail('فشلت الاستعادة: $e');
    }
  }

  void _fail(String message) {
    emit(
      state.copyWith(
        status: BackupStatus.error,
        error: message,
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}