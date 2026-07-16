class VdeSettingsValidator {
    static Validate(settings, logger := "") {
        this._ClampInt(settings, "GeneralTaskbarAntiFlickerRefreshDebounceMs", 90, 20, 2000, logger)
        this._ClampInt(settings, "GeneralTaskbarAntiFlickerRefreshSecondPhaseMs", 180, 20, 5000, logger)
        this._ClampInt(settings, "GeneralMaxHotkeysPerInterval", 140, 0, 1000, logger)
        this._ClampInt(settings, "GeneralHotkeyIntervalMs", 1000, 0, 60000, logger)
        this._ClampInt(settings, "DefaultDesktopNumber", 1, 1, 9, logger)
        this._ClampInt(settings, "TooltipsLifespan", 750, 100, 10000, logger)
        this._ClampInt(settings, "TooltipsFontSize", 16, 8, 72, logger)
        this._ClampInt(settings, "TooltipsMarginX", 18, 4, 120, logger)
        this._ClampInt(settings, "TooltipsMarginY", 12, 4, 120, logger)
        this._ClampInt(settings, "TooltipsMinWidth", 320, 120, 1200, logger)
        this._ClampInt(settings, "TooltipsMinHeight", 72, 36, 400, logger)

        this._EnumUpper(settings, "TooltipsPositionX", "CENTER", Map("LEFT", 1, "CENTER", 1, "RIGHT", 1), logger)
        this._EnumUpper(settings, "TooltipsPositionY", "CENTER", Map("TOP", 1, "CENTER", 1, "BOTTOM", 1), logger)
    }

    static _ClampInt(settings, key, fallback, minValue, maxValue, logger) {
        value := settings.%key%
        if (!IsInteger(value))
            value := fallback
        value := Integer(value)
        normalized := Max(minValue, Min(maxValue, value))
        if (normalized != settings.%key%)
            this._Warn(logger, "settings_normalized", key "=" normalized)
        settings.%key% := normalized
    }

    static _EnumUpper(settings, key, fallback, allowed, logger) {
        value := StrUpper(Trim(settings.%key%))
        if (!allowed.Has(value)) {
            value := fallback
            this._Warn(logger, "settings_normalized", key "=" value)
        }
        settings.%key% := value
    }

    static _Warn(logger, event, details := "") {
        VdeLogger.Dispatch(logger, "settings-validator", "WARN", event, details)
    }
}
