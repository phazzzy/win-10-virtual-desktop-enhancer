class VdeCoreDomain {
    __New(app, settings, gateway) {
        this.App := app
        this.Settings := settings
        this.Gateway := gateway
        this.App.NumDesktops := this.GetNumberOfDesktops()
        this.App.InitialDesktopNo := this.GetCurrentDesktopNumber()
        Loop this.App.NumDesktops {
            this.App.DesktopNames[A_Index] := this.GetDesktopName(A_Index)
        }
    }

    GetCurrentDesktopNumber() => this.Gateway.GetCurrentDesktopNumber()
    GetNumberOfDesktops() => this.Gateway.GetDesktopCount()
    GetNumberOfCyclableDesktops() => this.Settings.GeneralNumberOfCyclableDesktops >= 1 ? Min(this.App.NumDesktops, this.Settings.GeneralNumberOfCyclableDesktops) : this.App.NumDesktops

    GetDesktopName(n) {
        name := this.Settings.DesktopNames.Has(n) ? this.Settings.DesktopNames[n] : ""
        return name != "" ? name : "Desktop " n
    }

    SetDesktopName(n, name) {
        this.App.DesktopNames[n] := (name = "" ? "Desktop " n : name)
    }

    GetNextDesktopNumber() {
        i := this.GetCurrentDesktopNumber()
        max := this.GetNumberOfCyclableDesktops()
        return this.Settings.GeneralDesktopWrapping = 1 ? (i >= max ? 1 : i + 1) : (i >= max ? i : i + 1)
    }

    GetPreviousDesktopNumber() {
        i := this.GetCurrentDesktopNumber()
        max := this.GetNumberOfCyclableDesktops()
        if (i > max)
            return max
        return this.Settings.GeneralDesktopWrapping = 1 ? (i = 1 ? max : i - 1) : (i = 1 ? i : i - 1)
    }

    ChangeDesktop(n) => this.Gateway.GoToDesktopNumber(n)
    MoveCurrentWindowToDesktop(n) => this.Gateway.MoveWindowToDesktopNumber(WinExist("A"), n)
    PinWindow() => this.Gateway.PinWindow(WinExist("A"))
    UnpinWindow() => this.Gateway.UnPinWindow(WinExist("A"))
    IsPinnedWindow() => this.Gateway.IsPinnedWindow(WinExist("A"))
    PinApp() => this.Gateway.PinApp(WinExist("A"))
    UnpinApp() => this.Gateway.UnPinApp(WinExist("A"))
    IsPinnedApp() => this.Gateway.IsPinnedApp(WinExist("A"))

    IsCursorHoveringTaskbar() {
        MouseGetPos(, &posY, &hoverId)
        if (this.App.TaskbarIds.Length = 0) {
            this.App.TaskbarIds.Push(WinExist("ahk_class Shell_TrayWnd"))
            ids := WinGetList("ahk_class Shell_SecondaryTrayWnd")
            for _, id in ids
                this.App.TaskbarIds.Push(id)
        }
        for _, id in this.App.TaskbarIds
            if (hoverId = id)
                return true

        WinGetPos(, &y, , &h, "A")
        onBottomEdge := h - y - posY - 1
        return (y = 0 && onBottomEdge = 0)
    }
}

