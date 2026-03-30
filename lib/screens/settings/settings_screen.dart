import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:asmrapp/common/constants/strings.dart';
import 'package:asmrapp/core/theme/theme_controller.dart';
import 'package:asmrapp/core/platform/wakelock_controller.dart';
import 'package:asmrapp/core/settings/app_settings_service.dart';
import 'package:asmrapp/screens/settings/cache_manager_screen.dart';
import 'package:asmrapp/screens/settings/audio_format_order_dialog.dart';
import 'package:asmrapp/screens/settings/widgets/settings_group.dart';
import 'package:asmrapp/screens/settings/widgets/settings_tile.dart';
import 'package:asmrapp/screens/settings/widgets/settings_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = SettingsTheme.pageBackground(context);

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settings)),
      backgroundColor: bgColor,
      body: SettingsTheme.noSplashTheme(
        context: context,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _appearanceSection(),
            const SizedBox(height: 24),
            _networkSection(),
            const SizedBox(height: 24),
            _contentSection(context),
            const SizedBox(height: 24),
            _playbackSection(),
            const SizedBox(height: 24),
            _storageSection(context),
            const SizedBox(height: 24),
            _aboutSection(context),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.cannotOpenLink)),
        );
      }
    }
  }

  Widget _appearanceSection() {
    return Consumer<ThemeController>(
      builder: (context, tc, _) => SettingsGroup(
        header: Strings.appearance,
        footer: Strings.themeAutoDesc,
        children: [
          SettingsTile.selection(
            title: Strings.followSystem,
            leading: Icons.palette_outlined,
            selected: tc.themeMode == ThemeMode.system,
            onTap: () => tc.setThemeMode(ThemeMode.system),
          ),
          SettingsTile.selection(
            title: Strings.lightMode,
            leading: Icons.palette_outlined,
            selected: tc.themeMode == ThemeMode.light,
            onTap: () => tc.setThemeMode(ThemeMode.light),
          ),
          SettingsTile.selection(
            title: Strings.darkMode,
            leading: Icons.palette_outlined,
            selected: tc.themeMode == ThemeMode.dark,
            onTap: () => tc.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _networkSection() {
    return Builder(builder: (context) {
      final settings = GetIt.I<AppSettingsService>();
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SettingsGroup(
          header: Strings.network,
          children: AppSettingsService.serverOptions.entries.map((entry) {
            return SettingsTile.selection(
              title: entry.value,
              subtitle: entry.key,
              leading: Icons.lan_outlined,
              selected: settings.serverUrl == entry.key,
              onTap: () => settings.setServerUrl(entry.key),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _contentSection(BuildContext context) {
    return Builder(builder: (context) {
      final settings = GetIt.I<AppSettingsService>();
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SettingsGroup(
          header: Strings.content,
          children: [
            SettingsTile.toggle(
              title: Strings.smartPath,
              subtitle: Strings.smartPathDesc,
              leading: Icons.folder_open_outlined,
              value: settings.smartPathEnabled,
              onChanged: (v) => settings.setSmartPathEnabled(v),
            ),
            SettingsTile.navigation(
              title: Strings.audioFormatPreference,
              leading: Icons.audio_file_outlined,
              value: settings.audioFormatOrder.join(' > '),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AudioFormatOrderDialog(settings: settings),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _playbackSection() {
    return Builder(builder: (context) {
      final controller = GetIt.I<WakeLockController>();
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SettingsGroup(
          header: Strings.playback,
          footer: Strings.screenKeepAwakeDesc,
          children: [
            SettingsTile.toggle(
              title: Strings.screenKeepAwake,
              leading: Icons.wb_sunny_outlined,
              value: controller.enabled,
              onChanged: (_) => controller.toggle(),
            ),
          ],
        ),
      );
    });
  }

  Widget _storageSection(BuildContext context) {
    return SettingsGroup(
      header: Strings.storage,
      children: [
        SettingsTile.navigation(
          title: Strings.cacheManager,
          leading: Icons.storage_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CacheManagerScreen()),
          ),
        ),
      ],
    );
  }

  Widget _aboutSection(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '...';
        return SettingsGroup(
          header: Strings.about,
          children: [
            SettingsTile.navigation(
              title: Strings.versionInfo,
              leading: Icons.info_outline,
              value: version,
            ),
            SettingsTile.navigation(
              title: Strings.openSourceLicenses,
              leading: Icons.description_outlined,
              onTap: () => showLicensePage(
                context: context,
                applicationName: Strings.appName,
                applicationVersion: snapshot.data?.version,
              ),
            ),
            SettingsTile.navigation(
              title: Strings.feedback,
              leading: Icons.feedback_outlined,
              onTap: () => _openUrl(context, Strings.feedbackUrl),
            ),
            SettingsTile.navigation(
              title: Strings.sourceCode,
              leading: Icons.code_outlined,
              onTap: () => _openUrl(context, Strings.repoUrl),
            ),
          ],
        );
      },
    );
  }
}
