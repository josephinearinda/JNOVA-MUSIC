import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/services/notification_service.dart';

void main() {
  group('NotificationPreferences', () {
    test('uses the profile defaults for each notification category', () {
      const preferences = NotificationPreferences();

      expect(preferences.isEnabled(NotificationCategory.order), isTrue);
      expect(preferences.isEnabled(NotificationCategory.membership), isTrue);
      expect(preferences.isEnabled(NotificationCategory.promo), isTrue);
      expect(preferences.isEnabled(NotificationCategory.game), isFalse);
    });

    test('the push master switch disables every category', () {
      const preferences = NotificationPreferences(pushEnabled: false);

      for (final category in NotificationCategory.values) {
        expect(preferences.isEnabled(category), isFalse);
      }
    });

    test('category preferences round-trip through stored map values', () {
      final preferences = NotificationPreferences.fromMap({
        'pushEnabled': true,
        'promoOffers': false,
        'orderUpdates': true,
        'membershipPoints': false,
        'gameActivities': true,
      });

      expect(preferences.isEnabled(NotificationCategory.promo), isFalse);
      expect(preferences.isEnabled(NotificationCategory.order), isTrue);
      expect(preferences.isEnabled(NotificationCategory.membership), isFalse);
      expect(preferences.isEnabled(NotificationCategory.game), isTrue);
      expect(
        NotificationPreferences.fromMap(preferences.toMap()).toMap(),
        preferences.toMap(),
      );
    });
  });
}
