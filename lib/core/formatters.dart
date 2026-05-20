import 'package:intl/intl.dart';

final _currency =
    NumberFormat.currency(locale: 'tr', symbol: '₺', decimalDigits: 2);
final _date = DateFormat('dd.MM.yyyy HH:mm');

String formatTl(num value) => _currency.format(value);
String formatDate(DateTime dt) => _date.format(dt);
