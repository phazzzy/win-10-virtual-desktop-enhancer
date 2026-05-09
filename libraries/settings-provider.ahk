class VdeSettingsProvider {
    static Load(path) {
        s := Map()
        s.Path := path

        s.GeneralDefaultDesktop := this._Int(path, "General", "DefaultDesktop", 1)
        s.GeneralTaskbarScrollSwitching := this._Bool(path, "General", "TaskbarScrollSwitching", true)
        s.GeneralUseNativeDesktopSwitching := this._Bool(path, "General", "UseNativeDesktopSwitching", false)
        s.GeneralDesktopWrapping := this._Int(path, "General", "DesktopWrapping", 1)
        s.GeneralNumberOfCyclableDesktops := this._Int(path, "General", "NumberOfCyclableDesktops", 0)
        s.GeneralIconDir := this._Str(path, "General", "IconDir", "")
        s.GeneralIconDir := (s.GeneralIconDir = "") ? "icons/" : (SubStr(s.GeneralIconDir, -1) = "/" ? s.GeneralIconDir : s.GeneralIconDir "/")

        s.TooltipsEnabled := this._Bool(path, "Tooltips", "Enabled", false)
        s.TooltipsLifespan := this._Int(path, "Tooltips", "Lifespan", 750)

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

