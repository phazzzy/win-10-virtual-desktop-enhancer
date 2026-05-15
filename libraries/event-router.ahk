class VdeEventRouter {
    __New(app, settings, core, tray, overlayTooltip, logger := "") {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Tray := tray
        this.OverlayTooltip := overlayTooltip
        this.Logger := logger
        this.TaskbarScrollCooldownMs := 200
        this.LastTaskbarScrollTick := 0
    }

    Initialize() {
        this._Log("INFO", "router_initialize")
        ; Keep user on the currently active desktop at startup.
        ; Current desktop is detected earlier by core-domain and stored in App.InitialDesktopNo.
        this.OnDesktopSwitch(this.App.InitialDesktopNo)
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
        this._ShowDesktopTooltip(n)
        this._Log("INFO", "desktop_switched", "current=" this.App.CurrentDesktopNo " previous=" this.App.PreviousDesktopNo)
    }

    _ShowDesktopTooltip(n) {
        if (!this.Settings.TooltipsEnabled) {
            this._Log("DEBUG", "tooltip_skip", "reason=disabled desktop=" n)
            return
        }

        text := this.Core.GetDesktopName(n)
        this._Log("DEBUG", "tooltip_show_begin", "desktop=" n " text=" text)
        this.OverlayTooltip.Show(text, this.Settings)
        this._Log("DEBUG", "tooltip_show_done", "desktop=" n " via=overlay")
    }

    SwitchToDesktop(n) {
        if (!this.App.IsDisabled) {
            this._Log("DEBUG", "switch_to_desktop", "target=" n)
            this.Core.ChangeDesktop(n)
        }
    }
    MoveToDesktop(n) {
        if (!this.App.IsDisabled) {
            this._Log("DEBUG", "move_to_desktop", "target=" n)
            this.Core.MoveCurrentWindowToDesktop(n)
        }
    }
    MoveAndSwitchToDesktop(n) {
        if (!this.App.IsDisabled) {
            this._Log("DEBUG", "move_and_switch_to_desktop", "target=" n)
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
        if (!this.App.IsDisabled && this.Settings.GeneralTaskbarScrollSwitching && this._CanHandleTaskbarScroll())
            this.OnShiftLeftPress()
    }
    OnTaskbarScrollDown(*) {
        if (!this.App.IsDisabled && this.Settings.GeneralTaskbarScrollSwitching && this._CanHandleTaskbarScroll())
            this.OnShiftRightPress()
    }

    _CanHandleTaskbarScroll() {
        now := A_TickCount
        if (now - this.LastTaskbarScrollTick < this.TaskbarScrollCooldownMs)
            return false
        this.LastTaskbarScrollTick := now
        return true
    }

    ToggleMenuSetting(settingKey) {
        switch settingKey {
            case "TaskbarScrollSwitching":
                this.Settings.GeneralTaskbarScrollSwitching := !this.Settings.GeneralTaskbarScrollSwitching
                VdeSettingsProvider.SaveBool(this.Settings, "General", "TaskbarScrollSwitching", this.Settings.GeneralTaskbarScrollSwitching)
            case "TaskbarScrollBottomEdgeOnly":
                this.Settings.GeneralTaskbarScrollBottomEdgeOnly := !this.Settings.GeneralTaskbarScrollBottomEdgeOnly
                VdeSettingsProvider.SaveBool(this.Settings, "General", "TaskbarScrollBottomEdgeOnly", this.Settings.GeneralTaskbarScrollBottomEdgeOnly)
            case "UseNativeDesktopSwitching":
                this.Settings.GeneralUseNativeDesktopSwitching := !this.Settings.GeneralUseNativeDesktopSwitching
                VdeSettingsProvider.SaveBool(this.Settings, "General", "UseNativeDesktopSwitching", this.Settings.GeneralUseNativeDesktopSwitching)
            case "DesktopWrapping":
                this.Settings.GeneralDesktopWrapping := this.Settings.GeneralDesktopWrapping = 1 ? 0 : 1
                VdeSettingsProvider.SaveInt(this.Settings, "General", "DesktopWrapping", this.Settings.GeneralDesktopWrapping)
            case "Debug":
                this.Settings.DebugEnabled := !this.Settings.DebugEnabled
                VdeSettingsProvider.SaveBool(this.Settings, "Debug", "Enabled", this.Settings.DebugEnabled)
                this._ApplyDebugRuntimeState()
            case "Tooltips":
                this.Settings.TooltipsEnabled := !this.Settings.TooltipsEnabled
                VdeSettingsProvider.SaveBool(this.Settings, "Tooltips", "Enabled", this.Settings.TooltipsEnabled)
            default:
                this._Log("WARN", "settings_toggle_unknown", settingKey)
                return
        }

        this.Tray.SyncMenuState(this.App.CurrentDesktopNo > 0 ? this.App.CurrentDesktopNo : this.App.InitialDesktopNo)
        this._Log("INFO", "settings_toggled", settingKey)
    }

    _ApplyDebugRuntimeState() {
        if (this.Logger = "")
            return
        this.Logger.Enabled := this.Settings.DebugEnabled
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
            this._Log("INFO", "desktop_name_changed", "desktop=" cur)
        }
    }

    _Log(level, event, details := "") {
        if (this.Logger = "")
            return
        if (level = "ERROR")
            this.Logger.Error("event-router", event, details)
        else if (level = "WARN")
            this.Logger.Warn("event-router", event, details)
        else if (level = "DEBUG")
            this.Logger.Debug("event-router", event, details)
        else
            this.Logger.Info("event-router", event, details)
    }
}
