class VdeHotkeyRegistrar {
    __New(app, settings, router, core, logger := "") {
        this.App := app
        this.Settings := settings
        this.Router := router
        this.Core := core
        this.Logger := logger
    }

    RegisterAll() {
        this._RegisterOne(this.Settings.HkModifiersSwitchDir . this.Settings.HkIdentifierPrevious, this.Router.OnShiftLeftPress.Bind(this.Router))
        this._RegisterOne(this.Settings.HkModifiersSwitchDir . this.Settings.HkIdentifierNext, this.Router.OnShiftRightPress.Bind(this.Router))
        this._RegisterOne(this.Settings.HkModifiersSwitchDir . this.Settings.HkIdentifierLastActive, this.Router.OnShiftLastActivePress.Bind(this.Router))

        this._RegisterOne(this.Settings.HkModifiersMoveDir . this.Settings.HkIdentifierPrevious, this.Router.OnMoveLeftPress.Bind(this.Router))
        this._RegisterOne(this.Settings.HkModifiersMoveDir . this.Settings.HkIdentifierNext, this.Router.OnMoveRightPress.Bind(this.Router))
        this._RegisterOne(this.Settings.HkModifiersMoveDir . this.Settings.HkIdentifierLastActive, this.Router.OnMoveLastActivePress.Bind(this.Router))

        this._RegisterOne(this.Settings.HkModifiersMoveAndSwitchDir . this.Settings.HkIdentifierPrevious, this.Router.OnMoveAndShiftLeftPress.Bind(this.Router))
        this._RegisterOne(this.Settings.HkModifiersMoveAndSwitchDir . this.Settings.HkIdentifierNext, this.Router.OnMoveAndShiftRightPress.Bind(this.Router))
        this._RegisterOne(this.Settings.HkModifiersMoveAndSwitchDir . this.Settings.HkIdentifierLastActive, this.Router.OnMoveAndShiftLastActivePress.Bind(this.Router))

        Loop 9 {
            i := A_Index
            for _, id in [this.Settings.DesktopIdentifiers[i], this.Settings.DesktopAltIdentifiers[i]] {
                for _, normalizedId in this._ExpandNumberedIdentifierVariants(id)
                    this._RegisterNumbered(this.Settings.HkModifiersSwitchNum . normalizedId, i)
            }
        }

        this._RegisterOne(this.Settings.HkComboTogglePinWindow, this.Router.TogglePinWindow.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboTogglePinApp, this.Router.TogglePinApp.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboTogglePinOnTop, this.Router.ToggleOnTop.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboPinOnTop, this.Router.PinToTop.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboUnpinFromTop, this.Router.UnpinFromTop.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboChangeDesktopName, this.Router.ChangeDesktopName.Bind(this.Router))

        if (this.Settings.GeneralTaskbarScrollSwitching) {
            HotIf((*) => this._CanHandleWheelHotkeyContext())
            Hotkey("WheelUp", this.Router.OnTaskbarScrollUp.Bind(this.Router))
            Hotkey("WheelDown", this.Router.OnTaskbarScrollDown.Bind(this.Router))
            HotIf()
        }
    }

    _RegisterNumbered(hk, n) {
        if (hk = "")
            return
        this._RegisterOne("*" hk, (*) => this._HandleNumberedDesktopHotkey(n, hk))
    }

    _HandleNumberedDesktopHotkey(n, hk) {
        shiftPressed := GetKeyState("Shift", "P")
        this._Log("DEBUG", "numbered_hotkey_pressed", "hotkey=" hk " target=" n " shiftPressed=" (shiftPressed ? "1" : "0"))
        if (shiftPressed)
            this.Router.MoveAndSwitchToDesktop(n)
        else
            this.Router.SwitchToDesktop(n)
    }

    _ExpandNumberedIdentifierVariants(id) {
        variants := []
        if (id = "")
            return variants

        variants.Push(id)

        numpadMap := Map(
            "Numpad1", "NumpadEnd",
            "Numpad2", "NumpadDown",
            "Numpad3", "NumpadPgDn",
            "Numpad4", "NumpadLeft",
            "Numpad5", "NumpadClear",
            "Numpad6", "NumpadRight",
            "Numpad7", "NumpadHome",
            "Numpad8", "NumpadUp",
            "Numpad9", "NumpadPgUp"
        )

        if (numpadMap.Has(id)) {
            altId := numpadMap[id]
            variants.Push(altId)
            this._Log("DEBUG", "numbered_hotkey_variant_added", "source=" id " variant=" altId)
        }

        return variants
    }

    _RegisterOne(hk, fn) {
        if (hk = "")
            return
        try {
            Hotkey(hk, fn)
            this._Log("DEBUG", "hotkey_registered", hk)
        } catch as err {
            this._Log("ERROR", "hotkey_invalid", hk " | " err.Message)
        }
    }

    _CanHandleWheelHotkeyContext() {
        if (this.App.IsDisabled || !this.Settings.GeneralTaskbarScrollSwitching)
            return false
        return this.Core.IsCursorHoveringTaskbar()
    }

    _Log(level, event, details := "") {
        if (this.Logger = "")
            return
        if (level = "ERROR")
            this.Logger.Error("hotkey-registrar", event, details)
        else if (level = "WARN")
            this.Logger.Warn("hotkey-registrar", event, details)
        else if (level = "DEBUG")
            this.Logger.Debug("hotkey-registrar", event, details)
        else
            this.Logger.Info("hotkey-registrar", event, details)
    }
}
