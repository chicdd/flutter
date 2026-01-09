import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/member.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('members.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE members ADD COLUMN display_order INTEGER NOT NULL DEFAULT 0');

      final members = await db.query('members', orderBy: 'id ASC');
      for (int i = 0; i < members.length; i++) {
        await db.update(
          'members',
          {'display_order': i},
          where: 'id = ?',
          whereArgs: [members[i]['id']],
        );
      }
    }
  }

  Future<Member> insertMember(Member member) async {
    final db = await database;

    final maxOrder = await db.rawQuery('SELECT COALESCE(MAX(display_order), -1) as max_order FROM members');
    final nextOrder = (maxOrder.first['max_order'] as int) + 1;

    final memberWithOrder = Member(
      name: member.name,
      displayOrder: nextOrder,
    );

    final id = await db.insert('members', memberWithOrder.toMap());
    return Member(id: id, name: member.name, displayOrder: nextOrder);
  }

  Future<List<Member>> getAllMembers() async {
    final db = await database;
    final result = await db.query('members', orderBy: 'display_order ASC');
    return result.map((map) => Member.fromMap(map)).toList();
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMembersOrder(List<Member> members) async {
    final db = await database;
    final batch = db.batch();

    for (int i = 0; i < members.length; i++) {
      batch.update(
        'members',
        {'display_order': i},
        where: 'id = ?',
        whereArgs: [members[i].id],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
