class VdeHotkeyRegistrar {
    __New(app, settings, router, core) {
        this.App := app
        this.Settings := settings
        this.Router := router
        this.Core := core
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
                this._RegisterNumbered(this.Settings.HkModifiersSwitchNum . id, i, (n, *) => this.Router.SwitchToDesktop(n))
                this._RegisterNumbered(this.Settings.HkModifiersMoveNum . id, i, (n, *) => this.Router.MoveToDesktop(n))
                this._RegisterNumbered(this.Settings.HkModifiersMoveAndSwitchNum . id, i, (n, *) => this.Router.MoveAndSwitchToDesktop(n))
            }
        }

        this._RegisterOne(this.Settings.HkComboTogglePinWindow, this.Router.TogglePinWindow.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboTogglePinApp, this.Router.TogglePinApp.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboTogglePinOnTop, this.Router.ToggleOnTop.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboPinOnTop, this.Router.PinToTop.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboUnpinFromTop, this.Router.UnpinFromTop.Bind(this.Router))
        this._RegisterOne(this.Settings.HkComboChangeDesktopName, this.Router.ChangeDesktopName.Bind(this.Router))

        if (this.Settings.GeneralTaskbarScrollSwitching) {
            Hotkey("~WheelUp", this.Router.OnTaskbarScrollUp.Bind(this.Router))
            Hotkey("~WheelDown", this.Router.OnTaskbarScrollDown.Bind(this.Router))
        }
    }

    _RegisterNumbered(hk, n, fn) {
        if (hk = "")
            return
        this._RegisterOne(hk, (*) => fn(n))
    }

    _RegisterOne(hk, fn) {
        if (hk = "")
            return
        try Hotkey(hk, fn)
        catch {
            throw Error("Invalid hotkey mapping: " hk)
        }
    }
}

