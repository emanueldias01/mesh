
import 'package:floor/floor.dart';

@entity
class Address {
  
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String address;

  Address({required this.id, required this.address});
}