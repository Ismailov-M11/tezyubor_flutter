import 'package:flutter/widgets.dart';

class AppL10n {
  final String code;
  const AppL10n._(this.code);

  static const _ru = AppL10n._('ru');
  static const _uz = AppL10n._('uz');
  static const _en = AppL10n._('en');

  static AppL10n fromCode(String? code) => switch (code) {
        'uz' => _uz,
        'en' => _en,
        _ => _ru,
      };

  String _t(String ru, String uz, String en) => switch (code) {
        'uz' => uz,
        'en' => en,
        _ => ru,
      };

  // Navigation
  String get orders => _t('Заказы', 'Buyurtmalar', 'Orders');
  String get analytics => _t('Аналитика', 'Analitika', 'Analytics');
  String get clients => _t('Клиенты', 'Mijozlar', 'Clients');
  String get settings => _t('Настройки', 'Sozlamalar', 'Settings');

  // Common
  String get save => _t('Сохранить', 'Saqlash', 'Save');
  String get cancel => _t('Отмена', 'Bekor qilish', 'Cancel');
  String get yes => _t('Да', 'Ha', 'Yes');
  String get no => _t('Нет', "Yo'q", 'No');
  String get close => _t('Закрыть', 'Yopish', 'Close');
  String get confirm => _t('Подтвердить', 'Tasdiqlash', 'Confirm');
  String get logout => _t('Выйти', 'Chiqish', 'Log out');
  String get search => _t('Поиск', 'Qidirish', 'Search');
  String get filter => _t('Фильтр', 'Filtr', 'Filter');
  String get apply => _t('Применить', "Qo'llash", 'Apply');
  String get clear => _t('Сбросить', 'Tozalash', 'Clear');
  String get retry => _t('Повторить', 'Qayta', 'Retry');
  String get from => _t('От', 'Dan', 'From');
  String get to => _t('До', 'Gacha', 'To');
  String get all => _t('Все', 'Hammasi', 'All');
  String get error => _t('Ошибка', 'Xatolik', 'Error');
  String get success => _t('Успешно', 'Muvaffaqiyatli', 'Success');

  // Auth
  String get loginTitle => _t('Вход в аккаунт', 'Hisobga kirish', 'Sign In');
  String get adminLoginTitle =>
      _t('Вход для администратора', 'Admin kirishi', 'Admin Sign In');
  String get loginHint =>
      _t('Введите логин и пароль', 'Login va parolni kiriting', 'Enter credentials');
  String get loginBtn => _t('Войти', 'Kirish', 'Sign In');
  String get quickDelivery =>
      _t('Быстрая доставка товаров', "Tez yetkazib berish", 'Fast delivery');

  // Orders
  String get newOrder => _t('Новый заказ', 'Yangi buyurtma', 'New Order');
  String get createOrder => _t('Создать заказ', 'Buyurtma yaratish', 'Create Order');
  String get orderDetail =>
      _t('Детали заказа', 'Buyurtma tafsilotlari', 'Order Details');
  String get medicines => _t('Лекарства', 'Dorilar', 'Medicines');
  String get deliveryCost =>
      _t('Доставка', 'Yetkazib berish', 'Delivery');
  String get totalCost => _t('Итого', 'Jami', 'Total');
  String get courier => _t('Курьер', 'Kuryer', 'Courier');
  String get trackingLink =>
      _t('Ссылка отслеживания', 'Kuzatuv havolasi', 'Tracking Link');
  String get noOrders => _t('Нет заказов', "Buyurtmalar yo'q", 'No orders');
  String get createFirstOrder =>
      _t('Создайте первый заказ', 'Birinchi buyurtmani yarating', 'Create your first order');
  String get cancelOrderTitle =>
      _t('Отменить заказ?', 'Buyurtmani bekor qilasizmi?', 'Cancel order?');
  String get cancelOrderMsg =>
      _t('Это действие нельзя отменить.', "Bu amal qaytarib bo'lmaydi.", 'This cannot be undone.');
  String get orderConfirmed =>
      _t('Заказ подтверждён', 'Buyurtma tasdiqlandi', 'Order confirmed');
  String get orderCancelled =>
      _t('Заказ отменён', 'Buyurtma bekor qilindi', 'Order cancelled');
  String get statusFilter =>
      _t('Фильтр по статусу', "Holat bo'yicha filtr", 'Filter by status');
  String get dateRange => _t('Период', "Sana oralig'i", 'Date range');
  String get createdAt => _t('Создан', 'Yaratilgan', 'Created');
  String get customer => _t('Клиент', 'Mijoz', 'Customer');
  String get address => _t('Адрес', 'Manzil', 'Address');
  String get phone => _t('Телефон', 'Telefon', 'Phone');
  String get allStatuses => _t('Все статусы', 'Barcha holatlar', 'All statuses');
  String get copyLink => _t('Скопировать', 'Nusxalash', 'Copy');
  String get copied => _t('Скопировано', 'Nusxalandi', 'Copied');
  String get comment => _t('Комментарий', 'Izoh', 'Comment');
  String get openLink => _t('Открыть', 'Ochish', 'Open');
  String get orderCommentLbl => _t('Комментарий к заказу', 'Buyurtmaga izoh', 'Order comment');
  String get orderCommentHint => _t('Опишите заказ...', 'Buyurtmani tasvirlab bering...', 'Describe the order...');
  String get orderAmountLbl => _t('Сумма заказа', 'Buyurtma summasi', 'Order Amount');
  String get customerCommentLbl => _t('Комментарий клиента', 'Mijoz izohi', 'Customer comment');
  String get shareOrderLink => _t('Ссылка для клиента', 'Mijoz havolasi', 'Customer link');
  String get totalAmountLbl => _t('Итого', 'Jami', 'Total');

