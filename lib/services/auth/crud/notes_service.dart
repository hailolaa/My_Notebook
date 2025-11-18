

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_notebook/extensions/list/filter.dart';
import 'package:my_notebook/services/auth/crud/crud_exceptions.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as databaseFactoryIo;




class NoteService{
  Database? _db;


  List<DatabaseNote> _notes = [];

  DatabaseUser? _user;

  static final NoteService _shared = NoteService._sharedInstance();
  NoteService._sharedInstance() {
    _notesStreamController = 
        StreamController<List<DatabaseNote>>.broadcast(
          onListen: () {
            _notesStreamController.add(_notes);
          },
        );
  }
  factory NoteService() => _shared;

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes => 
      _notesStreamController.stream.filter(
        (note) {
          final currentUser = _user;
          if(currentUser != null){
            return note.userId == currentUser.id;
          } else{
            throw UserShouldBeSetBeforeReadingAllNotes();
          }
        },
      );
        
  Future<DatabaseUser> getOrCreateUser({required String email, bool setAsCurrentUser = true}) async {
    await _ensureDbIsOpen();
    try{
      final user = await getUser(email: email);
      if(setAsCurrentUser){
        _user = user;
      }
      return user;
    } on CouldNotFindUser{
      final createdUser = await createUser(email: email);
      if(setAsCurrentUser){
        _user = createdUser;
      }
      return createdUser;
    } catch(e){
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }    

  Future<DatabaseNote> updateNote({required DatabaseNote note, required String text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNote(id: note.id);

    final updatedCount = await db.update(
      notesTable,
      {
        textColumn: text,
        isSyncedWithCloudColumn: 0,
      },
      where: '$idColumn = ?',
      whereArgs: [note.id],
    );
    if(updatedCount == 0){
      throw CouldNotUpdateNote();
    }else{
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      notesTable,
      limit: 1,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if(notes.isEmpty){
      throw CouldNotFindNote();
    } else{
      final note = DatabaseNote.fromRowMap(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<List<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(notesTable);
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else{
      return notes.map((noteRow) => DatabaseNote.fromRowMap(noteRow)).toList();
    }
  }
  
  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(notesTable);

    _notes = [];
    _notesStreamController.add(_notes);

    return numberOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      notesTable,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if(deletedCount == 0){
      throw CouldNotDeleteNote();
    }else{
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner, String? text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    if(dbUser != owner){
      throw CouldNotFindUser();
    }

    const text = '';

    final noteId = await db.insert(notesTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);


    return note;

    
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final lowercaseEmail = email.toLowerCase();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [lowercaseEmail],
    );
    if(results.isEmpty){
      throw CouldNotFindUser();
    } else{
      return DatabaseUser.fromRowMap(results.first);
    }
  } 

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      usersTable,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if(deletedCount != 1){
      throw CouldNotDeleteUserException();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final lowercaseEmail = email.toLowerCase();
    final results = await db.query(
      usersTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [lowercaseEmail],
    );
    if(results.isNotEmpty){
      throw UserAlreadyExistsException();
    }
    final userId =await db.insert(usersTable, {
      emailColumn: lowercaseEmail,
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }




  Database _getDatabaseOrThrow(){
    final db = _db;
    if(db == null){
      throw DatabaseIsNotOpenException();
    } else{
      return db;
    }
  } 


  Future<void> close() async {
    final db = _db;
    if(db == null){
      throw DatabaseIsNotOpenException();
    } else{
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try{
      await open();
    } on DatabaseAlreadyOpenException{
      //empty
    }
  } 

  Future<void> open() async {
    if(_db != null){
      throw DatabaseAlreadyOpenException;
    }
    try{
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await databaseFactoryIo.openDatabase(dbPath);
      _db = db;
 
      await db.execute(createUsersTable);

      await db.execute(createNotesTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException{
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });


  DatabaseUser.fromRowMap(Map<String, Object?> map) 
      : id = map['idColumn'] as int,
        email = map['emailColumn'] as String;

  @override
  String toString() {
    return 'DatabaseUser{id: $id, email: $email}';
  }

  @override
  bool operator ==(covariant DatabaseUser other) =>
      id == other.id && email == other.email;
  @override
  int get hashCode => id.hashCode ^ email.hashCode;

}


class DatabaseNote{
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRowMap(Map<String, Object?> map)
      : id = map['idColumn'] as int,
        userId = map['userIdColumn'] as int,
        text = map['textColumn'] as String,
        isSyncedWithCloud = (map['isSyncedWithCloudColumn'] as int) == 1;

  @override
  String toString() {
    return 'DatabaseNote{id: $id, userId: $userId, text: $text, isSyncedWithCloud: $isSyncedWithCloud}';
  }

  @override
  bool operator ==(covariant DatabaseNote other) =>
      id == other.id ;

  @override
  int get hashCode => id.hashCode;

}



const dbName = 'notes.db';
const notesTable = 'notes';
const usersTable = 'users';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'userId';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'isSyncedWithCloud';

const createUsersTable = '''CREATE TABLE IF NOT EXISTS "users" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';


  const createNotesTable = '''CREATE TABLE IF NOT EXISTS "notes" (
        "id"	INTEGER NOT NULL,
        "userId"	INTEGER NOT NULL,
        "text"	TEXT,
        "isSyncedWithCloud"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("userId") REFERENCES "users"("id")
      );''';


