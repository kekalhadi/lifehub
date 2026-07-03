import 'package:flutter/material.dart';

/// Registry nama ikon → IconData untuk kategori finance & dompet.
/// Disimpan sebagai String (key) di Isar, dirender ke IconData di UI.
const Map<String, IconData> kCategoryIcons = {
  // Makanan & Minuman
  'restaurant': Icons.restaurant,
  'lunch_dining': Icons.lunch_dining,
  'ramen_dining': Icons.ramen_dining,
  'local_cafe': Icons.local_cafe,
  'fastfood': Icons.fastfood,
  'bakery_dining': Icons.bakery_dining,
  'local_bar': Icons.local_bar,
  'icecream': Icons.icecream,
  'cake': Icons.cake,
  'local_pizza': Icons.local_pizza,
  'set_meal': Icons.set_meal,

  // Transportasi
  'directions_car': Icons.directions_car,
  'local_taxi': Icons.local_taxi,
  'two_wheeler': Icons.two_wheeler,
  'local_gas_station': Icons.local_gas_station,
  'train': Icons.train,
  'directions_bus': Icons.directions_bus,
  'flight': Icons.flight,
  'directions_bike': Icons.directions_bike,
  'electric_scooter': Icons.electric_scooter,
  'local_parking': Icons.local_parking,

  // Belanja
  'shopping_cart': Icons.shopping_cart,
  'shopping_bag': Icons.shopping_bag,
  'checkroom': Icons.checkroom,
  'devices': Icons.devices,
  'local_grocery_store': Icons.local_grocery_store,
  'redeem': Icons.redeem,
  'local_offer': Icons.local_offer,
  'diamond': Icons.diamond,

  // Hiburan
  'sports_esports': Icons.sports_esports,
  'movie': Icons.movie,
  'music_note': Icons.music_note,
  'theater_comedy': Icons.theater_comedy,
  'sports_basketball': Icons.sports_basketball,
  'sports_soccer': Icons.sports_soccer,
  'pool': Icons.pool,
  'park': Icons.park,
  'attractions': Icons.attractions,
  'brunch_dining': Icons.brunch_dining,

  // Kesehatan
  'medication': Icons.medication,
  'local_hospital': Icons.local_hospital,
  'fitness_center': Icons.fitness_center,
  'health_and_safety': Icons.health_and_safety,
  'spa': Icons.spa,
  'vaccines': Icons.vaccines,

  // Pendidikan
  'school': Icons.school,
  'menu_book': Icons.menu_book,
  'science': Icons.science,
  'auto_stories': Icons.auto_stories,
  'history_edu': Icons.history_edu,

  // Tagihan & Utilitas
  'receipt_long': Icons.receipt_long,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'wifi': Icons.wifi,
  'phone_iphone': Icons.phone_iphone,
  'home': Icons.home,
  'apartment': Icons.apartment,

  // Pemasukan
  'work': Icons.work,
  'payments': Icons.payments,
  'trending_up': Icons.trending_up,
  'savings': Icons.savings,
  'attach_money': Icons.attach_money,
  'card_giftcard': Icons.card_giftcard,
  'handshake': Icons.handshake,
  'laptop': Icons.laptop,

  // Dompet / Rekening
  'account_balance': Icons.account_balance,
  'account_balance_wallet': Icons.account_balance_wallet,
  'credit_card': Icons.credit_card,
  'smartphone': Icons.smartphone,
  'e_mobiledata': Icons.e_mobiledata,
  'qr_code': Icons.qr_code,

  // Lainnya / Umum
  'inventory_2': Icons.inventory_2,
  'category': Icons.category,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
  'family_restroom': Icons.family_restroom,
  'church': Icons.church,
  'volunteer_activism': Icons.volunteer_activism,
  'flight_takeoff': Icons.flight_takeoff,
  'luggage': Icons.luggage,
  'beach_access': Icons.beach_access,
  'celebration': Icons.celebration,
  'cake_outlined': Icons.cake_outlined,
};

/// Mapping emoji lama → nama ikon, untuk migrasi data yang disimpan sebelum
/// sistem ikon ini ada. Idempoten: hanya dikonversi bila nilainya ada di map.
const Map<String, String> kEmojiToIconKey = {
  '🍜': 'ramen_dining',
  '🍽️': 'restaurant',
  '🍔': 'fastfood',
  '🚗': 'directions_car',
  '🛒': 'shopping_cart',
  '🎮': 'sports_esports',
  '💊': 'medication',
  '📚': 'menu_book',
  '🧾': 'receipt_long',
  '📦': 'inventory_2',
  '💼': 'work',
  '💻': 'laptop',
  '📈': 'trending_up',
  '💰': 'savings',
  '💵': 'payments',
  '🏦': 'account_balance',
  '📱': 'smartphone',
  '💳': 'credit_card',
};

/// Resolusi nama ikon → IconData. Mengembalikan null bila tidak dikenal.
IconData? tryParseIconData(String key) => kCategoryIcons[key];

/// Cek apakah sebuah String adalah key ikon yang valid (bukan emoji lama).
bool isIconKey(String value) => kCategoryIcons.containsKey(value);

/// Konversi emoji lama ke key ikon bila ada di map; bila tidak kembalikan apa adanya.
String migrateEmojiToKey(String value) => kEmojiToIconKey[value] ?? value;

/// Widget ikon kategori yang kompatibel dengan data lama.
/// - Jika [icon] adalah key ikon → render IconData.
/// - Jika tidak (emoji lama / string asing) → render sebagai teks emoji.
class CategoryIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    required this.icon,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final data = tryParseIconData(icon);
    if (data != null) {
      return Icon(data, size: size, color: color);
    }
    // Fallback: emoji lama dirender sebagai teks
    return Text(
      icon,
      style: TextStyle(fontSize: size, color: color),
    );
  }
}
