class VdeEventRouter {
    __New(app, settings, core, tray, overlayTooltip, logger := "", runtime := "", settingsToggleService := "") {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Tray := tray
        this.OverlayTooltip := overlayTooltip
        this.Logger := logger
        this.Runtime := runtime
        this.SettingsToggleService := settingsToggleService
        this.TaskbarScrollCooldownMs := 200
        this.LastTaskbarScrollTick := 0
        this._TaskbarRefreshSeq := 0
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
        if (n = this.App.CurrentDesktopNo)
            return
        this.Tray.UpdateDesktopCheck(n)
        this.App.PreviousDesktopNo := this.App.CurrentDesktopNo
        this.App.CurrentDesktopNo := n
        this._AfterDesktopSwitchHack()
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
            this._DefocusActiveWindowBeforeSwitch()
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

    _AfterDesktopSwitchHack() {
        if (!this.Settings.GeneralTaskbarAntiFlickerRefreshOnSwitch)
            return

        this._TaskbarRefreshSeq += 1
        seq := this._TaskbarRefreshSeq
        debounceMs := Max(20, Integer(this.Settings.GeneralTaskbarAntiFlickerRefreshDebounceMs))
        secondPhaseMs := Max(debounceMs, Integer(this.Settings.GeneralTaskbarAntiFlickerRefreshSecondPhaseMs))

        SetTimer((*) => this._RunTaskbarRefreshPhase(seq, 1), -debounceMs)
        SetTimer((*) => this._RunTaskbarRefreshPhase(seq, 2), -secondPhaseMs)
    }

    _DefocusActiveWindowBeforeSwitch() {
        if (!this.Settings.GeneralTaskbarAntiFlickerDefocusBeforeSwitch)
            return

        try {
            ; Shift-based move-and-switch path bypasses this method and keeps normal window focus behavior.
            ; For plain switching, move focus to taskbar to avoid active app activation race during desktop transition.
            if WinExist("ahk_class Shell_TrayWnd")
                WinActivate("ahk_class Shell_TrayWnd")
            this._Log("DEBUG", "anti_flicker_defocus_applied")
        } catch {
            this._Log("WARN", "anti_flicker_defocus_failed")
        }
    }

    _RunTaskbarRefreshPhase(seq, phase) {
        if (seq != this._TaskbarRefreshSeq)
            return
        if (this.Runtime = "" || !this.Runtime.HasMethod("SoftRefreshTaskbar")) {
            this._Log("WARN", "anti_flicker_taskbar_refresh_skipped", "reason=runtime_unavailable phase=" phase)
            return
        }
        refreshOk := this.Runtime.SoftRefreshTaskbar()
        if (refreshOk)
            this._Log("DEBUG", "anti_flicker_taskbar_refresh", "phase=" phase)
        else
            this._Log("WARN", "anti_flicker_taskbar_refresh_failed", "phase=" phase)
    }

    OnShiftLeftPress(*) => this.SwitchToDesktop(this.Core.GetPreviousDesktopNumber())
    OnShiftRightPress(*) => this.SwitchToDesktop(this.Core.GetNextDesktopNumber())
    OnMoveLeftPress(*) => this.MoveToDesktop(this.Core.GetPreviousDesktopNumber())
    OnMoveRightPress(*) => this.MoveToDesktop(this.Core.GetNextDesktopNumber())
    OnMoveAndShiftLeftPress(*) => this.MoveAndSwitchToDesktop(this.Core.GetPreviousDesktopNumber())
    OnMoveAndShiftRightPress(*) => this.MoveAndSwitchToDesktop(this.Core.GetNextDesktopNumber())
    OnShiftLastActivePress(*) => this.SwitchToDesktop(this.App.PreviousDesktopNo)
    OnShiftDefaultDesktopPress(*) => this.SwitchToDesktop(this.Settings.DefaultDesktopNumber)
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
        if (this.SettingsToggleService != "") {
            if (!this.SettingsToggleService.Toggle(settingKey)) {
                this._Log("WARN", "settings_toggle_unknown", settingKey)
                return
            }
            if (settingKey = "Debug")
                this._ApplyDebugRuntimeState()
            this.Tray.SyncMenuState(this.App.CurrentDesktopNo > 0 ? this.App.CurrentDesktopNo : this.App.InitialDesktopNo)
            this._Log("INFO", "settings_toggled", settingKey)
            return
        }

        switch settingKey {
            case "TaskbarScrollSwitching":
                this.Settings.GeneralTaskbarScrollSwitching := !this.Settings.GeneralTaskbarScrollSwitching
                VdeSettingsProvider.SaveBool(this.Settings, "General", "TaskbarScrollSwitching", this.Settings.GeneralTaskbarScrollSwitching)
            case "TaskbarScrollBottomEdgeOnly":
                this.Settings.GeneralTaskbarScrollBottomEdgeOnly := !this.Settings.GeneralTaskbarScrollBottomEdgeOnly
                VdeSettingsProvider.SaveBool(this.Settings, "General", "TaskbarScrollBottomEdgeOnly", this.Settings.GeneralTaskbarScrollBottomEdgeOnly)
            case "TaskbarAntiFlickerDefocusBeforeSwitch":
                this.Settings.GeneralTaskbarAntiFlickerDefocusBeforeSwitch := !this.Settings.GeneralTaskbarAntiFlickerDefocusBeforeSwitch
                VdeSettingsProvider.SaveBool(this.Settings, "General", "TaskbarAntiFlickerDefocusBeforeSwitch", this.Settings.GeneralTaskbarAntiFlickerDefocusBeforeSwitch)
            case "TaskbarAntiFlickerRefreshOnSwitch":
                this.Settings.GeneralTaskbarAntiFlickerRefreshOnSwitch := !this.Settings.GeneralTaskbarAntiFlickerRefreshOnSwitch
                VdeSettingsProvider.SaveBool(this.Settings, "General", "TaskbarAntiFlickerRefreshOnSwitch", this.Settings.GeneralTaskbarAntiFlickerRefreshOnSwitch)
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
        hwnd := WinExist("A")
        if (hwnd)
            this._SetWindowPinnedState(hwnd, !this.Core.IsPinnedWindow(hwnd))
    }
    TogglePinApp(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetAppPinnedState(hwnd, !this.Core.IsPinnedApp(hwnd))
    }
    PinWindow(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetWindowPinnedState(hwnd, true)
    }
    PinApp(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetAppPinnedState(hwnd, true)
    }
    UnpinWindow(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetWindowPinnedState(hwnd, false)
    }
    UnpinApp(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetAppPinnedState(hwnd, false)
    }
    ToggleOnTop(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetAlwaysOnTopState(hwnd, (WinGetExStyle("ahk_id " hwnd) & 0x8) = 0)
    }
    PinToTop(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetAlwaysOnTopState(hwnd, true)
    }
    UnpinFromTop(*) {
        hwnd := WinExist("A")
        if (hwnd)
            this._SetAlwaysOnTopState(hwnd, false)
    }

    _SetWindowPinnedState(hwnd, shouldPin) {
        if (shouldPin)
            this.Core.PinWindow(hwnd)
        else
            this.Core.UnpinWindow(hwnd)
        isPinned := !!this.Core.IsPinnedWindow(hwnd)
        this.Tray.UpdatePinnedWindow(hwnd, isPinned)
        this._ShowActionTooltip(isPinned ? "Window pinned to all desktops" : "Window unpinned from all desktops")
    }

    _SetAppPinnedState(hwnd, shouldPin) {
        if (shouldPin)
            this.Core.PinApp(hwnd)
        else
            this.Core.UnpinApp(hwnd)
        isPinned := !!this.Core.IsPinnedApp(hwnd)
        this.Tray.UpdatePinnedApp(hwnd, isPinned)
        this._ShowActionTooltip(isPinned ? "App pinned to all desktops" : "App unpinned from all desktops")
    }

    _SetAlwaysOnTopState(hwnd, shouldPin) {
        WinSetAlwaysOnTop(shouldPin ? 1 : 0, "ahk_id " hwnd)
        isOnTop := (WinGetExStyle("ahk_id " hwnd) & 0x8) != 0
        this.Tray.UpdateAlwaysOnTop(hwnd, isOnTop)
        this._ShowActionTooltip(isOnTop ? "Window set always on top" : "Window removed from always on top")
    }

    ToggleTrackedState(id) {
        if (!this.App.ModifiedStates.Has(id))
            return
        record := this.App.ModifiedStates[id]
        hwnd := this.Tray.ResolveModifiedStateTarget(record)
        if (!hwnd) {
            TrayTip("Windows 11 Virtual Desktop Enhancer", "Saved window is not currently available")
            this._Log("WARN", "tracked_state_target_missing", "id=" id " type=" record.Type)
            return
        }
        switch record.Type {
            case "PinnedWindow": this._SetWindowPinnedState(hwnd, !this.Core.IsPinnedWindow(hwnd))
            case "PinnedApp": this._SetAppPinnedState(hwnd, !this.Core.IsPinnedApp(hwnd))
            case "AlwaysOnTop": this._SetAlwaysOnTopState(hwnd, (WinGetExStyle("ahk_id " hwnd) & 0x8) = 0)
        }
    }

    _ShowActionTooltip(text) {
        if (!this.Settings.TooltipsEnabled)
            return
        this.OverlayTooltip.Show(text, this.Settings)
        this._Log("DEBUG", "action_tooltip_show", "text=" text)
    }

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
        VdeLogger.Dispatch(this.Logger, "event-router", level, event, details)
    }
}
