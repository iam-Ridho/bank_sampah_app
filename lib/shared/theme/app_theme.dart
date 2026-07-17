import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// Design token terpusat — terjemahan LANGSUNG dari `:root` CSS di
/// mockup `agri_mineral_figma_mockup_with_login.html` (tema "AgroMin
/// Manager"). Setiap nilai di sini punya pasangan persis di file CSS
/// asli — kalau mockup-nya diupdate, cukup samakan nilai di sini,
/// TIDAK perlu menyentuh widget yang memakainya.
///
/// Prinsip: SEMUA warna/radius/shadow di app harus diambil dari sini,
/// jangan hardcode Colors.teal/Colors.green dkk di widget manapun.
class AppColors {
  AppColors._();

  // Brand — sesuai --green-900 s/d --green-accent di mockup
  static const green900 = Color(0xFF1B5E20);
  static const green800 = Color(0xFF2E7D32);
  static const green700 = Color(0xFF388E3C);
  static const green100 = Color(0xFFE8F5E9);
  static const green50 = Color(0xFFF1F8F1);
  static const greenAccent = Color(0xFF4CAF50);

  // Neutrals — sesuai --gray-50 s/d --gray-900
  static const gray50 = Color(0xFFF8F9FA);
  static const gray100 = Color(0xFFF2F4F6);
  static const gray200 = Color(0xFFE9ECEF);
  static const gray300 = Color(0xFFDEE2E6);
  static const gray400 = Color(0xFFADB5BD);
  static const gray500 = Color(0xFF6C757D);
  static const gray700 = Color(0xFF343A40);
  static const gray900 = Color(0xFF212529);

  // Semantic accents — sesuai --orange, --blue, --gold, --red, --slate
  static const orange = Color(0xFFE65100);
  static const orangeBg = Color(0xFFFFF3E0);
  static const blue = Color(0xFF1565C0);
  static const blueBg = Color(0xFFE3F2FD);
  static const gold = Color(0xFFF9A825);
  static const goldBg = Color(0xFFFFFDE7);
  static const red = Color(0xFFC62828);
  static const redLight = Color(0xFFFFEBEE);
  static const slate = Color(0xFF546E7A);
  static const slateBg = Color(0xFFECEFF1);

  // Warna tambahan yang dipakai mockup untuk sawit (#BF360C di atas
  // #FBE9E7) — tidak didefinisikan sebagai CSS var bernama, tapi
  // dipakai berulang di beberapa tempat, jadi tetap dipusatkan di sini.
  static const sawitAccent = Color(0xFFBF360C);
  static const sawitBg = Color(0xFFFBE9E7);

  // Background utama di luar canvas/card — sesuai `body { background }`
  static const scaffoldBackground = Color(0xFFE8ECF0);
}

/// Radius — sesuai --r-sm s/d --r-xl
class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Shadow — sesuai --shadow-card dan --shadow-fab. Flutter tidak punya
/// multi-layer box-shadow yang identik 1:1, jadi ini pendekatan yang
/// secara visual paling mendekati efek aslinya di Material.
class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const fab = [
    BoxShadow(color: Color(0x591B5E20), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

/// ThemeData Flutter yang dibangun dari token di atas. Dipakai langsung
/// sebagai `theme:` di MaterialApp.
///
/// CATATAN PENTING (trade-off offline-first): `google_fonts` mengunduh
/// file font Inter dari Google Fonts API saat PERTAMA KALI dipakai di
/// suatu device, lalu cache lokal untuk pemakaian berikutnya. Kalau app
/// pertama kali dibuka TANPA internet sama sekali, font akan fallback ke
/// font sistem (bukan error) — jadi tidak mengganggu fungsi, hanya
/// tampilan teks sedikit berbeda dari Inter sampai device pernah online.
/// Kalau ini dianggap terlalu berisiko untuk use-case lapangan, alternatif:
/// bundle file .ttf Inter langsung ke assets/fonts/ dan deklarasikan di
/// pubspec.yaml — lebih pasti tapi menambah ukuran APK dan langkah setup.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green900,
      primary: AppColors.green900,
      secondary: AppColors.green700,
      surface: Colors.white,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.gray100,
      // Font Inter sesuai mockup — google_fonts otomatis download &
      // cache font-nya, tidak perlu menambahkan file .ttf manual ke
      // assets/ (yang akan menambah langkah setup di tengah deadline).
      textTheme: GoogleFonts.interTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.green900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, 
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xB3FFFFFF), // putih 70% opacity
        indicatorColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray700,
          side: const BorderSide(color: AppColors.gray200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.green700, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        labelStyle: const TextStyle(color: AppColors.gray500, fontSize: 13),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.green900,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.gray700),
        secondaryLabelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        side: const BorderSide(color: AppColors.gray200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.green900,
        foregroundColor: Colors.white,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.gray200, thickness: 1),
    );
  }
}