  // Status labels
  String get stPending => _t('Ожидает клиента', 'Mijoz kutilmoqda', 'Awaiting customer');
  String get stAwaiting =>
      _t('Ожид. подтверждения', 'Tasdiqlash kutmoqda', 'Awaiting confirmation');
  String get stConfirmed => _t('Подтверждён', 'Tasdiqlandi', 'Confirmed');
  String get stPickup => _t('Курьер едет', 'Kuryer kelmoqda', 'Courier en route');
  String get stPicked => _t('Курьер забрал', 'Kuryer oldi', 'Picked up');
  String get stDelivery => _t('Доставка', 'Yetkazilmoqda', 'In delivery');
  String get stDelivered => _t('Доставлен', 'Yetkazildi', 'Delivered');
  String get stCancelled => _t('Отменён', 'Bekor qilindi', 'Cancelled');

  // Clients
  String get noClients => _t("Нет клиентов", "Mijozlar yo'q", 'No clients');
  String get clientsSubtitle =>
      _t('Клиенты появятся после первых заказов', 'Mijozlar birinchi buyurtmalardan keyin paydo bo\'ladi', 'Clients will appear after first orders');
  String get clientDetails =>
      _t("Информация о клиенте", "Mijoz haqida ma'lumot", 'Client Details');
  String get ordersCount => _t('заказов', 'buyurtma', 'orders');
  String get lastOrder => _t('Последний заказ', 'Oxirgi buyurtma', 'Last order');
  String get minOrders => _t('Мин. заказов', 'Min. buyurtmalar', 'Min orders');
  String get searchByPhone =>
      _t('Поиск по телефону или имени', "Telefon yoki ism bo'yicha", 'Search by phone or name');

  // Analytics
  String get totalOrdersLbl =>
      _t('Всего заказов', 'Jami buyurtmalar', 'Total Orders');
  String get medicinesAmountLbl =>
      _t('Сумма лекарств', 'Dorilar summasi', 'Medicines Amount');
  String get deliveryRevenueLbl =>
      _t('Выручка доставки', 'Yetkazib berish daromadi', 'Delivery Revenue');
  String get totalRevenueLbl =>
      _t('Общая выручка', 'Umumiy daromad', 'Total Revenue');
  String get ordersByDayLbl =>
      _t('Заказы по дням', 'Kunlik buyurtmalar', 'Orders by Day');
  String get ordersByStatusLbl =>
      _t("По статусам", "Holat bo'yicha", 'By Status');
  String get ordersByCourierLbl =>
      _t("По курьерам", "Kuryer bo'yicha", 'By Courier');

