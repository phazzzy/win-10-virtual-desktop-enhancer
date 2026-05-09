#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce
#HotIf

#Include %A_ScriptDir%\libraries\app-state.ahk
#Include %A_ScriptDir%\libraries\accessor-gateway.ahk
#Include %A_ScriptDir%\libraries\settings-provider.ahk
#Include %A_ScriptDir%\libraries\core-domain.ahk
#Include %A_ScriptDir%\libraries\tray-renderer.ahk
#Include %A_ScriptDir%\libraries\hotkey-registrar.ahk
#Include %A_ScriptDir%\libraries\event-router.ahk

global VDE_SCRIPT_VERSION := "2.0.0"

global app := VdeAppState()
global settings := VdeSettingsProvider.Load(A_ScriptDir "\settings.ini")
global gateway := VdeAccessorGateway(A_ScriptDir, app)
global core := VdeCoreDomain(app, settings, gateway)
global tray := VdeTrayRenderer(app, settings, core)
global router := VdeEventRouter(app, settings, core, tray)

gateway.RegisterDesktopSwitchHook(router.OnDesktopSwitchMessage.Bind(router))
tray.BuildInitial()
router.Initialize()

registrar := VdeHotkeyRegistrar(app, settings, router, core)
registrar.RegisterAll()
