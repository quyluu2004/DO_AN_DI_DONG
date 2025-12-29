import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _selectedAddressId;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  
  Address? get selectedAddress {
    if (_selectedAddressId != null) {
      try {
        return _addresses.firstWhere((a) => a.id == _selectedAddressId);
      } catch (_) {}
    }
    // Fallback to default
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  void selectAddress(String id) {
    _selectedAddressId = id;
    notifyListeners();
  }

  Future<void> fetchAddresses(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      _addresses = snapshot.docs.map((doc) => Address.fromMap(doc.data())).toList();
      
      // If no address selected, try to select default
      if (_selectedAddressId == null && _addresses.isNotEmpty) {
          try {
             _selectedAddressId = _addresses.firstWhere((a) => a.isDefault).id;
          } catch (_) {
             _selectedAddressId = _addresses.first.id;
          }
      }
      
    } catch (e) {
      print('Error fetching addresses: $e');
      _addresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAddress(String userId, Address address) async {
    _isLoading = true;
    notifyListeners();
    try {
      // If this is the first address, make it default
      bool isDefault = address.isDefault;
      if (_addresses.isEmpty) {
        isDefault = true;
      }

      // If setting as default, unset others locally (and ideally in DB transaction)
      if (isDefault) {
         // Batch update could be better but keeping simple for now
         // For now just ensure the new one has isDefault=true
      }
      
      final newAddress = Address(
        id: address.id, 
        userId: userId, 
        name: address.name, 
        phone: address.phone, 
        province: address.province, 
        district: address.district, 
        ward: address.ward, 
        streetAddress: address.streetAddress,
        isDefault: isDefault
      );

      await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(newAddress.id)
          .set(newAddress.toMap());

      _addresses.add(newAddress);
       if (isDefault || _addresses.length == 1) {
          _selectedAddressId = newAddress.id;
       }
       
    } catch (e) {
      print('Error adding address: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddress(String userId, Address address) async {
      _isLoading = true;
      notifyListeners();
      try {
        await _db
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(address.id)
            .update(address.toMap());
            
        final index = _addresses.indexWhere((a) => a.id == address.id);
        if (index != -1) {
          _addresses[index] = address;
        }
      } catch (e) {
        print('Error updating address: $e');
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
  }
  
  Future<void> deleteAddress(String userId, String addressId) async {
    _isLoading = true;
    notifyListeners();
    try {
       await _db.collection('users').doc(userId).collection('addresses').doc(addressId).delete();
       _addresses.removeWhere((a) => a.id == addressId);
       if (_selectedAddressId == addressId) {
         _selectedAddressId = null;
          // re-select default
          if (_addresses.isNotEmpty) {
             _selectedAddressId = _addresses.first.id;
          }
       }
    } catch (e) {
       rethrow;
    } finally {
       _isLoading = false;
       notifyListeners();
    }
  }
}
