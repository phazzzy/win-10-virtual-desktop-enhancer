class VdeSettingsToggleService {
    __New(settings, logger := "") {
        this.Settings := settings
        this.Logger := logger
    }

    Toggle(settingKey) {
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
            case "Tooltips":
                this.Settings.TooltipsEnabled := !this.Settings.TooltipsEnabled
                VdeSettingsProvider.SaveBool(this.Settings, "Tooltips", "Enabled", this.Settings.TooltipsEnabled)
            default:
                return false
        }
        return true
    }
}

