// ===============================
// QuickServe Internationalization (i18n)
// Multi-language Support
// ===============================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Supported locales
class AppLocales {
  static const Locale english = Locale('en', 'US');
  static const Locale french = Locale('fr', 'FR');
  static const Locale hausa = Locale('ha', 'NG');
  static const Locale yoruba = Locale('yo', 'NG');
  static const Locale igbo = Locale('ig', 'NG');

  static List<Locale> supportedLocales = [english, french, hausa, yoruba, igbo];

  static Map<String, String> localeNames = {
    'en': 'English',
    'fr': 'Français',
    'ha': 'Hausa',
    'yo': 'Yorùbá',
    'ig': 'Igbo',
  };
}

// Locale Provider for state management
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = AppLocales.english;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}

// App Translations
class AppStrings {
  final String languageCode;

  AppStrings(this.languageCode);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale.languageCode);
  }

  // Get translation by key
  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']![key] ??
        key;
  }

  // Common strings
  String get appName => get('app_name');
  String get home => get('home');
  String get orders => get('orders');
  String get wallet => get('wallet');
  String get profile => get('profile');
  String get search => get('search');
  String get cart => get('cart');
  String get checkout => get('checkout');
  String get login => get('login');
  String get signup => get('signup');
  String get logout => get('logout');
  String get email => get('email');
  String get password => get('password');
  String get confirmPassword => get('confirm_password');
  String get name => get('name');
  String get phone => get('phone');
  String get address => get('address');
  String get save => get('save');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get submit => get('submit');
  String get loading => get('loading');
  String get error => get('error');
  String get success => get('success');
  String get retry => get('retry');
  String get noData => get('no_data');
  String get offline => get('offline');
  String get offlineMessage => get('offline_message');

  // Order related
  String get myOrders => get('my_orders');
  String get orderHistory => get('order_history');
  String get trackOrder => get('track_order');
  String get orderPlaced => get('order_placed');
  String get orderConfirmed => get('order_confirmed');
  String get preparing => get('preparing');
  String get onTheWay => get('on_the_way');
  String get delivered => get('delivered');
  String get cancelled => get('cancelled');

  // Subscription related
  String get subscription => get('subscription');
  String get mySubscriptions => get('my_subscriptions');
  String get subscribeMeals => get('subscribe_meals');
  String get breakfast => get('breakfast');
  String get lunch => get('lunch');
  String get dinner => get('dinner');
  String get weekly => get('weekly');
  String get monthly => get('monthly');

  // Settings
  String get settings => get('settings');
  String get darkMode => get('dark_mode');
  String get language => get('language');
  String get notifications => get('notifications');
  String get help => get('help');
  String get about => get('about');

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'QuickServe',
      'home': 'Home',
      'orders': 'Orders',
      'wallet': 'Wallet',
      'profile': 'Profile',
      'search': 'Search',
      'cart': 'Cart',
      'checkout': 'Checkout',
      'login': 'Login',
      'signup': 'Sign Up',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'name': 'Name',
      'phone': 'Phone',
      'address': 'Address',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'submit': 'Submit',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',
      'no_data': 'No data available',
      'offline': 'You\'re Offline',
      'offline_message': 'Please check your internet connection',
      'my_orders': 'My Orders',
      'order_history': 'Order History',
      'track_order': 'Track Order',
      'order_placed': 'Order Placed',
      'order_confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'on_the_way': 'On the Way',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'subscription': 'Subscription',
      'my_subscriptions': 'My Subscriptions',
      'subscribe_meals': 'Subscribe to Meals',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'help': 'Help & Support',
      'about': 'About',
    },
    'fr': {
      'app_name': 'QuickServe',
      'home': 'Accueil',
      'orders': 'Commandes',
      'wallet': 'Portefeuille',
      'profile': 'Profil',
      'search': 'Rechercher',
      'cart': 'Panier',
      'checkout': 'Paiement',
      'login': 'Connexion',
      'signup': 'Inscription',
      'logout': 'Déconnexion',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'name': 'Nom',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'submit': 'Soumettre',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'retry': 'Réessayer',
      'no_data': 'Aucune donnée disponible',
      'offline': 'Hors ligne',
      'offline_message': 'Vérifiez votre connexion internet',
      'my_orders': 'Mes commandes',
      'order_history': 'Historique des commandes',
      'track_order': 'Suivre la commande',
      'order_placed': 'Commande passée',
      'order_confirmed': 'Confirmée',
      'preparing': 'En préparation',
      'on_the_way': 'En route',
      'delivered': 'Livrée',
      'cancelled': 'Annulée',
      'subscription': 'Abonnement',
      'my_subscriptions': 'Mes abonnements',
      'subscribe_meals': 'S\'abonner aux repas',
      'breakfast': 'Petit-déjeuner',
      'lunch': 'Déjeuner',
      'dinner': 'Dîner',
      'weekly': 'Hebdomadaire',
      'monthly': 'Mensuel',
      'settings': 'Paramètres',
      'dark_mode': 'Mode sombre',
      'language': 'Langue',
      'notifications': 'Notifications',
      'help': 'Aide et support',
      'about': 'À propos',
    },
    'ha': {
      'app_name': 'QuickServe',
      'home': 'Gida',
      'orders': 'Oda',
      'wallet': 'Jakar Kuɗi',
      'profile': 'Bayanai',
      'search': 'Bincika',
      'cart': 'Kwando',
      'checkout': 'Biya',
      'login': 'Shiga',
      'signup': 'Yi Rajista',
      'logout': 'Fita',
      'email': 'Imel',
      'password': 'Kalmar Sirri',
      'confirm_password': 'Tabbatar da Kalmar Sirri',
      'name': 'Suna',
      'phone': 'Waya',
      'address': 'Adireshi',
      'save': 'Ajiye',
      'cancel': 'Soke',
      'confirm': 'Tabbatar',
      'submit': 'Aika',
      'loading': 'Ana lodawa...',
      'error': 'Kuskure',
      'success': 'Nasara',
      'retry': 'Sake gwadawa',
      'no_data': 'Babu bayani',
      'offline': 'Ba a kan layi',
      'offline_message': 'Duba haɗin intanet ɗinka',
      'my_orders': 'Odar na',
      'order_history': 'Tarihin Oda',
      'track_order': 'Bi Oda',
      'order_placed': 'An Yi Oda',
      'order_confirmed': 'An Tabbatar',
      'preparing': 'Ana Shirya',
      'on_the_way': 'A Hanya',
      'delivered': 'An Isarwa',
      'cancelled': 'An Soke',
      'subscription': 'Biyan Kudi',
      'my_subscriptions': 'Biyan Kuɗina',
      'subscribe_meals': 'Yi Rajista don Abinci',
      'breakfast': 'Karin Kumallo',
      'lunch': 'Abincin Rana',
      'dinner': 'Abincin Dare',
      'weekly': 'Mako-mako',
      'monthly': 'Wata-wata',
      'settings': 'Saiti',
      'dark_mode': 'Yanayin Duhu',
      'language': 'Harshe',
      'notifications': 'Sanarwa',
      'help': 'Taimako',
      'about': 'Game da',
    },
    'yo': {
      'app_name': 'QuickServe',
      'home': 'Ile',
      'orders': 'Àṣẹ',
      'wallet': 'Apamọ́wọ́',
      'profile': 'Àkọsílẹ̀',
      'search': 'Ṣàwárí',
      'cart': 'Agbọn',
      'checkout': 'Sanwo',
      'login': 'Wọlé',
      'signup': 'Forúkọsílẹ̀',
      'logout': 'Jáde',
      'email': 'Ímeèlì',
      'password': 'Ọ̀rọ̀ Aṣínà',
      'confirm_password': 'Jẹ́rìísí Ọ̀rọ̀ Aṣínà',
      'name': 'Orúkọ',
      'phone': 'Fóònù',
      'address': 'Àdírẹ́sì',
      'save': 'Fi pamọ́',
      'cancel': 'Fagilé',
      'confirm': 'Jẹ́rìísí',
      'submit': 'Ránṣẹ́',
      'loading': 'Ń gba...',
      'error': 'Àṣìṣe',
      'success': 'Àṣeyọrí',
      'retry': 'Tún gbìyànjú',
      'no_data': 'Kò sí dátà',
      'offline': 'Kò sí ìsopọ̀',
      'offline_message': 'Ṣàyẹ̀wò ìsopọ̀ intánẹ́ẹ̀tì rẹ',
      'my_orders': 'Àṣẹ Mi',
      'order_history': 'Ìtàn Àṣẹ',
      'track_order': 'Tọpinpin Àṣẹ',
      'order_placed': 'A ti Pàṣẹ',
      'order_confirmed': 'Ti Fìdí Múlẹ̀',
      'preparing': 'A ń Múra',
      'on_the_way': 'Lọ́nà',
      'delivered': 'Ti Dé',
      'cancelled': 'Ti Fagilé',
      'subscription': 'Ìforúkọsílẹ̀',
      'my_subscriptions': 'Ìforúkọsílẹ̀ Mi',
      'subscribe_meals': 'Forúkọsílẹ̀ fún Oúnjẹ',
      'breakfast': 'Oúnjẹ Àárọ̀',
      'lunch': 'Oúnjẹ Ọ̀sán',
      'dinner': 'Oúnjẹ Alẹ́',
      'weekly': 'Ọ̀sẹ̀ kan',
      'monthly': 'Oṣù kan',
      'settings': 'Ètò',
      'dark_mode': 'Ìmọ́lẹ̀ Dúdú',
      'language': 'Èdè',
      'notifications': 'Ìfitónilétí',
      'help': 'Ìrànlọ́wọ́',
      'about': 'Nípa',
    },
    'ig': {
      'app_name': 'QuickServe',
      'home': 'Ụlọ',
      'orders': 'Iwu',
      'wallet': 'Obere akpa',
      'profile': 'Profaịlụ',
      'search': 'Chọọ',
      'cart': 'Ngwongwo',
      'checkout': 'Kwụọ ụgwọ',
      'login': 'Banye',
      'signup': 'Debanye aha',
      'logout': 'Pụọ',
      'email': 'Email',
      'password': 'Okwuntughe',
      'confirm_password': 'Kwado Okwuntughe',
      'name': 'Aha',
      'phone': 'Ekwentị',
      'address': 'Adreesị',
      'save': 'Chekwaa',
      'cancel': 'Kagbuo',
      'confirm': 'Kwado',
      'submit': 'Nyefee',
      'loading': 'Na-ebu...',
      'error': 'Njehie',
      'success': 'Ọganihu',
      'retry': 'Nwaa ọzọ',
      'no_data': 'Enweghị data',
      'offline': 'Ị nọghị n\'ịntanetị',
      'offline_message': 'Biko lelee njikọ intanetị gị',
      'my_orders': 'Iwu m',
      'order_history': 'Akụkọ iwu',
      'track_order': 'Soro iwu',
      'order_placed': 'Etinyela iwu',
      'order_confirmed': 'Akwadoro',
      'preparing': 'Na-akwado',
      'on_the_way': 'N\'ụzọ',
      'delivered': 'Ebulatara',
      'cancelled': 'Akagburu',
      'subscription': 'Ndenye aha',
      'my_subscriptions': 'Ndenye aha m',
      'subscribe_meals': 'Denye aha maka nri',
      'breakfast': 'Nri ụtụtụ',
      'lunch': 'Nri ehihie',
      'dinner': 'Nri anyasị',
      'weekly': 'Izu izu',
      'monthly': 'Ọnwa ọnwa',
      'settings': 'Ntọala',
      'dark_mode': 'Ọnọdụ ọchịchịrị',
      'language': 'Asụsụ',
      'notifications': 'Ọkwa',
      'help': 'Enyemaka',
      'about': 'Maka',
    },
  };
}
