class VdeTrayRenderer {
    __New(app, settings, core, logger := "") {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Logger := logger
        this.Router := ""
        this.SettingsMenu := ""
        this.MenuKeys := Map(
            "EnableKeys", "Enable shortcuts",
            "Settings", "Settings",
            "TaskbarScrollSwitching", "Taskbar scroll switching",
            "TaskbarScrollBottomEdgeOnly", "Taskbar bottom edge only",
            "UseNativeDesktopSwitching", "Use native desktop switching",
            "DesktopWrapping", "Desktop wrapping",
            "Debug", "Debug logging",
            "Tooltips", "Tooltips"
        )
    }

    BindRouter(router) {
        this.Router := router
    }

    BuildInitial() {
        this._Log("INFO", "tray_build_begin")
        A_TrayMenu.Delete()
        this._BuildSettingsSection()
        this._BuildScriptSection()
        this._BuildDesktopsSection()

        this.SyncMenuState(this.App.InitialDesktopNo)

        this.UpdateTrayIcon(this.App.InitialDesktopNo)
        this._Log("INFO", "tray_build_done")
    }

    _BuildDesktopsSection() {
        this.App.DesktopMenuItems := Map()
        Loop this.App.NumDesktops {
            i := A_Index
            name := this.Core.GetDesktopName(i)
            this.App.DesktopMenuItems[i] := name
            A_TrayMenu.Add(name, (*) => this.SwitchToDesktop(i))
        }
        A_TrayMenu.Add()
    }

    _BuildSettingsSection() {
        this.SettingsMenu := Menu()
        this.SettingsMenu.Add(this.MenuKeys["EnableKeys"], (*) => this.ToggleDisabled())
        this.SettingsMenu.Add()
        this.SettingsMenu.Add(this.MenuKeys["TaskbarScrollSwitching"], (*) => this._ToggleSetting("TaskbarScrollSwitching"))
        this.SettingsMenu.Add(this.MenuKeys["TaskbarScrollBottomEdgeOnly"], (*) => this._ToggleSetting("TaskbarScrollBottomEdgeOnly"))
        this.SettingsMenu.Add(this.MenuKeys["UseNativeDesktopSwitching"], (*) => this._ToggleSetting("UseNativeDesktopSwitching"))
        this.SettingsMenu.Add(this.MenuKeys["DesktopWrapping"], (*) => this._ToggleSetting("DesktopWrapping"))
        this.SettingsMenu.Add(this.MenuKeys["Debug"], (*) => this._ToggleSetting("Debug"))
        this.SettingsMenu.Add(this.MenuKeys["Tooltips"], (*) => this._ToggleSetting("Tooltips"))
        A_TrayMenu.Add(this.MenuKeys["Settings"], this.SettingsMenu)
        A_TrayMenu.Add()
    }

    _BuildScriptSection() {
        scriptMenu := Menu()
        scriptMenu.Add("Reload", (*) => Reload())
        scriptMenu.Default := "Reload"
        scriptMenu.Add()
        scriptMenu.Add("Open in explorer", (*) => Run(A_ScriptDir))
        scriptMenu.Add("Edit script", (*) => Run('notepad.exe "' A_ScriptDir '\virtual-desktop-enhancer.ahk"'))
        scriptMenu.Add("Edit config", (*) => Run("rundll32.exe shell32.dll,ShellExec_RunDLL " A_ScriptDir "\\settings.ini"))
        scriptMenu.Add()
        scriptMenu.Add("Exit", (*) => ExitApp())
        A_TrayMenu.Add("Script", scriptMenu)
        A_TrayMenu.Add()
    }

    ToggleDisabled() {
        this.App.IsDisabled := !this.App.IsDisabled
        this.SyncMenuState(this.App.CurrentDesktopNo > 0 ? this.App.CurrentDesktopNo : this.App.InitialDesktopNo)
        TrayTip("Windows 10 Virtual Desktop Enhancer", this.App.IsDisabled ? "Disabled" : "Enabled")
        this._Log("INFO", "toggle_disabled", "value=" this.App.IsDisabled)
    }

    _ToggleSetting(settingKey) {
        if (this.Router = "")
            return
        this.Router.ToggleMenuSetting(settingKey)
    }

    SwitchToDesktop(n) {
        if (!this.App.IsDisabled)
            this.Core.ChangeDesktop(n)
    }

    UpdateDesktopCheck(n) {
        this.SyncMenuState(n)
        this.UpdateTrayIcon(n)
    }

    SyncMenuState(currentDesktopNo := 0) {
        for i, name in this.App.DesktopMenuItems
            A_TrayMenu.Uncheck(name)
        if (currentDesktopNo > 0 && this.App.DesktopMenuItems.Has(currentDesktopNo))
            A_TrayMenu.Check(this.App.DesktopMenuItems[currentDesktopNo])

        this._SetSettingsMenuChecked(this.MenuKeys["EnableKeys"], !this.App.IsDisabled)
        this._SetSettingsMenuChecked(this.MenuKeys["TaskbarScrollSwitching"], this.Settings.GeneralTaskbarScrollSwitching)
        this._SetSettingsMenuChecked(this.MenuKeys["TaskbarScrollBottomEdgeOnly"], this.Settings.GeneralTaskbarScrollBottomEdgeOnly)
        this._SetSettingsMenuChecked(this.MenuKeys["UseNativeDesktopSwitching"], this.Settings.GeneralUseNativeDesktopSwitching)
        this._SetSettingsMenuChecked(this.MenuKeys["DesktopWrapping"], this.Settings.GeneralDesktopWrapping = 1)
        this._SetSettingsMenuChecked(this.MenuKeys["Debug"], this.Settings.DebugEnabled)
        this._SetSettingsMenuChecked(this.MenuKeys["Tooltips"], this.Settings.TooltipsEnabled)
    }

    _SetMenuChecked(itemLabel, isChecked) {
        if (isChecked)
            A_TrayMenu.Check(itemLabel)
        else
            A_TrayMenu.Uncheck(itemLabel)
    }

    _SetSettingsMenuChecked(itemLabel, isChecked) {
        if (this.SettingsMenu = "")
            return
        if (isChecked)
            this.SettingsMenu.Check(itemLabel)
        else
            this.SettingsMenu.Uncheck(itemLabel)
    }

    UpdateTrayIcon(n) {
        iconDir := this.Settings.GeneralIconDir
        if !(RegExMatch(iconDir, "i)^[A-Z]:\\") || RegExMatch(iconDir, "^\\\\"))
            iconDir := A_ScriptDir "\\" iconDir

        iconFile := this.Settings.Icons.Has(n) && this.Settings.Icons[n] != "" ? this.Settings.Icons[n] : n ".png"
        iconPath := iconDir iconFile
        fallbackIconPath := iconDir "+.png"

        if FileExist(iconPath)
            TraySetIcon(iconPath)
        else if FileExist(fallbackIconPath)
            TraySetIcon(fallbackIconPath)
        else
            this._Log("WARN", "tray_icon_missing", "desktop=" n " dir=" iconDir)
    }

    _Log(level, event, details := "") {
        if (this.Logger = "")
            return
        if (level = "ERROR")
            this.Logger.Error("tray-renderer", event, details)
        else if (level = "WARN")
            this.Logger.Warn("tray-renderer", event, details)
        else if (level = "DEBUG")
            this.Logger.Debug("tray-renderer", event, details)
        else
            this.Logger.Info("tray-renderer", event, details)
    }
}
