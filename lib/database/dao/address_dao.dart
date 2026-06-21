
import 'package:floor/floor.dart';
import 'package:mesh/database/models/address.dart';

@dao
abstract class AddressDao {

  @Query("SELECT * FROM Address")
  Future<List<Address>> findAllAddress();

  @insert
  Future<void> insertAddress(Address address);
  
  // @delete
  // Future<void> deleteAddress(Address address);

  @Query('DELETE FROM Address WHERE id = :id')
  Future<void> deleteAddressById(int id);
}