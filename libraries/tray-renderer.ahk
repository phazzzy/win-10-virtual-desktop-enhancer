class VdeTrayRenderer {
    __New(app, settings, core, logger := "") {
        this.App := app
        this.Settings := settings
        this.Core := core
        this.Logger := logger
        this.Router := ""
        this.ScriptMenu := ""
        this.ModifiedStateMenu := ""
        this.StatePath := A_ScriptDir "\window-state.ini"
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
        this._LoadModifiedStates()
        this._RebuildTrayMenu()
        this.UpdateTrayIcon(this.App.InitialDesktopNo)
        this._Log("INFO", "tray_build_done")
    }

    _RebuildTrayMenu() {
        A_TrayMenu.Delete()
        this._BuildScriptSection()
        this._BuildModifiedStateItems()
        A_TrayMenu.Add()
        this._BuildDesktopsSection()
        currentDesktop := this.App.CurrentDesktopNo > 0 ? this.App.CurrentDesktopNo : this.App.InitialDesktopNo
        this.SyncMenuState(currentDesktop)
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
    }

    _BuildModifiedStateItems() {
        if (this.App.ModifiedStates.Count = 0) {
            A_TrayMenu.Add("No pinned items", (*) => 0)
            A_TrayMenu.Disable("No pinned items")
            return
        }
        this.ModifiedStateMenu := Menu()
        for id, record in this.App.ModifiedStates {
            hwnd := this.ResolveModifiedStateTarget(record)
            record.Active := this._IsRecordActive(record, hwnd)
            label := this._GetStateLabel(record)
            this.ModifiedStateMenu.Add(label, ObjBindMethod(this, "ToggleModifiedState", id))
            if (record.Active)
                this.ModifiedStateMenu.Check(label)
        }
        A_TrayMenu.Add(this.App.ModifiedStates.Count " pinned", this.ModifiedStateMenu)
    }

    UpdatePinnedWindow(hwnd, isPinned) {
        this._UpdateModifiedState("PinnedWindow", hwnd, isPinned)
    }

    UpdatePinnedApp(hwnd, isPinned) {
        this._UpdateModifiedState("PinnedApp", hwnd, isPinned)
    }

    UpdateAlwaysOnTop(hwnd, isOnTop) {
        this._UpdateModifiedState("AlwaysOnTop", hwnd, isOnTop)
    }

    ToggleModifiedState(id, *) {
        if (this.Router = "" || !this.App.ModifiedStates.Has(id))
            return
        this.Router.ToggleTrackedState(id)
    }

    ResolveModifiedStateTarget(record) {
        if (record.Hwnd && WinExist("ahk_id " record.Hwnd)) {
            current := this._GetWindowIdentity(record.Hwnd)
            if (record.Type = "PinnedApp" ? this._SameProcess(record, current) : this._SameProcessAndClass(record, current))
                return record.Hwnd
        }

        fallbackMatches := []
        for _, hwnd in WinGetList() {
            current := this._GetWindowIdentity(hwnd)
            if (record.Type = "PinnedApp" && this._SameProcess(record, current)) {
                record.Hwnd := hwnd
                return hwnd
            }
            if (record.Type != "PinnedApp" && this._SameWindowSignature(record, current)) {
                record.Hwnd := hwnd
                return hwnd
            }
            if (record.Type != "PinnedApp" && this._SameProcessAndClass(record, current))
                fallbackMatches.Push(hwnd)
        }
        if (fallbackMatches.Length = 1) {
            record.Hwnd := fallbackMatches[1]
            return record.Hwnd
        }
        record.Hwnd := 0
        return 0
    }

    _UpdateModifiedState(type, hwnd, isEnabled) {
        if (!hwnd)
            return
        identity := this._GetWindowIdentity(hwnd)
        id := this._FindModifiedState(type, identity)
        if (isEnabled) {
            if (id = "") {
                id := this.App.NextModifiedStateId ""
                this.App.NextModifiedStateId += 1
            }
            identity.Id := id
            identity.Type := type
            identity.Active := true
            this.App.ModifiedStates[id] := identity
        } else if (id != "") {
            this.App.ModifiedStates.Delete(id)
        }
        this._SaveModifiedStates()
        this._RebuildTrayMenu()
    }

    _GetWindowIdentity(hwnd) {
        try processName := WinGetProcessName("ahk_id " hwnd)
        catch
            processName := ""
        try processPath := WinGetProcessPath("ahk_id " hwnd)
        catch
            processPath := ""
        try windowClass := WinGetClass("ahk_id " hwnd)
        catch
            windowClass := ""
        try title := WinGetTitle("ahk_id " hwnd)
        catch
            title := ""
        return {
            Hwnd: hwnd,
            ProcessName: processName,
            ProcessPath: processPath,
            WindowClass: windowClass,
            Title: title
        }
    }

    _FindModifiedState(type, identity) {
        for id, record in this.App.ModifiedStates {
            if (record.Type != type)
                continue
            if (record.Hwnd = identity.Hwnd)
                return id
            if (type = "PinnedApp" && this._SameProcess(record, identity))
                return id
            if (type != "PinnedApp" && this._SameWindowSignature(record, identity))
                return id
        }
        return ""
    }

    _SameProcess(left, right) {
        if (left.ProcessPath != "" && right.ProcessPath != "")
            return StrLower(left.ProcessPath) = StrLower(right.ProcessPath)
        return left.ProcessName != "" && StrLower(left.ProcessName) = StrLower(right.ProcessName)
    }

    _SameWindowSignature(left, right) {
        return this._SameProcessAndClass(left, right)
            && left.Title = right.Title
    }

    _SameProcessAndClass(left, right) {
        return this._SameProcess(left, right) && left.WindowClass = right.WindowClass
    }

    _IsRecordActive(record, hwnd) {
        if (!hwnd)
            return false
        try {
            switch record.Type {
                case "PinnedWindow": return !!this.Core.IsPinnedWindow(hwnd)
                case "PinnedApp": return !!this.Core.IsPinnedApp(hwnd)
                case "AlwaysOnTop": return (WinGetExStyle("ahk_id " hwnd) & 0x8) != 0
            }
        }
        return false
    }

    _GetStateLabel(record) {
        prefix := Map(
            "PinnedWindow", "[All desktops: window] ",
            "PinnedApp", "[All desktops: app] ",
            "AlwaysOnTop", "[Always on top] "
        )[record.Type]
        appName := record.ProcessName != "" ? record.ProcessName : "Unknown app"
        name := record.Type != "PinnedApp" && record.Title != "" ? appName " — " record.Title : appName
        return prefix name " (#" record.Id ")"
    }

    _LoadModifiedStates() {
        this.App.ModifiedStates := Map()
        this.App.NextModifiedStateId := 1
        if (!FileExist(this.StatePath))
            return
        try sectionsText := IniRead(this.StatePath)
        catch
            return
        for _, section in StrSplit(sectionsText, "`n", "`r") {
            if (!RegExMatch(section, "^State(\d+)$", &match))
                continue
            id := match[1]
            type := IniRead(this.StatePath, section, "Type", "")
            if !(type = "PinnedWindow" || type = "PinnedApp" || type = "AlwaysOnTop")
                continue
            record := {
                Id: id,
                Type: type,
                Hwnd: Integer(IniRead(this.StatePath, section, "Hwnd", "0")),
                ProcessName: IniRead(this.StatePath, section, "ProcessName", ""),
                ProcessPath: IniRead(this.StatePath, section, "ProcessPath", ""),
                WindowClass: IniRead(this.StatePath, section, "WindowClass", ""),
                Title: IniRead(this.StatePath, section, "Title", ""),
                Active: false
            }
            this.App.ModifiedStates[id] := record
            this.App.NextModifiedStateId := Max(this.App.NextModifiedStateId, Integer(id) + 1)
        }
    }

    _SaveModifiedStates() {
        if (FileExist(this.StatePath))
            FileDelete(this.StatePath)
        for id, record in this.App.ModifiedStates {
            section := "State" id
            IniWrite(record.Type, this.StatePath, section, "Type")
            IniWrite(record.Hwnd, this.StatePath, section, "Hwnd")
            IniWrite(record.ProcessName, this.StatePath, section, "ProcessName")
            IniWrite(record.ProcessPath, this.StatePath, section, "ProcessPath")
            IniWrite(record.WindowClass, this.StatePath, section, "WindowClass")
            IniWrite(StrReplace(record.Title, "`n", " "), this.StatePath, section, "Title")
        }
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
        VdeLogger.Dispatch(this.Logger, "tray-renderer", level, event, details)
    }
}
