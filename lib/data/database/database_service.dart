import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:taif_alamin/utils/path_utils.dart';

class DatabaseService {
  static const _dbName = 'taif_alamin.db';
  static const _dbVersion = 1;
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  /// Absolute path to the live SQLite file
  /// (`%APPDATA%/taif_alamin_renew/taif_alamin.db`). Single source of truth so
  /// backup/restore points at the exact same file the app opens.
  static Future<String> databasePath() async {
    final dbFolder = Directory(
      join(await PathUtils.getAppDataPath(), 'taif_alamin_renew'),
    );
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    return join(dbFolder.path, _dbName);
  }

  /// Re-open the connection after it was closed (e.g. after a restore).
  /// `_initDb` runs again lazily, so the additive schema fixes are re-applied
  /// to whatever database file is now in place.
  static Future<Database> reopen() async {
    await close();
    return db;
  }

  static Future<Database> _initDb() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;

    // Full custom database path
    final dbPath = await databasePath();

    final db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    await db.execute('PRAGMA foreign_keys = ON');
    await _ensureSchema(db);
    return db;
  }

  /// Additive, idempotent column/table fixes for databases that were created
  /// before a schema change shipped. Safe to run on every app start: each
  /// statement is wrapped so an "already exists" failure is ignored.
  static Future<void> _ensureSchema(Database db) async {
    Future<void> tryExec(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {
        // Column/table already exists — ignore.
      }
    }

    // Exchange rate for a USD exhibition bill (دولار -> دينار), entered per
    // bill at the moment it's marked as USD. Null/0 for IQD bills.
    await tryExec('ALTER TABLE Exhibitions ADD COLUMN exchange_rate REAL');

    // Same idea for Supplies (مواد أولية): USD records carry their own rate.
    await tryExec('ALTER TABLE Supplies ADD COLUMN exchange_rate REAL');

    // "ديون علينا" — debts the business owes to someone else, a separate
    // ledger from CustomersDebts (money owed TO the business). Brand new
    // tables for existing installs; CREATE TABLE IF NOT EXISTS is already
    // idempotent so no try/catch needed here.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS OnUsDebts (
        id       INTEGER,
        name     TEXT,
        date     TEXT,
        bill     TEXT,
        tPrice   INTEGER,
        notes    TEXT,
        currency TEXT,
        PRIMARY KEY (id AUTOINCREMENT)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS OnUsPayments (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id        INTEGER NOT NULL,
        payment_amount INTEGER NOT NULL,
        payment_date   TEXT NOT NULL,
        notes          TEXT,
        FOREIGN KEY (debt_id) REFERENCES OnUsDebts(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onCreate(Database db, int version) async {
    final sql = await rootBundle.loadString('assets/create.sql');

    // Split by semicolon (basic SQL script runner)
    final statements = sql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    for (final stmt in statements) {
      await db.execute(stmt);
    }
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Apply migrations if needed
    // For now, assume migrations are applied externally
  }

  /// Execute a SELECT query - returns list of maps
  static Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?>? args,
  ]) async {
    final database = await db;
    return database.rawQuery(sql, args);
  }

  /// Execute an INSERT/UPDATE/DELETE - returns affected rows
  static Future<int> execute(String sql, [List<Object?>? args]) async {
    final database = await db;
    return database.rawUpdate(sql, args);
  }

  /// Batch insert with transaction
  static Future<void> insertBatch(
    String sql,
    List<List<Object?>> argsList,
  ) async {
    final database = await db;
    final batch = database.batch();
    for (final args in argsList) {
      batch.rawInsert(sql, args);
    }
    await batch.commit();
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}