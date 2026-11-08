import 'package:hive_flutter/hive_flutter.dart';

class CartSettingsService {
  static const String boxName = 'cart_settings_box';

  // Ініціалізація Hive (працює і в Web, і на Android/iOS/Desktop)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  // Прапор швидкого оформлення (Quick Checkout)
  static bool get isQuickCheckoutEnabled =>
      _box.get('quick_checkout', defaultValue: false);

  static Future<void> setQuickCheckout(bool value) async {
    await _box.put('quick_checkout', value);
  }

  // Збережений промокод
  static String? get appliedPromoCode => _box.get('promo_code');

  static Future<void> setPromoCode(String? code) async {
    if (code == null || code.isEmpty) {
      await _box.delete('promo_code');
    } else {
      await _box.put('promo_code', code);
    }
  }

  // Очищення налаштувань
  static Future<void> clearSettings() async {
    await _box.clear();
  }
}
