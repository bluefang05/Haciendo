import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../services/platform_service.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;
    final directories = await PlatformService.instance.getAppDirectories();
    final dbDirectory = Directory(p.join(directories['files']!, 'database'));
    await dbDirectory.create(recursive: true);
    final db = await openDatabase(
      p.join(dbDirectory.path, 'haciendo.db'),
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
    _database = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cover_photo_id TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        pin_hash TEXT,
        reminder_at TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        materials TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        taken_at TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_private INTEGER NOT NULL DEFAULT 0,
        is_milestone INTEGER NOT NULL DEFAULT 0,
        is_sequence INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        original_path TEXT NOT NULL,
        display_path TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_sequence_frame INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_projects_updated ON projects(is_deleted, updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_entries_project ON entries(project_id, is_deleted, sort_order)',
    );
    await db.execute(
      'CREATE INDEX idx_photos_entry ON photos(entry_id, sort_order)',
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
