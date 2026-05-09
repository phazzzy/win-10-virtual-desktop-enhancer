class VdeEventRouter {
    __New(app, settings, core, tray) {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Tray := tray
    }

    Initialize() {
        if (this.Settings.GeneralDefaultDesktop > 0 && this.Settings.GeneralDefaultDesktop != this.App.InitialDesktopNo) {
            this.SwitchToDesktop(this.Settings.GeneralDefaultDesktop)
        } else {
            this.OnDesktopSwitch(this.App.InitialDesktopNo)
        }
    }

    OnDesktopSwitchMessage(wParam, lParam, msg, hwnd) {
        this.OnDesktopSwitch(lParam + 1)
    }

    OnDesktopSwitch(n) {
        if (this.App.IsDisabled)
            return
        this.Tray.UpdateDesktopCheck(n)
        this.App.PreviousDesktopNo := this.App.CurrentDesktopNo
        this.App.CurrentDesktopNo := n
    }

    SwitchToDesktop(n) {
        if (!this.App.IsDisabled)
            this.Core.ChangeDesktop(n)
    }
    MoveToDesktop(n) {
        if (!this.App.IsDisabled)
            this.Core.MoveCurrentWindowToDesktop(n)
    }
    MoveAndSwitchToDesktop(n) {
        if (!this.App.IsDisabled) {
            this.Core.MoveCurrentWindowToDesktop(n)
            this.Core.ChangeDesktop(n)
        }
    }

    OnShiftLeftPress(*) => this.SwitchToDesktop(this.Core.GetPreviousDesktopNumber())
    OnShiftRightPress(*) => this.SwitchToDesktop(this.Core.GetNextDesktopNumber())
    OnMoveLeftPress(*) => this.MoveToDesktop(this.Core.GetPreviousDesktopNumber())
    OnMoveRightPress(*) => this.MoveToDesktop(this.Core.GetNextDesktopNumber())
    OnMoveAndShiftLeftPress(*) => this.MoveAndSwitchToDesktop(this.Core.GetPreviousDesktopNumber())
    OnMoveAndShiftRightPress(*) => this.MoveAndSwitchToDesktop(this.Core.GetNextDesktopNumber())
    OnShiftLastActivePress(*) => this.SwitchToDesktop(this.App.PreviousDesktopNo)
    OnMoveLastActivePress(*) => this.MoveToDesktop(this.App.PreviousDesktopNo)
    OnMoveAndShiftLastActivePress(*) => this.MoveAndSwitchToDesktop(this.App.PreviousDesktopNo)

    OnTaskbarScrollUp(*) {
        if (!this.App.IsDisabled && this.Core.IsCursorHoveringTaskbar())
            this.OnShiftLeftPress()
    }
    OnTaskbarScrollDown(*) {
        if (!this.App.IsDisabled && this.Core.IsCursorHoveringTaskbar())
            this.OnShiftRightPress()
    }

    TogglePinWindow(*) {
        if this.Core.IsPinnedWindow()
            this.Core.UnpinWindow()
        else
            this.Core.PinWindow()
    }
    TogglePinApp(*) {
        if this.Core.IsPinnedApp()
            this.Core.UnpinApp()
        else
            this.Core.PinApp()
    }
    ToggleOnTop(*) => WinSetAlwaysOnTop(-1, "A")
    PinToTop(*) => WinSetAlwaysOnTop(1, "A")
    UnpinFromTop(*) => WinSetAlwaysOnTop(0, "A")

    ChangeDesktopName(*) {
        cur := this.Core.GetCurrentDesktopNumber()
        currentName := this.Core.GetDesktopName(cur)
        result := InputBox(Format(this.App.ChangeDesktopNamesPopupText, cur), this.App.ChangeDesktopNamesPopupTitle, "", currentName)
        if (result.Result = "OK") {
            this.Core.SetDesktopName(cur, result.Value)
            this.Tray.UpdateDesktopCheck(cur)
        }
    }
}

