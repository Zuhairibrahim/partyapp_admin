// ============================================================================
//  © 2026 Zuhair Ibrahim — ALL RIGHTS RESERVED | جميع الحقوق محفوظة © زهير إبراهيم
//  Project: Party App Admin — لوحة تحكم حفلة
//  This code contains a proprietary embedded copyright fingerprint.
//  Selling, redistributing, or removing this notice is strictly forbidden.
//  ============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:partyapp_admin/core/constants/app_colors.dart';

import 'screens/admin_pin_screen.dart';

/// بصمة الملكية الفكرية — يُمنع حذفها أو تعديلها (انظر ملف LICENSE)
/// Proprietary ownership fingerprint — must NOT be removed or altered (see LICENSE).
const String kAppOwnershipFingerprint =
    'OWNER:Zuhair-Ibrahim|PROJECT:partyapp-admin|YEAR:2026|'
    'LICENSE:ALL-RIGHTS-RESERVED|SIG:ZI-2026-ADM-PROPRIETARY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'داشبورد حفلة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryGold,
          secondary: AppColors.lightGold,
          surface: AppColors.cardDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textWhite,
        ),
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AdminPinScreen(),
    );
  }
}