  // Settings
  String get profileStore => _t("Профиль магазина", "Do'kon profili", 'Store Profile');
  String get changePassword =>
      _t('Изменить пароль', "Parolni o'zgartirish", 'Change Password');
  String get subscription => _t('Подписка', 'Obuna', 'Subscription');
  String get aboutApp => _t('О приложении', 'Ilova haqida', 'About App');
  String get appearance => _t('Внешний вид', "Ko'rinish", 'Appearance');
  String get account => _t('Аккаунт', 'Akkaunt', 'Account');
  String get application => _t('Приложение', 'Ilova', 'Application');
  String get language => _t('Язык', 'Til', 'Language');
  String get theme => _t('Тема', 'Mavzu', 'Theme');
  String get themeDark => _t('Тёмная', "Qorong'u", 'Dark');
  String get themeLight => _t("Светлая", "Yorug'", 'Light');
  String get themeSystem => _t('Системная', 'Tizim', 'System');
  String get location => _t('Местоположение', 'Joylashuv', 'Location');
  String get updateLocation =>
      _t('Обновить местоположение', 'Joylashuvni yangilash', 'Update Location');
  String get paySubscription =>
      _t('Продлить подписку', 'Obunani uzaytirish', 'Renew Subscription');
  String get subscriptionActive => _t('Активна', 'Faol', 'Active');
  String get subscriptionExpired => _t('Истекла', 'Tugagan', 'Expired');
  String get daysLeft => _t('дн. осталось', 'kun qoldi', 'days left');
  String get logoutConfirm =>
      _t('Выйти из аккаунта?', 'Hisobdan chiqasizmi?', 'Log out?');
  String get storeNameLbl => _t("Название магазина", "Do'kon nomi", 'Store Name');
  String get emailLbl => _t('Email', 'Email', 'Email');
  String get phoneLbl => _t('Телефон', 'Telefon', 'Phone');
  String get passwordLbl => _t('Пароль', 'Parol', 'Password');
  String get loginFieldLbl => _t('Логин', 'Login', 'Login');
  String get enterLoginHint => _t('Введите логин', 'Loginni kiriting', 'Enter login');
  String get enterPasswordHint => _t('Введите пароль', 'Parolni kiriting', 'Enter password');
  String get oldPasswordLbl => _t('Старый пароль', 'Eski parol', 'Old Password');
  String get newPasswordLbl => _t('Новый пароль', 'Yangi parol', 'New Password');
  String get confirmPasswordLbl =>
      _t('Подтвердите новый пароль', 'Yangi parolni tasdiqlang', 'Confirm Password');
  String get changePasswordTitle =>
      _t('Изменить пароль', "Parolni o'zgartirish", 'Change Password');
  String get passwordChanged =>
      _t('Пароль успешно изменён', 'Parol muvaffaqiyatli o\'zgardi', 'Password changed');
  String get passwordsNoMatch =>
      _t('Новые пароли не совпадают', 'Yangi parollar mos emas', 'Passwords do not match');
  String get passwordTooShort =>
      _t('Пароль должен содержать минимум 6 символов', 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak', 'Password must be at least 6 characters');
  String get fillAllFields =>
      _t('Заполните все поля', "Barcha maydonlarni to'ldiring", 'Fill all fields');
  String get nameCantBeEmpty =>
      _t('Название не может быть пустым', "Nom bo'sh bo'lishi mumkin emas", 'Name cannot be empty');
  String get saveError => _t("Не удалось сохранить", "Saqlab bo'lmadi", 'Could not save');
  String get changPasswordError =>
      _t('Не удалось изменить пароль', "Parolni o'zgartirib bo'lmadi", 'Could not change password');

  // Location
  String get locationTitle =>
      _t('Выбор местоположения', 'Joylashuvni tanlash', 'Pick Location');
  String get searchAddress => _t('Поиск адреса...', 'Manzil qidirish...', 'Search address...');
  String get determiningAddress =>
      _t('Определяю адрес...', 'Manzil aniqlanmoqda...', 'Determining address...');
  String get unknownAddress =>
      _t('Адрес не определён', 'Manzil aniqlanmadi', 'Address unknown');
  String get confirmLocation =>
      _t('Подтвердить местоположение', 'Joylashuvni tasdiqlash', 'Confirm Location');
  String get locationSaved =>
      _t('Местоположение обновлено', 'Joylashuv yangilandi', 'Location updated');
  String get locationError => _t('Ошибка сохранения', 'Saqlashda xatolik', 'Save error');

  // Errors
  String get errorLoading => _t('Ошибка загрузки', 'Yuklashda xatolik', 'Loading error');
}

extension AppL10nContext on BuildContext {
  AppL10n get l10n =>
      AppL10n.fromCode(Localizations.localeOf(this).languageCode);
}
