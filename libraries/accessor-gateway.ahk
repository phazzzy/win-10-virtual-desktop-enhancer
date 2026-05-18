class VdeAccessorGateway {
    __New(scriptDir, appState, logger := "") {
        this.ScriptDir := scriptDir
        this.App := appState
        this.Logger := logger
        this.DllHandle := 0
        this.Procs := Map()
        this.IsAvailable := false
        this._Load()
        if (this.IsAvailable)
            this._BindAll()
    }

    _Load() {
        build := Integer(StrSplit(A_OSVersion, ".")[3])
        dllName := build >= 20000 ? "win-11.dll" : "win-10.dll"
        this.DllPath := this.ScriptDir "\\libraries\\virtual-desktop-accessor\\" dllName
        this._Log("INFO", "gateway_load_begin", "build=" build " path=" this.DllPath)
        this.DllHandle := DllCall("LoadLibrary", "Str", this.DllPath, "Ptr")
        if (!this.DllHandle) {
            this.IsAvailable := false
            this._Log("ERROR", "gateway_load_failed", "path=" this.DllPath)
            return
        }
        this.IsAvailable := true
        this._Log("INFO", "gateway_load_ok")
    }

    _Bind(name) {
        if (!this.IsAvailable)
            return 0
        proc := DllCall("GetProcAddress", "Ptr", this.DllHandle, "AStr", name, "Ptr")
        if (!proc) {
            this.IsAvailable := false
            this._Log("ERROR", "gateway_bind_missing_proc", name)
            return 0
        }
        this.Procs[name] := proc
        this._Log("DEBUG", "gateway_bind_ok", name)
        return proc
    }

    _BindAll() {
        for _, n in [
            "GoToDesktopNumber", "RegisterPostMessageHook", "UnregisterPostMessageHook",
            "GetCurrentDesktopNumber", "GetDesktopCount", "IsWindowOnDesktopNumber",
            "MoveWindowToDesktopNumber", "IsPinnedWindow", "PinWindow", "UnPinWindow",
            "IsPinnedApp", "PinApp", "UnPinApp"
        ] {
            if (!this._Bind(n)) {
                this._Log("ERROR", "gateway_bindall_failed", n)
                return
            }
        }
        this.IsAvailable := true
        this._Log("INFO", "gateway_bindall_ok")
    }

    RegisterDesktopSwitchHook(handlerFn) {
        if (!this.IsAvailable) {
            this._Log("WARN", "hook_skipped_gateway_unavailable")
            return false
        }
        DetectHiddenWindows(true)
        this.App.HookHwnd := WinExist("ahk_pid " DllCall("GetCurrentProcessId", "UInt"))
        this.App.HookHwnd += 0x1000 << 32
        DllCall(this.Procs["RegisterPostMessageHook"], "Int", this.App.HookHwnd, "Int", this.App.HookMsgId)
        OnMessage(this.App.HookMsgId, handlerFn)
        this._Log("INFO", "hook_registered", "msg=" this.App.HookMsgId)
        return true
    }

    GetCurrentDesktopNumber() => this.IsAvailable ? (DllCall(this.Procs["GetCurrentDesktopNumber"]) + 1) : 1
    GetDesktopCount() => this.IsAvailable ? DllCall(this.Procs["GetDesktopCount"]) : 1
    GoToDesktopNumber(n) => this.IsAvailable ? DllCall(this.Procs["GoToDesktopNumber"], "Int", n - 1) : 0
    IsWindowOnDesktopNumber(hwnd, n) => this.IsAvailable ? DllCall(this.Procs["IsWindowOnDesktopNumber"], "UInt", hwnd, "UInt", n - 1) : 0
    MoveWindowToDesktopNumber(hwnd, n) => this.IsAvailable ? DllCall(this.Procs["MoveWindowToDesktopNumber"], "UInt", hwnd, "UInt", n - 1) : 0
    IsPinnedWindow(hwnd) => this.IsAvailable ? DllCall(this.Procs["IsPinnedWindow"], "UInt", hwnd) : 0
    PinWindow(hwnd) => this.IsAvailable ? DllCall(this.Procs["PinWindow"], "UInt", hwnd) : 0
    UnPinWindow(hwnd) => this.IsAvailable ? DllCall(this.Procs["UnPinWindow"], "UInt", hwnd) : 0
    IsPinnedApp(hwnd) => this.IsAvailable ? DllCall(this.Procs["IsPinnedApp"], "UInt", hwnd) : 0
    PinApp(hwnd) => this.IsAvailable ? DllCall(this.Procs["PinApp"], "UInt", hwnd) : 0
    UnPinApp(hwnd) => this.IsAvailable ? DllCall(this.Procs["UnPinApp"], "UInt", hwnd) : 0

    _Log(level, event, details := "") {
        VdeLogger.Dispatch(this.Logger, "accessor-gateway", level, event, details)
    }
}
