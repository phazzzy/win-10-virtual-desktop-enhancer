class VdeWindowsRuntime {
    ApplyHotkeyBurstTuning(settings) {
        if (!settings.GeneralHotkeyBurstTuningEnabled)
            return

        maxHotkeys := Integer(settings.GeneralMaxHotkeysPerInterval)
        intervalMs := Integer(settings.GeneralHotkeyIntervalMs)

        if (maxHotkeys <= 0 || intervalMs <= 0) {
            A_MaxHotkeysPerInterval := 2147483647
            A_HotkeyInterval := 0
            return
        }

        maxHotkeys := Max(1, Min(1000, maxHotkeys))
        intervalMs := Max(1, Min(60000, intervalMs))

        A_MaxHotkeysPerInterval := maxHotkeys
        A_HotkeyInterval := intervalMs
    }

    EnableDarkTrayMenus() {
        try {
            if (VerCompare(A_OSVersion, "10.0") < 0)
                return

            hUxTheme := DllCall("Kernel32.dll\GetModuleHandle", "Str", "uxtheme.dll", "Ptr")
            if (!hUxTheme)
                hUxTheme := DllCall("Kernel32.dll\LoadLibrary", "Str", "uxtheme.dll", "Ptr")
            if (!hUxTheme)
                return

            setPreferredAppMode := DllCall("Kernel32.dll\GetProcAddress", "Ptr", hUxTheme, "Ptr", 135, "Ptr")
            flushMenuThemes := DllCall("Kernel32.dll\GetProcAddress", "Ptr", hUxTheme, "Ptr", 136, "Ptr")
            allowDarkModeForWindow := DllCall("Kernel32.dll\GetProcAddress", "Ptr", hUxTheme, "Ptr", 133, "Ptr")

            if !(setPreferredAppMode && flushMenuThemes)
                return

            DllCall(setPreferredAppMode, "Int", 2, "Int")

            if (allowDarkModeForWindow && A_TrayMenu.HasOwnProp("Handle"))
                DllCall(allowDarkModeForWindow, "Ptr", A_TrayMenu.Handle, "UInt", 1)

            DllCall(flushMenuThemes)
        }
    }

    SoftRefreshTaskbar() {
        WM_SETTINGCHANGE := 0x001A
        HWND_BROADCAST := 0xFFFF
        SMTO_ABORTIFHUNG := 0x0002
        timeoutMs := 150

        try {
            result := 0
            ok := DllCall(
                "User32.dll\SendMessageTimeoutW",
                "Ptr", HWND_BROADCAST,
                "UInt", WM_SETTINGCHANGE,
                "Ptr", 0,
                "Str", "TraySettings",
                "UInt", SMTO_ABORTIFHUNG,
                "UInt", timeoutMs,
                "Ptr*", &result,
                "Ptr"
            )
            return ok != 0
        } catch {
            return false
        }
    }
}
