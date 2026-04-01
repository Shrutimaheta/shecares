class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const products = '/products';
  static const productDetail = '/product-detail';
  static const cart = '/cart';
  static const orderSuccess = '/order-success';
  static const orders = '/orders';
  static const tracking = '/tracking';
  static const profile = '/profile';
  static const wellness = '/wellness';
  static const admin = '/admin';
}

class AppConstants {
  static const appName = 'SheCares';
  static const adminAppName = 'SheCares Admin';
  static const defaultCity = 'Ahmedabad';
  static const freeDeliveryThreshold = 499.0;
  static const deliveryFee = 29.0;
  static const emergencyFee = 49.0;
  static const minServicePincode = 380001;
  static const maxServicePincode = 382480;
  static const maxCartSkus = 10;
  static const maxQuantityPerSku = 10;
  static const defaultMinimumUtrLength = 12;
  static const defaultCheckoutSettingsDocId = 'checkout';
  static const defaultCheckoutQrPath = 'settings/upi_qr.jpg';
  static const defaultUpiId = 'shecares@okaxis';
  static const defaultPayeeName = 'SheCares Welfare';
  static const defaultPaymentInstructions =
      'Open any UPI app, pay the exact order amount, then paste your UTR or transaction reference below so our team can verify and confirm the order.';

  static const careTargets = <String>['Self', 'Baby', 'Elderly'];
  static const reservedUsernames = <String>{
    'admin',
    'superadmin',
    'support',
    'shecares',
    'help',
    'system',
    'root',
    'test',
    'demo',
  };

  static const languages = <Map<String, String>>[
    {'code': 'en', 'label': 'English'},
    {'code': 'gu', 'label': 'Gujarati'},
    {'code': 'hi', 'label': 'Hindi'},
  ];
}
