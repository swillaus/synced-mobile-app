import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synced/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  DatabaseHelper.internal();

  initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "baby_tracker.db");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE User(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL, password TEXT NOT NULL, authToken TEXT NOT NULL, name TEXT NOT NULL, image TEXT)");
    print("User table created");
  }

  Future<int> saveUser() async {
    var dbClient = await db;
    var existingUsers = await dbClient.query("User");
    if (existingUsers.length > 0) {
      int res = await dbClient.delete("User");
      return res;
    }

    int res = await dbClient.insert("User", User.toMap());
    return res;
  }

  Future<int> deleteUsers() async {
    var dbClient = await db;
    int res = await dbClient.delete("User");
    User.removeUser();
    return res;
  }

  Future<bool> isLoggedIn() async {
    var dbClient = await db;
    var res = await dbClient.query("User");
    return res.isNotEmpty ? true : false;
  }

  Future<List<Map<String, dynamic>>> getLoggedInUser() async {
    var dbClient = await db;
    var res = await dbClient.query("User");
    return res;
  }
}
