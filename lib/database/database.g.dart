// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $MeshDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $MeshDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $MeshDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<MeshDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorMeshDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $MeshDatabaseBuilderContract databaseBuilder(String name) =>
      _$MeshDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $MeshDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$MeshDatabaseBuilder(null);
}

class _$MeshDatabaseBuilder implements $MeshDatabaseBuilderContract {
  _$MeshDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $MeshDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $MeshDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<MeshDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$MeshDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$MeshDatabase extends MeshDatabase {
  _$MeshDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  AddressDao? _addressDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Address` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `address` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  AddressDao get addressDao {
    return _addressDaoInstance ??= _$AddressDao(database, changeListener);
  }
}

class _$AddressDao extends AddressDao {
  _$AddressDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _addressInsertionAdapter = InsertionAdapter(
            database,
            'Address',
            (Address item) =>
                <String, Object?>{'id': item.id, 'address': item.address});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Address> _addressInsertionAdapter;

  @override
  Future<List<Address>> findAllAddress() async {
    return _queryAdapter.queryList('SELECT * FROM Address',
        mapper: (Map<String, Object?> row) =>
            Address(id: row['id'] as int, address: row['address'] as String));
  }

  @override
  Future<void> deleteAddressById(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Address WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<void> insertAddress(Address address) async {
    await _addressInsertionAdapter.insert(address, OnConflictStrategy.abort);
  }
}
