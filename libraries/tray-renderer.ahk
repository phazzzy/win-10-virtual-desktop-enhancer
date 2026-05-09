class VdeTrayRenderer {
    __New(app, settings, core, logger := "") {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Logger := logger
    }

    BuildInitial() {
        this._Log("INFO", "tray_build_begin")
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Reload", (*) => Reload())
        A_TrayMenu.Default := "Reload"
        A_TrayMenu.Add("Disable keys", (*) => this.ToggleDisabled())
        A_TrayMenu.Add()

        Loop this.App.NumDesktops {
            i := A_Index
            name := this.Core.GetDesktopName(i)
            this.App.DesktopMenuItems[i] := name
            A_TrayMenu.Add(name, (*) => this.SwitchToDesktop(i))
            if (this.App.InitialDesktopNo = i)
                A_TrayMenu.Check(name)
        }

        scriptMenu := Menu()
        scriptMenu.Add("Open in explorer", (*) => Run(A_ScriptDir))
        scriptMenu.Add("Edit script", (*) => Run('notepad.exe "' A_ScriptDir '\virtual-desktop-enhancer.ahk"'))
        scriptMenu.Add("Edit config", (*) => Run("rundll32.exe shell32.dll,ShellExec_RunDLL " A_ScriptDir "\\settings.ini"))
        scriptMenu.Add()
        scriptMenu.Add("Exit", (*) => ExitApp())
        A_TrayMenu.Add("Script", scriptMenu)

        this.UpdateTrayIcon(this.App.InitialDesktopNo)
        this._Log("INFO", "tray_build_done")
    }

    ToggleDisabled() {
        this.App.IsDisabled := !this.App.IsDisabled
        A_TrayMenu.ToggleCheck("Disable keys")
        TrayTip("Windows 10 Virtual Desktop Enhancer", this.App.IsDisabled ? "Disabled" : "Enabled")
        this._Log("INFO", "toggle_disabled", "value=" this.App.IsDisabled)
    }

    SwitchToDesktop(n) {
        if (!this.App.IsDisabled)
            this.Core.ChangeDesktop(n)
    }

    UpdateDesktopCheck(n) {
        for i, name in this.App.DesktopMenuItems
            A_TrayMenu.Uncheck(name)
        if (this.App.DesktopMenuItems.Has(n))
            A_TrayMenu.Check(this.App.DesktopMenuItems[n])
        this.UpdateTrayIcon(n)
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
