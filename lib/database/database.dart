import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:mesh/database/dao/address_dao.dart';
import 'package:mesh/database/models/address.dart';

part 'database.g.dart';

@Database(version: 1, entities: [Address])
abstract class MeshDatabase extends FloorDatabase {
  AddressDao get addressDao;
}