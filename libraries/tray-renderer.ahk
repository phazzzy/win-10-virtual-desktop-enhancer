class VdeTrayRenderer {
    __New(app, settings, core, logger := "") {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Logger := logger
        this.Router := ""
        this.ScriptMenu := ""
        this.MenuKeys := Map(
            "EnableKeys", "Enable shortcuts",
            "TaskbarScrollSwitching", "Taskbar scroll switching",
            "TaskbarScrollBottomEdgeOnly", "Taskbar bottom edge only",
            "TaskbarAntiFlickerDefocusBeforeSwitch", "Taskbar anti-flicker: defocus before switch",
            "TaskbarAntiFlickerRefreshOnSwitch", "Taskbar anti-flicker: refresh on switch",
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
        this._BuildScriptSection()
        this._BuildDesktopsSection()

        this.SyncMenuState(this.App.InitialDesktopNo)

        this.UpdateTrayIcon(this.App.InitialDesktopNo)
        this._Log("INFO", "tray_build_done")
    }

    _BuildDesktopsSection() {
        this.App.DesktopMenuItems := Map()
        Loop this.App.NumDesktops {
            desktopNo := A_Index
            name := this.Core.GetDesktopName(desktopNo)
            this.App.DesktopMenuItems[desktopNo] := name
            A_TrayMenu.Add(name, ObjBindMethod(this, "SwitchToDesktop", desktopNo))
        }
    }

    _BuildScriptSection() {
        this.ScriptMenu := Menu()
        this.ScriptMenu.Add(this.MenuKeys["TaskbarScrollSwitching"], (*) => this._ToggleSetting("TaskbarScrollSwitching"))
        this.ScriptMenu.Add(this.MenuKeys["TaskbarScrollBottomEdgeOnly"], (*) => this._ToggleSetting("TaskbarScrollBottomEdgeOnly"))
        this.ScriptMenu.Add(this.MenuKeys["TaskbarAntiFlickerDefocusBeforeSwitch"], (*) => this._ToggleSetting("TaskbarAntiFlickerDefocusBeforeSwitch"))
        this.ScriptMenu.Add(this.MenuKeys["TaskbarAntiFlickerRefreshOnSwitch"], (*) => this._ToggleSetting("TaskbarAntiFlickerRefreshOnSwitch"))
        this.ScriptMenu.Add(this.MenuKeys["UseNativeDesktopSwitching"], (*) => this._ToggleSetting("UseNativeDesktopSwitching"))
        this.ScriptMenu.Add(this.MenuKeys["DesktopWrapping"], (*) => this._ToggleSetting("DesktopWrapping"))
        this.ScriptMenu.Add(this.MenuKeys["Debug"], (*) => this._ToggleSetting("Debug"))
        this.ScriptMenu.Add(this.MenuKeys["Tooltips"], (*) => this._ToggleSetting("Tooltips"))
        this.ScriptMenu.Add()
        this.ScriptMenu.Add(this.MenuKeys["EnableKeys"], (*) => this.ToggleDisabled())
        this.ScriptMenu.Add("Reload", (*) => Reload())
        this.ScriptMenu.Add("Exit", (*) => ExitApp())
        this.ScriptMenu.Default := "Enable shortcuts"
        A_TrayMenu.Add("Script", this.ScriptMenu)
        A_TrayMenu.Add()
    }

    ToggleDisabled() {
        this.App.IsDisabled := !this.App.IsDisabled
        this.SyncMenuState(this.App.CurrentDesktopNo > 0 ? this.App.CurrentDesktopNo : this.App.InitialDesktopNo)
        TrayTip("Windows 11 Virtual Desktop Enhancer", this.App.IsDisabled ? "Disabled" : "Enabled")
        this._Log("INFO", "toggle_disabled", "value=" this.App.IsDisabled)
    }

    _ToggleSetting(settingKey) {
        if (this.Router = "")
            return
        this.Router.ToggleMenuSetting(settingKey)
    }

    SwitchToDesktop(n, *) {
        this._Log("INFO", "tray_switch_request", "target=" n " disabled=" this.App.IsDisabled)

        if (this.App.IsDisabled) {
            this._Log("DEBUG", "tray_switch_ignored", "reason=disabled target=" n)
            return
        }

        if (n < 1 || n > this.App.NumDesktops) {
            this._Log("WARN", "tray_switch_rejected", "reason=out_of_range target=" n " desktops=" this.App.NumDesktops)
            return
        }

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

        this._SetScriptMenuChecked(this.MenuKeys["EnableKeys"], !this.App.IsDisabled)
        this._SetScriptMenuChecked(this.MenuKeys["TaskbarScrollSwitching"], this.Settings.GeneralTaskbarScrollSwitching)
        this._SetScriptMenuChecked(this.MenuKeys["TaskbarScrollBottomEdgeOnly"], this.Settings.GeneralTaskbarScrollBottomEdgeOnly)
        this._SetScriptMenuChecked(this.MenuKeys["TaskbarAntiFlickerDefocusBeforeSwitch"], this.Settings.GeneralTaskbarAntiFlickerDefocusBeforeSwitch)
        this._SetScriptMenuChecked(this.MenuKeys["TaskbarAntiFlickerRefreshOnSwitch"], this.Settings.GeneralTaskbarAntiFlickerRefreshOnSwitch)
        this._SetScriptMenuChecked(this.MenuKeys["UseNativeDesktopSwitching"], this.Settings.GeneralUseNativeDesktopSwitching)
        this._SetScriptMenuChecked(this.MenuKeys["DesktopWrapping"], this.Settings.GeneralDesktopWrapping = 1)
        this._SetScriptMenuChecked(this.MenuKeys["Debug"], this.Settings.DebugEnabled)
        this._SetScriptMenuChecked(this.MenuKeys["Tooltips"], this.Settings.TooltipsEnabled)
    }

    _SetMenuChecked(itemLabel, isChecked) {
        if (isChecked)
            A_TrayMenu.Check(itemLabel)
        else
            A_TrayMenu.Uncheck(itemLabel)
    }

    _SetScriptMenuChecked(itemLabel, isChecked) {
        if (this.ScriptMenu = "")
            return
        if (isChecked)
            this.ScriptMenu.Check(itemLabel)
        else
            this.ScriptMenu.Uncheck(itemLabel)
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
