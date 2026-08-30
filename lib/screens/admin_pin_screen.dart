import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partyapp_admin/core/constants/app_colors.dart';

import 'admin_home_screen.dart';

/// Locks the whole dashboard behind a PIN that only the owner knows. The very
/// first launch asks to create the PIN, then every launch (and the in-app lock
/// button) ask for it again. The PIN is never stored in clear text: only a
/// salted, iterated SHA-256 digest lives in Firestore (`admin/access`), so
/// reading the database is not enough to open the dashboard.
class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  static const int _pinLength = 6;

  static const String _collection = 'admin';
  static const String _docId = 'access';

  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = true;
  bool _setup = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGate();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_docId)
          .get();
      if (!mounted) return;
      setState(() {
        _setup = !doc.exists;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setup = true;
        _loading = false;
        _error = 'تعذر الاتصال بخدمة الحماية، أنشئ رمز PIN';
      });
    }
  }

  String _hashPin(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt@$pin');
    for (var i = 0; i < 2500; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  String _newSalt() {
    final rnd = Random.secure();
    return base64Encode(
      List<int>.generate(16, (_) => rnd.nextInt(256)),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final db = FirebaseFirestore.instance;
    final pin = _pinCtrl.text;

    if (_setup) {
      final confirm = _confirmCtrl.text;
      if (pin.length != _pinLength) {
        return _fail('يجب أن يتكون الرمز من 6 أرقام');
      }
      if (pin != confirm) {
        return _fail('الرقمان غير متطابقين، حاول مجدداً');
      }
      final salt = _newSalt();
      try {
        await db.collection(_collection).doc(_docId).set({
          'salt': salt,
          'pinHash': _hashPin(pin, salt),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        return _fail('تعذر حفظ الرمز، تحقق من الاتصال');
      }
      _open();
      return;
    }

    if (pin.length != _pinLength) {
      return _fail('أدخل 6 أرقام');
    }
    try {
      final doc = await db.collection(_collection).doc(_docId).get();
      if (!doc.exists) {
        return _fail('لم يُعثر على رمز الداشبورد');
      }
      final data = doc.data()!;
      final salt = (data['salt'] ?? '') as String;
      final stored = (data['pinHash'] ?? '') as String;
      if (stored.isEmpty || stored != _hashPin(pin, salt)) {
        return _fail('رمز PIN غير صحيح');
      }
    } catch (_) {
      return _fail('تعذر التحقق، تحقق من الاتصال');
    }
    _open();
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
      _pinCtrl.clear();
      _confirmCtrl.clear();
    });
  }

  void _open() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: _building(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _building() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryGold, AppColors.lightGold],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.45),
                blurRadius: 26,
              ),
            ],
          ),
          child: const Icon(Icons.lock_outline, color: Colors.black87, size: 38),
        ),
        const SizedBox(height: 18),
        const Text(
          'داشبورد حفلة',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _setup
              ? 'أنشئ رمز PIN لحماية لوحة الإدارة (6 أرقام)'
              : 'هذه اللوحة خاصة بالمشرف — أدخل رمز PIN للدخول',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pinField(
                controller: _pinCtrl,
                label: _setup ? 'رمز PIN الجديد' : 'رمز PIN',
                autofocus: true,
              ),
              if (_setup) ...[
                const SizedBox(height: 14),
                _pinField(
                  controller: _confirmCtrl,
                  label: 'تأكيد الرمز',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE57373), fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.black87,
                          ),
                        )
                      : Text(
                          _setup ? 'حفظ والدخول' : 'دخول',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'اللوحة خاصة بك أنت فقط',
          style: TextStyle(color: AppColors.textGray, fontSize: 11),
        ),
      ],
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          obscureText: _obscure,
          keyboardType: TextInputType.number,
          maxLength: _pinLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.primaryGold,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.backgroundDark.withValues(alpha: 0.7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryGold.withValues(alpha: 0.22),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryGold,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}