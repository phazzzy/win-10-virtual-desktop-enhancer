class VdeCoreDomain {
    __New(app, settings, gateway, logger := "") {
        this.App := app
        this.Settings := settings
        this.Gateway := gateway
        this.Logger := logger
        this.App.NumDesktops := this.GetNumberOfDesktops()
        this.App.InitialDesktopNo := this.GetCurrentDesktopNumber()
        this._Log("INFO", "domain_initialized", "desktops=" this.App.NumDesktops " initial=" this.App.InitialDesktopNo)
        this._CacheTaskbarIds()
        this._CacheMonitorBounds()
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
        if (this.Settings.GeneralTaskbarScrollBottomEdgeOnly)
            return this.IsCursorOnBottomEdge()

        MouseGetPos(, &posY, &hoverId)
        if (this.App.TaskbarIds.Length = 0)
            this._CacheTaskbarIds()

        for _, id in this.App.TaskbarIds
            if (hoverId = id)
                return true

        WinGetPos(, &y, , &h, "A")
        onBottomEdge := h - y - posY - 1
        return (y = 0 && onBottomEdge = 0)
    }

    IsCursorOnBottomEdge() {
        prevCoordMode := A_CoordModeMouse
        CoordMode("Mouse", "Screen")
        try {
            MouseGetPos(&posX, &posY)

            if (!this.HasOwnProp("MonitorBounds") || this.MonitorBounds.Length = 0)
                this._CacheMonitorBounds()

            for _, mon in this.MonitorBounds {
                isInsideX := (posX >= mon.Left && posX < mon.Right)
                isBottomPixel := (posY = mon.Bottom - 1)
                if (isInsideX && isBottomPixel)
                    return true
            }
            return false
        } finally {
            CoordMode("Mouse", prevCoordMode)
        }
    }

    _CacheTaskbarIds() {
        this.App.TaskbarIds := []
        mainTaskbarId := WinExist("ahk_class Shell_TrayWnd")
        if (mainTaskbarId)
            this.App.TaskbarIds.Push(mainTaskbarId)
        ids := WinGetList("ahk_class Shell_SecondaryTrayWnd")
        for _, id in ids
            this.App.TaskbarIds.Push(id)
    }

    _CacheMonitorBounds() {
        this.MonitorBounds := []
        monitorCount := MonitorGetCount()
        Loop monitorCount {
            MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
            this.MonitorBounds.Push({ Left: monLeft, Top: monTop, Right: monRight, Bottom: monBottom })
        }
    }

    _Log(level, event, details := "") {
        if (this.Logger = "")
            return
        if (level = "ERROR")
            this.Logger.Error("core-domain", event, details)
        else if (level = "WARN")
            this.Logger.Warn("core-domain", event, details)
        else if (level = "DEBUG")
            this.Logger.Debug("core-domain", event, details)
        else
            this.Logger.Info("core-domain", event, details)
    }
}
