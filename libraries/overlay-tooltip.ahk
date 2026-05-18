class VdeOverlayTooltip {
    __New(logger := "") {
        this.Logger := logger
        this.Token := 0
        this.Gui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner")
        this.Gui.BackColor := "1F1F1F"
        this.Gui.MarginX := 18
        this.Gui.MarginY := 12
        this.TextCtrl := this.Gui.AddText("BackgroundTrans +Center", "")
        this.TextCtrl.SetFont("s16 cFFFFFF", "Segoe UI")
        this._ApplyClickThrough(true)
        this._ApplyRoundedCorners(true)
    }

    Show(text, settings) {
        this.Token += 1
        token := this.Token

        fontSize := this._SanitizeInt(settings.TooltipsFontSize, 16, 8, 72)
        fontName := Trim(settings.TooltipsFontName)
        if (fontName = "")
            fontName := "Segoe UI"
        fontColor := this._SanitizeColor(settings.TooltipsFontColor, "FFFFFF")
        fontBold := settings.TooltipsFontInBold ? "bold" : ""
        bgColor := this._SanitizeColor(settings.TooltipsBackgroundColor, "1F1F1F")
        lifespan := this._SanitizeInt(settings.TooltipsLifespan, 750, 100, 10000)
        marginX := this._SanitizeInt(settings.TooltipsMarginX, 18, 4, 120)
        marginY := this._SanitizeInt(settings.TooltipsMarginY, 12, 4, 120)
        minWidth := this._SanitizeInt(settings.TooltipsMinWidth, 320, 120, 1200)
        minHeight := this._SanitizeInt(settings.TooltipsMinHeight, 72, 36, 400)

        this._ApplyClickThrough(settings.TooltipsClickThrough)
        this._ApplyRoundedCorners(settings.TooltipsRoundedCorners)

        this.Gui.BackColor := bgColor
        this.Gui.MarginX := marginX
        this.Gui.MarginY := marginY
        fontOpts := "s" fontSize " c" fontColor
        if (fontBold != "")
            fontOpts .= " " fontBold
        this.TextCtrl.SetFont(fontOpts, fontName)
        this.TextCtrl.Text := text

        metrics := this._MeasureText(text, fontName, fontSize, settings.TooltipsFontInBold)
        textWidth := Max(1, metrics.W + 2)
        ; Extra vertical slack avoids clipping descenders (g, j, p, q, y) in GUI text control.
        textHeight := Max(1, metrics.H + 10)

        ; Keep a stable minimum panel size, but expand if text requires more space.
        panelWidth := Max(minWidth, textWidth + (marginX * 2))
        panelHeight := Max(minHeight, textHeight + (marginY * 2))

        ; Exact centering of text inside the panel (horizontal + vertical).
        textX := (panelWidth - textWidth) // 2
        textY := (panelHeight - textHeight) // 2
        this.TextCtrl.Move(textX, textY, textWidth, textHeight)

        this._PlaceBySettings(settings, panelWidth, panelHeight)

        this._Log("DEBUG", "overlay_tooltip_show", "text=" text " lifespan_ms=" lifespan " token=" token)
        SetTimer(() => this.Hide(token), -lifespan)
    }

    Hide(token := 0) {
        if (token != 0 && token != this.Token) {
            this._Log("DEBUG", "overlay_tooltip_hide_skip", "token=" token " current_token=" this.Token)
            return
        }
        this.Gui.Hide()
        this._Log("DEBUG", "overlay_tooltip_hide", token != 0 ? "token=" token : "")
    }

    _PlaceBySettings(settings, w, h) {

        targetLeft := 0
        targetTop := 0
        targetRight := A_ScreenWidth
        targetBottom := A_ScreenHeight

        if (settings.TooltipsOnEveryMonitor) {
            vx := DllCall("user32\GetSystemMetrics", "Int", 76, "Int") ; SM_XVIRTUALSCREEN
            vy := DllCall("user32\GetSystemMetrics", "Int", 77, "Int") ; SM_YVIRTUALSCREEN
            vw := DllCall("user32\GetSystemMetrics", "Int", 78, "Int") ; SM_CXVIRTUALSCREEN
            vh := DllCall("user32\GetSystemMetrics", "Int", 79, "Int") ; SM_CYVIRTUALSCREEN
            targetLeft := vx
            targetTop := vy
            targetRight := vx + vw
            targetBottom := vy + vh
        }

        posX := StrUpper(settings.TooltipsPositionX)
        posY := StrUpper(settings.TooltipsPositionY)

        x := this._ResolveAxisX(posX, targetLeft, targetRight, w)
        y := this._ResolveAxisY(posY, targetTop, targetBottom, h)

        this.Gui.Show("NA x" x " y" y " w" w " h" h)
    }

    _MeasureText(text, fontName, fontSize, isBold) {
        hdc := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
        weight := isBold ? 700 : 400
        hFont := DllCall("gdi32\CreateFontW"
            , "Int", -fontSize
            , "Int", 0
            , "Int", 0
            , "Int", 0
            , "Int", weight
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "UInt", 1
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "WStr", fontName
            , "Ptr")
        oldFont := DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr")

        sz := Buffer(8, 0)
        DllCall("gdi32\GetTextExtentPoint32W", "Ptr", hdc, "WStr", text, "Int", StrLen(text), "Ptr", sz)
        textW := NumGet(sz, 0, "Int")
        textH := NumGet(sz, 4, "Int")

        DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", oldFont)
        DllCall("gdi32\DeleteObject", "Ptr", hFont)
        DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", hdc)

        return { W: textW, H: textH }
    }

    _ResolveAxisX(pos, left, right, width) {
        margin := 24
        if (pos = "LEFT")
            return left + margin
        if (pos = "RIGHT")
            return right - width - margin
        return left + ((right - left - width) // 2)
    }

    _ResolveAxisY(pos, top, bottom, height) {
        margin := 24
        if (pos = "TOP")
            return top + margin
        if (pos = "BOTTOM")
            return bottom - height - margin
        return top + ((bottom - top - height) // 2)
    }

    _SanitizeInt(value, fallback, min, max) {
        if (!IsInteger(value))
            return fallback
        v := Integer(value)
        if (v < min)
            return min
        if (v > max)
            return max
        return v
    }

    _SanitizeColor(value, fallback) {
        s := value
        if (SubStr(s, 1, 2) = "0x")
            s := SubStr(s, 3)
        s := StrUpper(Trim(s))
        if RegExMatch(s, "^[0-9A-F]{6}$")
            return s
        return fallback
    }

    _ApplyRoundedCorners(enabled := true) {
        try {
            attr := 33 ; DWMWA_WINDOW_CORNER_PREFERENCE
            prefRound := enabled ? 2 : 1 ; ROUND / DONOTROUND
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.Gui.Hwnd, "Int", attr, "Int*", prefRound, "Int", 4)
        }
    }

    _ApplyClickThrough(enabled := true) {
        exStyle := DllCall("user32\GetWindowLongPtr", "Ptr", this.Gui.Hwnd, "Int", -20, "Ptr")
        wsExTransparent := 0x20
        if (enabled)
            exStyle := exStyle | wsExTransparent
        else
            exStyle := exStyle & ~wsExTransparent
        DllCall("user32\SetWindowLongPtr", "Ptr", this.Gui.Hwnd, "Int", -20, "Ptr", exStyle, "Ptr")
    }

    _Log(level, event, details := "") {
        VdeLogger.Dispatch(this.Logger, "overlay-tooltip", level, event, details)
    }
}
