class VdeTrayRenderer {
    __New(app, settings, core) {
        this.App := app
        this.Settings := settings
        this.Core := core
    }

    BuildInitial() {
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
    }

    ToggleDisabled() {
        this.App.IsDisabled := !this.App.IsDisabled
        A_TrayMenu.ToggleCheck("Disable keys")
        TrayTip("Windows 10 Virtual Desktop Enhancer", this.App.IsDisabled ? "Disabled" : "Enabled")
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
    }
}
