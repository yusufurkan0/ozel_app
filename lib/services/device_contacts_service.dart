import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class DeviceContactsService {
  /// Opens the device native contact picker and returns the selected contact name and phone.
  static Future<Map<String, String>?> pickContact() async {
    try {
      if (kIsWeb) return null;
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact != null) {
        String name = contact.displayName ?? '';
        if (name.isEmpty && contact.name != null) {
          name = ' '.trim();
        }
        String phone = '';
        if (contact.phones.isNotEmpty) {
          phone = contact.phones.first.number;
        }
        return {
          'name': name.isNotEmpty ? name : 'Seçilen Kişi',
          'phone': phone,
        };
      }
    } catch (e) {
      debugPrint('pickContact error: ');
    }
    return null;
  }

  /// Opens the device native contact creation screen pre-filled with name and phone.
  static Future<bool> saveContactToDevice({
    required String name,
    required String phone,
    String? role,
  }) async {
    try {
      if (kIsWeb) return false;
      final contact = Contact(
        name: Name(first: name),
        phones: [Phone(number: phone)],
        notes: [Note(note: role != null ? 'Destek Rolü: ' : 'Destek Kişisi')],
      );
      final id = await FlutterContacts.native.showCreator(contact: contact);
      return id != null || true;
    } catch (e) {
      debugPrint('saveContactToDevice error: ');
      return false;
    }
  }
}
