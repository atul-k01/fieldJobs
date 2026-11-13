import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_text_styles.dart';
import 'app_log.dart';

/// Centralized utility for opening phone dialer and external maps (Apple Maps / Google Maps)
class ExternalLauncher {
  ExternalLauncher._();

  /// Opens the device dial pad with the customer phone number
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty) {
      _showError(context, 'No valid phone number provided.');
      return;
    }

    final uri = Uri.parse('tel:$cleanNumber');
    AppLog.i('ExternalLauncher', 'Launching dialer for: $cleanNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        AppLog.w('ExternalLauncher', 'Cannot launch tel URI: $uri');
        if (context.mounted) {
          _showError(context, 'Could not launch phone dialer on this device.');
        }
      }
    } catch (e) {
      AppLog.e('ExternalLauncher', 'Failed to launch phone dialer: $e');
      if (context.mounted) {
        _showError(context, 'Error launching phone dialer: $e');
      }
    }
  }

  /// Opens customer address in native maps:
  /// - On iOS: Prompts technician to choose Apple Maps or Google Maps
  /// - On Android / Other: Launches Google Maps directly
  static Future<void> openMapAddress(BuildContext context, String address) async {
    if (address.trim().isEmpty) {
      _showError(context, 'No address available for navigation.');
      return;
    }

    AppLog.i('ExternalLauncher', 'Opening maps for address: $address');

    if (Platform.isIOS) {
      _showIosMapChooser(context, address);
    } else {
      await _launchAndroidGoogleMaps(context, address);
    }
  }

  /// Shows clean bottom sheet on iOS to choose between Apple Maps and Google Maps
  static void _showIosMapChooser(BuildContext context, String address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: AppDimens.space10),
                  Text(
                    'Open Address in Maps',
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  address,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // Option 1: Apple Maps
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  side: const BorderSide(color: AppColors.divider),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: const Icon(CupertinoIcons.map_fill, color: Color(0xFF1E293B), size: 22),
                ),
                title: const Text(
                  'Apple Maps',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text('Default iOS Navigation', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _launchAppleMaps(context, address);
                },
              ),
              const SizedBox(height: AppDimens.space10),

              // Option 2: Google Maps
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  side: const BorderSide(color: AppColors.divider),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                title: const Text(
                  'Google Maps',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text('Google Navigation & Traffic', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _launchGoogleMapsWebOrApp(context, address);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchAppleMaps(BuildContext context, String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.apple.com/?q=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showError(context, 'Could not open Apple Maps.');
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Error opening Apple Maps: $e');
    }
  }

  static Future<void> _launchGoogleMapsWebOrApp(BuildContext context, String address) async {
    final encoded = Uri.encodeComponent(address);
    // Try Google Maps native scheme first on iOS, fallback to HTTPS
    final nativeUri = Uri.parse('comgooglemaps://?q=$encoded');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showError(context, 'Could not open Google Maps.');
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Error opening Google Maps: $e');
    }
  }

  static Future<void> _launchAndroidGoogleMaps(BuildContext context, String address) async {
    final encoded = Uri.encodeComponent(address);
    final geoUri = Uri.parse('geo:0,0?q=$encoded');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showError(context, 'Could not open Google Maps on this device.');
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Error opening maps: $e');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
