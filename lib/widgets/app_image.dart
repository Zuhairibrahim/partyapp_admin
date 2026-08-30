import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Renders an image that may come from a network URL (`http`/`https`),
/// a base64 data URI (`data:image/...;base64,...`), a local absolute file
/// path, or nothing (shows a graceful gold placeholder).
///
/// This lets items added by the admin dashboard (whose photos are stored as
/// base64 in the shared local store) render in the same views that show the
/// built-in network images.
///
/// Network/memory images are decoded at roughly the size they are displayed
/// (via [cacheWidth], derived from the layout constraints) so loading and
/// thumbnails stay fast and light even for high-resolution photos.
class AppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final IconData? fallbackIcon;
  final int? cacheWidth;

  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
    this.cacheWidth,
  });

  bool get _isNetwork => source.startsWith('http://') || source.startsWith('https://');

  bool get _isDataUri => source.startsWith('data:');

  Widget _placeholder(IconData icon) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardDark, AppColors.primaryGold],
          ),
        ),
        child: Icon(icon, color: Colors.black87, size: 46),
      );

  /// Decode size: an explicit [cacheWidth] wins; otherwise the smallest
  /// rendered edge (scaled for the device's pixel density), capped so huge
  /// originals never blow up memory. Fullscreen/carousel images can override.
  int? _resolveCacheWidth(BuildContext context, BoxConstraints constraints) {
    final explicit = cacheWidth;
    if (explicit != null) return explicit;
    final max = constraints.biggest;
    if (!max.isFinite || max.shortestSide <= 0) return 600;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (max.shortestSide * dpr).round().clamp(48, 1200);
  }

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return _placeholder(fallbackIcon ?? Icons.image_outlined);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cache = _resolveCacheWidth(context, constraints);
        if (_isNetwork) {
          return Image.network(
            source,
            fit: fit,
            cacheWidth: cache,
            // Show a graceful gold placeholder while the network photo loads so
            // there is never a blank or broken frame.
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _placeholder(fallbackIcon ?? Icons.image_outlined);
            },
            errorBuilder: (context, error, stackTrace) =>
                _placeholder(fallbackIcon ?? Icons.image_outlined),
          );
        }
        if (_isDataUri) {
          try {
            final bytes = base64Decode(source.split(',').last);
            return Image.memory(
              bytes,
              fit: fit,
              cacheWidth: cache,
              errorBuilder: (context, error, stackTrace) =>
                  _placeholder(fallbackIcon ?? Icons.image_outlined),
            );
          } catch (_) {
            return _placeholder(fallbackIcon ?? Icons.image_outlined);
          }
        }
        // Absolute/local file path.
        return Image.file(
          File(source),
          fit: fit,
          cacheWidth: cache,
          errorBuilder: (context, error, stackTrace) =>
              _placeholder(fallbackIcon ?? Icons.image_outlined),
        );
      },
    );
  }
}