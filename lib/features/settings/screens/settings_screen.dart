import 'package:flutter/material.dart';

import '../../../core/theme/theme_mode_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.themeModeController,
    super.key,
  });

  final ThemeModeController themeModeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeModeController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Use system theme'),
                      subtitle:
                          const Text('Automatically match device appearance'),
                      value: ThemeMode.system,
                      groupValue: themeModeController.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeModeController.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: themeModeController.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeModeController.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: themeModeController.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeModeController.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
