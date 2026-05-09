class VdeAccessorGateway {
    __New(scriptDir, appState) {
        this.ScriptDir := scriptDir
        this.App := appState
        this.DllHandle := 0
        this.Procs := Map()
        this._Load()
        this._BindAll()
    }

    _Load() {
        build := Integer(StrSplit(A_OSVersion, ".")[3])
        dllName := build >= 20000 ? "win-11.dll" : "win-10.dll"
        this.DllPath := this.ScriptDir "\\libraries\\virtual-desktop-accessor\\" dllName
        this.DllHandle := DllCall("LoadLibrary", "Str", this.DllPath, "Ptr")
        if (!this.DllHandle) {
            throw Error("Failed to load accessor DLL: " this.DllPath)
        }
    }

    _Bind(name) {
        proc := DllCall("GetProcAddress", "Ptr", this.DllHandle, "AStr", name, "Ptr")
        if (!proc) {
            throw Error("Missing accessor proc: " name)
        }
        this.Procs[name] := proc
        return proc
    }

    _BindAll() {
        for _, n in [
            "GoToDesktopNumber", "RegisterPostMessageHook", "UnregisterPostMessageHook",
            "GetCurrentDesktopNumber", "GetDesktopCount", "IsWindowOnDesktopNumber",
            "MoveWindowToDesktopNumber", "IsPinnedWindow", "PinWindow", "UnPinWindow",
            "IsPinnedApp", "PinApp", "UnPinApp"
        ] {
            this._Bind(n)
        }
    }

    RegisterDesktopSwitchHook(handlerFn) {
        DetectHiddenWindows(true)
        this.App.HookHwnd := WinExist("ahk_pid " DllCall("GetCurrentProcessId", "UInt"))
        this.App.HookHwnd += 0x1000 << 32
        DllCall(this.Procs["RegisterPostMessageHook"], "Int", this.App.HookHwnd, "Int", this.App.HookMsgId)
        OnMessage(this.App.HookMsgId, handlerFn)
    }

    GetCurrentDesktopNumber() => DllCall(this.Procs["GetCurrentDesktopNumber"]) + 1
    GetDesktopCount() => DllCall(this.Procs["GetDesktopCount"])
    GoToDesktopNumber(n) => DllCall(this.Procs["GoToDesktopNumber"], "Int", n - 1)
    IsWindowOnDesktopNumber(hwnd, n) => DllCall(this.Procs["IsWindowOnDesktopNumber"], "UInt", hwnd, "UInt", n - 1)
    MoveWindowToDesktopNumber(hwnd, n) => DllCall(this.Procs["MoveWindowToDesktopNumber"], "UInt", hwnd, "UInt", n - 1)
    IsPinnedWindow(hwnd) => DllCall(this.Procs["IsPinnedWindow"], "UInt", hwnd)
    PinWindow(hwnd) => DllCall(this.Procs["PinWindow"], "UInt", hwnd)
    UnPinWindow(hwnd) => DllCall(this.Procs["UnPinWindow"], "UInt", hwnd)
    IsPinnedApp(hwnd) => DllCall(this.Procs["IsPinnedApp"], "UInt", hwnd)
    PinApp(hwnd) => DllCall(this.Procs["PinApp"], "UInt", hwnd)
    UnPinApp(hwnd) => DllCall(this.Procs["UnPinApp"], "UInt", hwnd)
}

