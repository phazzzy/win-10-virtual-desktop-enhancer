#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce
#HotIf

#Include %A_ScriptDir%\libraries\app-state.ahk
#Include %A_ScriptDir%\libraries\logger.ahk
#Include %A_ScriptDir%\libraries\accessor-gateway.ahk
#Include %A_ScriptDir%\libraries\settings-provider.ahk
#Include %A_ScriptDir%\libraries\core-domain.ahk
#Include %A_ScriptDir%\libraries\tray-renderer.ahk
#Include %A_ScriptDir%\libraries\hotkey-registrar.ahk
#Include %A_ScriptDir%\libraries\event-router.ahk

global VDE_SCRIPT_VERSION := "2.0.0"

global bootstrapSettings := VdeSettingsProvider.Load(A_ScriptDir "\settings.ini")
global logger := VdeLogger(A_ScriptDir, bootstrapSettings.DebugEnabled, bootstrapSettings.DebugVerbose)

logger.Info("bootstrap", "startup_begin", "version=" VDE_SCRIPT_VERSION)

global app := VdeAppState()
app.Logger := logger
global settings := bootstrapSettings
global gateway := VdeAccessorGateway(A_ScriptDir, app, logger)
global core := VdeCoreDomain(app, settings, gateway, logger)
global tray := VdeTrayRenderer(app, settings, core, logger)
global router := VdeEventRouter(app, settings, core, tray, logger)

try {
    gateway.RegisterDesktopSwitchHook(router.OnDesktopSwitchMessage.Bind(router))
    tray.BuildInitial()
    router.Initialize()

    registrar := VdeHotkeyRegistrar(app, settings, router, core, logger)
    registrar.RegisterAll()
    logger.Info("bootstrap", "startup_ready")
} catch as err {
    logger.Error("bootstrap", "startup_failed", err.Message)
    TrayTip("Windows 10 Virtual Desktop Enhancer", "Startup failed: " err.Message)
    throw err
}
