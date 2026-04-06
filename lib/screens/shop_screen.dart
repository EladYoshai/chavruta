import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../utils/constants.dart';
class ShopItem {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final int price;
  final String category; // 'avatar', 'title', 'shield'
  final String? imagePath; // asset path for image avatars

  const ShopItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imagePath,
  });
}

const List<ShopItem> shopItems = [
  // === Avatars - People ===
  ShopItem(id: 'kohen_gadol', emoji: '', name: 'כהן גדול', description: 'כהן גדול בבגדי זהב', price: 50, category: 'avatar', imagePath: 'assets/images/avatars/kohen_gadol.png'),
  ShopItem(id: 'rebbetzin', emoji: '', name: 'הרבנית', description: 'רבנית עם נרות שבת', price: 50, category: 'avatar', imagePath: 'assets/images/avatars/rebbetzin.png'),
  ShopItem(id: 'talmid_chacham', emoji: '', name: 'תלמיד חכם', description: 'תלמיד חכם עם גמרא', price: 75, category: 'avatar', imagePath: 'assets/images/avatars/talmid_chacham.png'),
  ShopItem(id: 'chacham_sefardi', emoji: '', name: 'חכם ספרדי', description: 'חכם עם קולמוס וקלף', price: 75, category: 'avatar', imagePath: 'assets/images/avatars/chacham_sefardi.png'),
  ShopItem(id: 'morenu_verabenu', emoji: '', name: 'מורינו ורבינו', description: 'מורה תורה בבית המדרש', price: 100, category: 'avatar', imagePath: 'assets/images/avatars/morenu_verabenu.png'),
  ShopItem(id: 'tzaddik_nistar', emoji: '', name: 'צדיק נסתר', description: 'צדיק נסתר ברחוב', price: 120, category: 'avatar', imagePath: 'assets/images/avatars/tzaddik_nistar.png'),
  ShopItem(id: 'tzaddeket', emoji: '', name: 'צדיקה', description: 'צדיקה בגן של אור', price: 100, category: 'avatar', imagePath: 'assets/images/avatars/tzaddeket.png'),
  ShopItem(id: 'gavra_raba', emoji: '', name: 'גברא רבא', description: 'רב שקוע בלימוד הספרים', price: 100, category: 'avatar', imagePath: 'assets/images/avatars/gavra_raba.png'),
  ShopItem(id: 'navi', emoji: '', name: 'נביא', description: 'נביא עם הילה זהובה', price: 150, category: 'avatar', imagePath: 'assets/images/avatars/navi.png'),
  ShopItem(id: 'amora', emoji: '', name: 'אמורא', description: 'אמורא בין הספרים העתיקים', price: 120, category: 'avatar', imagePath: 'assets/images/avatars/amora.png'),
  ShopItem(id: 'lamdan', emoji: '', name: 'למדן', description: 'למדן בספריה חמה', price: 80, category: 'avatar', imagePath: 'assets/images/avatars/lamdan.png'),

  // === Avatars - Foods (3D images) ===
  ShopItem(id: 'jachnun', emoji: '', name: "ג'חנון", description: "ג'חנון חם בשבת בבוקר!", price: 90, category: 'avatar', imagePath: 'assets/images/avatars/jachnun.png'),
  ShopItem(id: 'gefilte_fish', emoji: '', name: 'גפילטע פיש', description: 'מאכל מסורתי אשכנזי', price: 90, category: 'avatar', imagePath: 'assets/images/avatars/gefilte_fish.png'),
  ShopItem(id: 'sufganiya', emoji: '', name: 'סופגניה', description: 'חנוכה שמח!', price: 80, category: 'avatar', imagePath: 'assets/images/avatars/sufganiya.png'),
  ShopItem(id: 'cholent', emoji: '', name: 'חמין / צ\'ולנט', description: 'מה יש לשבת?', price: 100, category: 'avatar', imagePath: 'assets/images/avatars/cholent.png'),
  ShopItem(id: 'falafel', emoji: '', name: 'פלאפל', description: 'האוכל הלאומי', price: 70, category: 'avatar', imagePath: 'assets/images/avatars/falafel.png'),
  ShopItem(id: 'kubeh', emoji: '', name: 'קובה', description: 'קובה של סבתא!', price: 85, category: 'avatar', imagePath: 'assets/images/avatars/kubeh.png'),
  ShopItem(id: 'bourekas', emoji: '', name: 'בורקס', description: 'בורקס חם מהתנור', price: 70, category: 'avatar', imagePath: 'assets/images/avatars/bourekas.png'),
  ShopItem(id: 'kiddush_cup', emoji: '', name: 'כוס קידוש', description: 'בורא פרי הגפן', price: 85, category: 'avatar', imagePath: 'assets/images/avatars/kiddush_cup.png'),
  ShopItem(id: 'hamantaschen', emoji: '', name: 'אוזני המן', description: 'פורים שמח!', price: 75, category: 'avatar', imagePath: 'assets/images/avatars/hamantaschen.png'),

  // === Avatars - Jewish Items (3D images) ===
  ShopItem(id: 'chanukia', emoji: '', name: 'חנוכיה', description: 'מצווה להניחה על פתח ביתו', price: 100, category: 'avatar', imagePath: 'assets/images/avatars/chanukia.png'),
  ShopItem(id: 'sefer_torah', emoji: '', name: 'ספר תורה', description: 'הכתר של התורה', price: 200, category: 'avatar', imagePath: 'assets/images/avatars/sefer_torah.png'),
  ShopItem(id: 'beit_hamikdash', emoji: '', name: 'בית המקדש', description: 'במהרה יבנה', price: 250, category: 'avatar', imagePath: 'assets/images/avatars/beit_hamikdash.png'),

  // === Custom titles ===
  ShopItem(id: 'title_masmid', emoji: '📖', name: 'מתמיד', description: 'תואר מיוחד: מתמיד', price: 100, category: 'title'),
  ShopItem(id: 'title_shoked', emoji: '📚', name: 'שוקד על התורה', description: 'תואר מיוחד: שוקד', price: 100, category: 'title'),
  ShopItem(id: 'title_baal_musar', emoji: '✨', name: 'בעל מוסר', description: 'תואר מיוחד: בעל מוסר', price: 120, category: 'title'),
  ShopItem(id: 'title_lamdan', emoji: '🧠', name: 'למדן', description: 'תואר מיוחד: למדן', price: 150, category: 'title'),
  ShopItem(id: 'title_tzaddik', emoji: '💫', name: 'צדיק', description: 'תואר מיוחד: צדיק', price: 200, category: 'title'),
  ShopItem(id: 'title_tzadeket', emoji: '💫', name: 'צדקת', description: 'תואר מיוחד: צדקת', price: 200, category: 'title'),
  ShopItem(id: 'title_gaon', emoji: '👑', name: 'הגאון', description: 'תואר מיוחד: הגאון', price: 300, category: 'title'),
  ShopItem(id: 'title_mekubal', emoji: '🌟', name: 'מקובל', description: 'תואר מיוחד: מקובל', price: 250, category: 'title'),

  // === Streak shields ===
  ShopItem(id: 'shield_1', emoji: '🛡️', name: 'מגן רצף', description: 'הגנה על רצף ליום אחד', price: 100, category: 'shield'),
  ShopItem(id: 'shield_3', emoji: '🛡️🛡️🛡️', name: '3 מגני רצף', description: 'חבילת 3 מגנים (חיסכון!)', price: 250, category: 'shield'),
];

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final progress = appState.progress;

        final avatars = shopItems.where((i) => i.category == 'avatar').toList();
        final titles = shopItems.where((i) => i.category == 'title').toList();
        final shields = shopItems.where((i) => i.category == 'shield').toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('חנות זוזים'),
            backgroundColor: AppColors.darkGold,
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${progress.zuzim}',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatars section
                  _buildSectionTitle('אווטארים', '🎭'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                    children: avatars
                        .map((item) => _buildShopCard(
                            context, appState, item, progress))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Titles section
                  _buildSectionTitle('תארים מיוחדים', '🏅'),
                  const SizedBox(height: 10),
                  ...titles.map((item) =>
                      _buildTitleCard(context, appState, item, progress)),
                  const SizedBox(height: 24),

                  // Shields section
                  _buildSectionTitle('מגני רצף', '🛡️'),
                  const SizedBox(height: 10),
                  ...shields.map((item) =>
                      _buildTitleCard(context, appState, item, progress)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildShopCard(BuildContext context, AppState appState,
      ShopItem item, dynamic progress) {
    final owned = progress.purchasedAvatars.contains(item.id);
    final isActive = progress.activeAvatar == item.id;
    final canAfford = progress.zuzim >= item.price;

    return GestureDetector(
      onTap: () {
        if (isActive) return;
        if (owned) {
          appState.setActiveAvatar(item.id);
        } else if (canAfford) {
          _showPurchaseDialog(context, appState, item);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.deepBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.deepBlue
                : owned
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.gold.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  item.imagePath!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(item.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(
              item.name,
              style: GoogleFonts.rubik(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Text('פעיל', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.deepBlue, fontWeight: FontWeight.w600))
            else if (owned)
              Text('נרכש', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.success))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  Text(
                    '${item.price}',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: canAfford ? AppColors.darkGold : Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(BuildContext context, AppState appState,
      ShopItem item, dynamic progress) {
    final owned = item.category == 'title'
        ? progress.purchasedTitles.contains(item.id)
        : false;
    final isActiveTitle = item.category == 'title' &&
        progress.activeTitle == item.name;
    final canAfford = progress.zuzim >= item.price;

    return GestureDetector(
      onTap: () {
        if (item.category == 'shield') {
          if (canAfford) _showPurchaseDialog(context, appState, item);
        } else if (isActiveTitle) {
          return;
        } else if (owned) {
          appState.setActiveTitle(item.name);
        } else if (canAfford) {
          _showPurchaseDialog(context, appState, item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActiveTitle
              ? AppColors.deepBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActiveTitle
                ? AppColors.deepBlue
                : AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  Text(
                    item.description,
                    style: GoogleFonts.rubik(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isActiveTitle)
              Text('פעיל', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.deepBlue, fontWeight: FontWeight.w600))
            else if (owned)
              Text('נרכש', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.success))
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: canAfford ? AppColors.darkGold : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(
      BuildContext context, AppState appState, ShopItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'לרכוש ${item.name}?',
            style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    '${item.price} ${AppStrings.zuzim}',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ביטול',
                  style: GoogleFonts.rubik(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                appState.purchaseItem(item.id, item.price, item.category,
                    item.category == 'title' ? item.name : null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGold,
              ),
              child: Text('רכוש',
                  style: GoogleFonts.rubik(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
