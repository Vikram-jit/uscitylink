import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/services/app_update_service.dart';

const _androidAppId = 'com.uscitylink.app';
const _iosAppId = '6737588933';
const _accent = Color(0xFF0B3D91);

Future<void> openStore() async {
  final String url;
  if (Platform.isAndroid) {
    url = 'https://play.google.com/store/apps/details?id=$_androidAppId';
  } else if (Platform.isIOS) {
    url = 'https://apps.apple.com/app/id$_iosAppId';
  } else {
    return;
  }
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Forced update (Admin → App versions → "Force update"): the app can't be used until it's updated.
class UpdateView extends StatefulWidget {
  final AppUpdateInfoResult? info;
  const UpdateView({super.key, this.info});

  @override
  State<UpdateView> createState() => _UpdateViewState();
}

class _UpdateViewState extends State<UpdateView> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    final result = await AppUpdateService.to.check();
    if (!mounted) return;
    setState(() => _checking = false);
    if (result == null) {
      Get.snackbar('Could not check', 'Check your connection and try again.', snackPosition: SnackPosition.BOTTOM);
    } else if (result.status == UpdateStatus.forceUpdate) {
      Get.snackbar('Still out of date', 'Install ${result.latestLabel ?? 'the new version'} from the store first.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      await AppUpdateService.to.apply(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final store = Platform.isIOS ? 'App Store' : 'Google Play';
    return PopScope(
      canPop: false, // back button / swipe can't skip a required update
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/images/update.webp', height: 220, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Update required',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This version of USCityLink is no longer supported. Install the latest version from $store to keep using the app.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54, height: 1.4),
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 20),
                      _VersionRow(installed: info.installed, latest: info.latestLabel),
                    ],
                    if (info?.releaseNotes != null) ...[
                      const SizedBox(height: 16),
                      _ReleaseNotes(text: info!.releaseNotes!),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        key: const Key('updateNow'),
                        onPressed: openStore,
                        icon: const Icon(Icons.system_update_rounded),
                        label: const Text('Update now', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _checking ? null : _checkAgain,
                      style: TextButton.styleFrom(foregroundColor: _accent),
                      child: _checking
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("I've updated — check again"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Optional update: a newer build is live but the installed one is still allowed.
class OptionalUpdateDialog extends StatelessWidget {
  final AppUpdateInfoResult info;
  const OptionalUpdateDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      icon: const Icon(Icons.system_update_rounded, color: _accent, size: 32),
      title: const Text('Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            info.latestLabel == null ? 'A new version of USCityLink is available.' : 'Version ${info.latestLabel} is available.',
            textAlign: TextAlign.center,
          ),
          if (info.releaseNotes != null) ...[
            const SizedBox(height: 12),
            _ReleaseNotes(text: info.releaseNotes!, maxHeight: 180),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: _accent),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Get.back();
            openStore();
          },
          style: FilledButton.styleFrom(backgroundColor: _accent),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String installed;
  final String? latest;
  const _VersionRow({required this.installed, this.latest});

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, {bool strong = false}) => Expanded(
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              const SizedBox(height: 2),
              Text(value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: strong ? _accent : Colors.black87)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFFF3F6FB), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          cell('Installed', installed),
          if (latest != null) ...[
            const Icon(Icons.arrow_forward_rounded, color: Colors.black38),
            cell('Latest', latest!, strong: true),
          ],
        ],
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  final String text;
  final double maxHeight;
  const _ReleaseNotes({required this.text, this.maxHeight = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What's new", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: Colors.black87, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
