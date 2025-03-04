#include "include/arms_updater/arms_updater_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "arms_updater_plugin.h"

void ArmsUpdaterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  arms_updater::ArmsUpdaterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
