import 'package:intl/intl.dart';

final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

/// Formats an amount as US dollars with grouping, e.g. `$1,250.00`.
String formatMoney(num amount) => _usd.format(amount);
