import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final int apkSize;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.apkSize,
  });
}

class UpdateService {
  static const String _repo = 'Rextt1122/Pharma';
  static const String _latestReleaseApi =
      'https://api.github.com/repos/$_repo/releases/latest';

  static bool _hasPromptedThisSession = false;

  /// Check GitHub Releases for newer version
  static Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVer = packageInfo.version; // e.g. "1.0.1"

      final response = await http
          .get(
            Uri.parse(_latestReleaseApi),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawTag = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
        final body = data['body'] as String? ?? 'Pembaruan aplikasi Pharma.';
        final assets = data['assets'] as List<dynamic>? ?? [];

        String downloadUrl = '';
        int size = 0;
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            size = (asset['size'] as num?)?.toInt() ?? 0;
            break;
          }
        }

        final bool isNewer = _isVersionNewer(rawTag, currentVer);

        return AppUpdateInfo(
          hasUpdate: isNewer && downloadUrl.isNotEmpty,
          currentVersion: currentVer,
          latestVersion: rawTag.isNotEmpty ? rawTag : currentVer,
          releaseNotes: body,
          downloadUrl: downloadUrl,
          apkSize: size,
        );
      }
    } catch (_) {
      // Offline / network timeout / rate limit fallback
    }

    final fallbackInfo = await PackageInfo.fromPlatform();
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: fallbackInfo.version,
      latestVersion: fallbackInfo.version,
      releaseNotes: '',
      downloadUrl: '',
      apkSize: 0,
    );
  }

  /// Semver compare
  static bool _isVersionNewer(String latest, String current) {
    try {
      final lParts = latest.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return latest != current && latest.isNotEmpty;
    }
  }

  /// Automatically prompt user if update is available (once per app launch)
  static Future<void> checkAndPromptAutoUpdate(BuildContext context) async {
    if (_hasPromptedThisSession) return;
    _hasPromptedThisSession = true;

    final info = await checkForUpdate();
    if (info.hasUpdate && context.mounted) {
      showUpdateDialog(context, info);
    }
  }

  /// Show the styled update modal
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _UpdateDialogContent(info: info),
    );
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final AppUpdateInfo info;

  const _UpdateDialogContent({required this.info});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.05;
      _statusText = 'Menghubungkan ke GitHub...';
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.info.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? widget.info.apkSize;
        int receivedBytes = 0;

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/Pharma_v${widget.info.latestVersion}.apk';
        final file = File(filePath);
        final sink = file.openWrite();

        await response.stream.listen(
          (chunk) {
            receivedBytes += chunk.length;
            sink.add(chunk);
            if (totalBytes > 0 && mounted) {
              setState(() {
                _progress = receivedBytes / totalBytes;
                final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
                final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                _statusText = 'Mengunduh: $mbReceived MB / $mbTotal MB (${(_progress * 100).toInt()}%)';
              });
            }
          },
          onDone: () async {
            await sink.flush();
            await sink.close();

            if (mounted) {
              setState(() {
                _statusText = 'Membuka paket instalasi...';
                _progress = 1.0;
              });
            }

            final result = await OpenFilex.open(
              filePath,
              type: 'application/vnd.android.package-archive',
            );

            if (mounted) {
              setState(() => _isDownloading = false);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status: ${result.message}'),
                    backgroundColor: AppColors.alertRed,
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            }
          },
          onError: (e) {
            sink.close();
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _statusText = 'Gagal mengunduh: $e';
              });
            }
          },
          cancelOnError: true,
        ).asFuture();
      } else {
        throw Exception('Server mengembalikan kode: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Gagal: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeMb = (widget.info.apkSize / (1024 * 1024)).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 4,
        AppSpacing.lg,
        AppSpacing.lg + 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.containerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.pharmaNavy.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.pharmaNavy,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembaruan Tersedia',
                      style: AppTypography.subtitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pharmaNavy,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Versi v${widget.info.latestVersion} ($sizeMb MB) • Aktif: v${widget.info.currentVersion}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.containerLow),
            ),
            constraints: const BoxConstraints(maxHeight: 130),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                widget.info.releaseNotes.isNotEmpty
                    ? widget.info.releaseNotes
                    : 'Peningkatan performa, perbaikan tampilan, dan stabilitas telemetri.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppColors.containerLow,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.pharmaNavy,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.containerHigh),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Nanti Saja'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pharmaNavy,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onPressed: _startDownloadAndInstall,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Perbarui Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
