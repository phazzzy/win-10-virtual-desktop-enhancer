class VdeAppState {
    __New() {
        this.IsDisabled := false
        this.TaskbarIds := []
        this.CurrentDesktopNo := 0
        this.PreviousDesktopNo := 0
        this.DoFocusAfterNextSwitch := false
        this.NumberedHotkeys := Map()
        this.HotkeyToAction := Map()
        this.DesktopMenuItems := Map()
        this.DesktopNames := Map()
        this.NumDesktops := 0
        this.InitialDesktopNo := 0
        this.ChangeDesktopNamesPopupTitle := "Windows 10 Virtual Desktop Enhancer"
        this.ChangeDesktopNamesPopupText := "Change the desktop name of desktop #{:d}"
        this.HookMsgId := 0x1400 + 30
        this.HookHwnd := 0
    }
}

