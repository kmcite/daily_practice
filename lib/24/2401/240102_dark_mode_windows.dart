import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:win32/win32.dart';

void main() {
  const keyPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize';

  // Open the registry key with read-write access
  final key = Registry.openPath(
    RegistryHive.currentUser,
    path: keyPath,
    desiredAccessRights: AccessRights.allAccess,
  );

  final currentAppTheme = key.getIntValue('AppsUseLightTheme') ?? 1;
  final currentSystemTheme = key.getIntValue('SystemUsesLightTheme') ?? 1;

  final newValue = (currentAppTheme == 1 && currentSystemTheme == 1) ? 0 : 1;

  key.createValue(RegistryValue.int32('AppsUseLightTheme', newValue));
  key.createValue(RegistryValue.int32('SystemUsesLightTheme', newValue));
  broadcastThemeChange();
  debugPrint(
    '[🌗] Windows theme switched to: ${newValue == 0 ? "Dark" : "Light"} mode',
  );
  key.close();
}

void broadcastThemeChange() {
  final param = TEXT('ImmersiveColorSet');
  SendMessageTimeout(
    HWND_BROADCAST,
    WM_SETTINGCHANGE,
    0,
    param.address,
    SMTO_ABORTIFHUNG,
    100,
    nullptr,
  );
}
