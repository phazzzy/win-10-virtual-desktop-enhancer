class VdeSettingsProvider {
    static Load(path) {
        s := Map()
        s.Path := path

        s.AppVersion := this._Str(path, "App", "Version", "0.0.0")

        s.GeneralDefaultDesktop := this._Int(path, "General", "DefaultDesktop", 1)
        s.GeneralTaskbarScrollSwitching := this._Bool(path, "General", "TaskbarScrollSwitching", true)
        s.GeneralTaskbarScrollBottomEdgeOnly := this._Bool(path, "General", "TaskbarScrollBottomEdgeOnly", false)
        s.GeneralUseNativeDesktopSwitching := this._Bool(path, "General", "UseNativeDesktopSwitching", false)
        s.GeneralDesktopWrapping := this._Int(path, "General", "DesktopWrapping", 1)
        s.GeneralNumberOfCyclableDesktops := this._Int(path, "General", "NumberOfCyclableDesktops", 0)
        s.GeneralIconDir := this._Str(path, "General", "IconDir", "")
        s.GeneralIconDir := (s.GeneralIconDir = "") ? "icons/" : (SubStr(s.GeneralIconDir, -1) = "/" ? s.GeneralIconDir : s.GeneralIconDir "/")
        s.GeneralHotkeyBurstTuningEnabled := this._Bool(path, "General", "HotkeyBurstTuningEnabled", true)
        s.GeneralMaxHotkeysPerInterval := this._Int(path, "General", "MaxHotkeysPerInterval", 140)
        s.GeneralHotkeyIntervalMs := this._Int(path, "General", "HotkeyIntervalMs", 1000)

        s.DebugEnabled := this._Bool(path, "Debug", "Enabled", false)
        s.DebugVerbose := this._Bool(path, "Debug", "Verbose", false)

        s.TooltipsEnabled := this._Bool(path, "Tooltips", "Enabled", false)
        s.TooltipsLifespan := this._Int(path, "Tooltips", "Lifespan", 750)
        s.TooltipsPositionX := this._Str(path, "Tooltips", "PositionX", "CENTER")
        s.TooltipsPositionY := this._Str(path, "Tooltips", "PositionY", "CENTER")
        s.TooltipsFontSize := this._Int(path, "Tooltips", "FontSize", 16)
        s.TooltipsFontName := this._Str(path, "Tooltips", "FontName", "Segoe UI")
        s.TooltipsFontColor := this._Str(path, "Tooltips", "FontColor", "0xFFFFFF")
        s.TooltipsFontInBold := this._Bool(path, "Tooltips", "FontInBold", false)
        s.TooltipsBackgroundColor := this._Str(path, "Tooltips", "BackgroundColor", "0x1F1F1F")
        s.TooltipsOnEveryMonitor := this._Bool(path, "Tooltips", "OnEveryMonitor", true)
        s.TooltipsMarginX := this._Int(path, "Tooltips", "MarginX", 18)
        s.TooltipsMarginY := this._Int(path, "Tooltips", "MarginY", 12)
        s.TooltipsClickThrough := this._Bool(path, "Tooltips", "ClickThrough", true)
        s.TooltipsRoundedCorners := this._Bool(path, "Tooltips", "RoundedCorners", true)
        s.TooltipsMinWidth := this._Int(path, "Tooltips", "MinWidth", 320)
        s.TooltipsMinHeight := this._Int(path, "Tooltips", "MinHeight", 72)

        s.HkModifiersSwitchNum := this._NormMods(this._Str(path, "KeyboardShortcutsModifiers", "SwitchDesktopNum", ""))
        s.HkModifiersMoveNum := this._NormMods(this._Str(path, "KeyboardShortcutsModifiers", "MoveWindowToDesktopNum", ""))
        s.HkModifiersMoveAndSwitchNum := this._NormMods(this._Str(path, "KeyboardShortcutsModifiers", "MoveWindowAndSwitchToDesktopNum", ""))
        s.HkModifiersSwitchDir := this._NormMods(this._Str(path, "KeyboardShortcutsModifiers", "SwitchDesktopDir", ""))
        s.HkModifiersMoveDir := this._NormMods(this._Str(path, "KeyboardShortcutsModifiers", "MoveWindowToDesktopDir", ""))
        s.HkModifiersMoveAndSwitchDir := this._NormMods(this._Str(path, "KeyboardShortcutsModifiers", "MoveWindowAndSwitchToDesktopDir", ""))

        s.HkIdentifierPrevious := this._Str(path, "KeyboardShortcutsIdentifiers", "PreviousDesktop", "Left")
        s.HkIdentifierNext := this._Str(path, "KeyboardShortcutsIdentifiers", "NextDesktop", "Right")
        s.HkIdentifierLastActive := this._Str(path, "KeyboardShortcutsIdentifiers", "LastActiveDesktop", "Numpad0")

        s.HkComboTogglePinWindow := this._NormMods(this._Str(path, "KeyboardShortcutsCombinations", "TogglePinWindow", ""))
        s.HkComboTogglePinApp := this._NormMods(this._Str(path, "KeyboardShortcutsCombinations", "TogglePinApp", ""))
        s.HkComboTogglePinOnTop := this._NormMods(this._Str(path, "KeyboardShortcutsCombinations", "TogglePinOnTop", ""))
        s.HkComboPinOnTop := this._NormMods(this._Str(path, "KeyboardShortcutsCombinations", "PinOnTop", ""))
        s.HkComboUnpinFromTop := this._NormMods(this._Str(path, "KeyboardShortcutsCombinations", "UnpinFromTop", ""))
        s.HkComboChangeDesktopName := this._NormMods(this._Str(path, "KeyboardShortcutsCombinations", "ChangeDesktopName", ""))

        s.DesktopIdentifiers := Map()
        s.DesktopAltIdentifiers := Map()
        s.DesktopNames := Map()
        s.Icons := Map()
        s.SwitchToProgram := Map()
        s.SwitchFromProgram := Map()
        Loop 9 {
            i := A_Index
            s.DesktopIdentifiers[i] := this._Str(path, "KeyboardShortcutsIdentifiers", "Desktop" i, i "")
            s.DesktopAltIdentifiers[i] := this._Str(path, "KeyboardShortcutsIdentifiers", "DesktopAlt" i, "Numpad" i)
            s.DesktopNames[i] := this._Str(path, "DesktopNames", i "", "")
            s.Icons[i] := this._Str(path, "Icons", i "", "")
            s.SwitchToProgram[i] := this._Str(path, "RunProgramWhenSwitchingToDesktop", i "", "")
            s.SwitchFromProgram[i] := this._Str(path, "RunProgramWhenSwitchingFromDesktop", i "", "")
        }
        return s
    }

    static SaveBool(settings, sec, key, value) {
        normalized := value ? 1 : 0
        IniWrite(normalized, settings.Path, sec, key)
    }

    static SaveInt(settings, sec, key, value) {
        IniWrite(Integer(value), settings.Path, sec, key)
    }

    static _Str(path, sec, key, def := "") {
        try v := IniRead(path, sec, key, def)
        catch
            v := def
        return Trim(v)
    }
    static _Int(path, sec, key, def := 0) {
        v := this._Str(path, sec, key, def)
        return IsInteger(v) ? Integer(v) : def
    }
    static _Bool(path, sec, key, def := false) {
        v := this._Str(path, sec, key, def ? "1" : "0")
        return v = "1"
    }
    static _NormMods(text) {
        out := RegExReplace(text, "\s*|,", "")
        out := RegExReplace(out, "LCtrl", "<Ctrl")
        out := RegExReplace(out, "RCtrl", ">Ctrl")
        out := RegExReplace(out, "LShift", "<Shift")
        out := RegExReplace(out, "RShift", ">Shift")
        out := RegExReplace(out, "LAlt", "<Alt")
        out := RegExReplace(out, "RAlt", ">Alt")
        out := RegExReplace(out, "LWin", "<Win")
        out := RegExReplace(out, "RWin", ">Win")
        out := StrReplace(out, "Ctrl", "^")
        out := StrReplace(out, "Shift", "+")
        out := StrReplace(out, "Alt", "!")
        out := StrReplace(out, "Win", "#")
        return out
    }
}
