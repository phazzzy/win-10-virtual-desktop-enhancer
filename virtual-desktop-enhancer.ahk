#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce
#HotIf

; --- Hotkey burst tuning (configured via settings.ini [General]) ---


#Include %A_ScriptDir%\libraries\app-state.ahk
#Include %A_ScriptDir%\libraries\logger.ahk
#Include %A_ScriptDir%\libraries\accessor-gateway.ahk
#Include %A_ScriptDir%\libraries\settings-provider.ahk
#Include %A_ScriptDir%\libraries\core-domain.ahk
#Include %A_ScriptDir%\libraries\tray-renderer.ahk
#Include %A_ScriptDir%\libraries\overlay-tooltip.ahk
#Include %A_ScriptDir%\libraries\hotkey-registrar.ahk
#Include %A_ScriptDir%\libraries\event-router.ahk

global bootstrapSettings := VdeSettingsProvider.Load(A_ScriptDir "\settings.ini")
global VDE_SCRIPT_VERSION := bootstrapSettings.AppVersion
global logger := VdeLogger(A_ScriptDir, bootstrapSettings.DebugEnabled, bootstrapSettings.DebugVerbose)

logger.Info("bootstrap", "startup_begin", "version=" VDE_SCRIPT_VERSION)

global app := VdeAppState()
app.Logger := logger
global settings := bootstrapSettings
global gateway := VdeAccessorGateway(A_ScriptDir, app, logger)
global core := VdeCoreDomain(app, settings, gateway, logger)
global tray := VdeTrayRenderer(app, settings, core, logger)
global overlayTooltip := VdeOverlayTooltip(logger)
global router := VdeEventRouter(app, settings, core, tray, overlayTooltip, logger)
tray.BindRouter(router)
VdeEnableDarkTrayMenus()

try {
    VdeApplyHotkeyBurstTuning(settings)

    gateway.RegisterDesktopSwitchHook(router.OnDesktopSwitchMessage.Bind(router))
    tray.BuildInitial()
    router.Initialize()

    registrar := VdeHotkeyRegistrar(app, settings, router, core, logger)
    registrar.RegisterAll()
    logger.Info("bootstrap", "startup_ready")
} catch as err {
    logger.Error("bootstrap", "startup_failed", err.Message)
    TrayTip("Windows 11 Virtual Desktop Enhancer", "Startup failed: " err.Message)
    throw err
}

VdeApplyHotkeyBurstTuning(settings) {
    if (!settings.GeneralHotkeyBurstTuningEnabled)
        return

    maxHotkeys := Integer(settings.GeneralMaxHotkeysPerInterval)
    intervalMs := Integer(settings.GeneralHotkeyIntervalMs)

    ; If either value is <= 0, disable AutoHotkey burst warning and rely on app-level throttling.
    if (maxHotkeys <= 0 || intervalMs <= 0) {
        A_MaxHotkeysPerInterval := 2147483647
        A_HotkeyInterval := 0
        return
    }

    ; Keep values in safe ranges before assigning to built-in hotkey runtime controls.
    maxHotkeys := Max(1, Min(1000, maxHotkeys))
    intervalMs := Max(1, Min(60000, intervalMs))

    A_MaxHotkeysPerInterval := maxHotkeys
    A_HotkeyInterval := intervalMs
}

VdeEnableDarkTrayMenus() {
    try {
        ; undocumented uxtheme ordinals are only known to be usable on modern Windows builds
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

        ; required calls for menu theming must exist, otherwise fail gracefully
        if !(setPreferredAppMode && flushMenuThemes)
            return

        DllCall(setPreferredAppMode, "Int", 2, "Int") ; ForceDark

        if (allowDarkModeForWindow && A_TrayMenu.HasOwnProp("Handle"))
            DllCall(allowDarkModeForWindow, "Ptr", A_TrayMenu.Handle, "UInt", 1)

        DllCall(flushMenuThemes)
    }
}

VdeSoftRefreshTaskbar() {
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
