#SingleInstance, force
#WinActivateForce
#HotkeyInterval 20
#MaxHotkeysPerInterval 20000
#MenuMaskKey vk07
#UseHook

; Credits to Ciantic: https://github.com/Ciantic/VirtualDesktopAccessor
; Credits to Scott McKay for windows 11 fixes: https://github.com/skottmckay/VirtualDesktopAccessor

#Include, %A_ScriptDir%\libraries\read-ini.ahk
#Include, %A_ScriptDir%\libraries\tooltip.ahk
#Include, %A_ScriptDir%\libraries\core.ahk


; ======================================================================
; Set Up Library Hooks
; ======================================================================

DetectHiddenWindows, On
hwnd := WinExist("ahk_pid " . DllCall("GetCurrentProcessId","Uint"))
hwnd += 0x1000 << 32

versionParts := StrSplit(A_OSVersion, ".")
buildNumber := versionParts[3] ; 19045 — win 10. 20000 — win 11
virtualDesktopAccessorDll := buildNumber >= 20000 ? "win-11.dll" : "win-10.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", A_ScriptDir . "\libraries\virtual-desktop-accessor\" . virtualDesktopAccessorDll, "Ptr")

global GoToDesktopNumberProc					:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GoToDesktopNumber", "Ptr")
global RegisterPostMessageHookProc				:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "RegisterPostMessageHook", "Ptr")
global UnregisterPostMessageHookProc			:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnregisterPostMessageHook", "Ptr")
global GetCurrentDesktopNumberProc				:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetCurrentDesktopNumber", "Ptr")
global GetDesktopCountProc						:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetDesktopCount", "Ptr")
global IsWindowOnDesktopNumberProc				:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsWindowOnDesktopNumber", "Ptr")
global MoveWindowToDesktopNumberProc			:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "MoveWindowToDesktopNumber", "Ptr")
global IsPinnedWindowProc						:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsPinnedWindow", "Ptr")
global PinWindowProc							:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "PinWindow", "Ptr")
global UnPinWindowProc							:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnPinWindow", "Ptr")
global IsPinnedAppProc							:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsPinnedApp", "Ptr")
global PinAppProc								:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "PinApp", "Ptr")
global UnPinAppProc								:= DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnPinApp", "Ptr")

DllCall(RegisterPostMessageHookProc, Int, hwnd, Int, 0x1400 + 30)
OnMessage(0x1400 + 30, "VWMess")
VWMess(wParam, lParam, msg, hwnd) {
	OnDesktopSwitch(lParam + 1)
}


; ======================================================================
; Auto Execute
; ======================================================================

; Read and groom settings

ReadIni("settings.ini")

global GeneralDesktopWrapping					:= (GeneralDesktopWrapping != "" and GeneralDesktopWrapping ~= "^[01]$") ? GeneralDesktopWrapping : 1
global GeneralNumberOfCyclableDesktops			:= GeneralNumberOfCyclableDesktops >= 1 ? GeneralNumberOfCyclableDesktops : 0
global GeneralUseNativeDesktopSwitching			:= (GeneralUseNativeDesktopSwitching ~= "^[01]$" && GeneralUseNativeDesktopSwitching == "1" ? true : false)
global GeneralIconDir							:= GeneralIconDir == "" ? "icons/" : GeneralIconDir ~= "/$" ? GeneralIconDir : GeneralIconDir . "/"
global TooltipsEnabled							:= (TooltipsEnabled != "" and TooltipsEnabled ~= "^[01]$") ? TooltipsEnabled : 1
global TooltipsLifespan							:= (TooltipsLifespan != "" and TooltipsLifespan ~= "^\d+$") ? TooltipsLifespan : 750
global TooltipsPositionX						:= (TooltipsPositionX == "LEFT" or TooltipsPositionX == "CENTER" or TooltipsPositionX == "RIGHT") ? TooltipsPositionX : "CENTER"
global TooltipsPositionY						:= (TooltipsPositionY == "TOP" or TooltipsPositionY == "CENTER" or TooltipsPositionY == "BOTTOM") ? TooltipsPositionY : "CENTER"
global TooltipsOnEveryMonitor					:= (TooltipsOnEveryMonitor != "" and TooltipsOnEveryMonitor ~= "^[01]$") ? TooltipsOnEveryMonitor : 1
global TooltipsFontSize							:= (TooltipsFontSize != "" and TooltipsFontSize ~= "^\d+$") ? TooltipsFontSize : 11
global TooltipsFontInBold						:= (TooltipsFontInBold != "" and TooltipsFontInBold ~= "^[01]$") ? (TooltipsFontInBold ? 700 : 400) : 700
global TooltipsFontColor						:= (TooltipsFontColor != "" and TooltipsFontColor ~= "^0x[0-9A-Fa-f]{1,6}$") ? TooltipsFontColor : "0xFFFFFF"
global TooltipsBackgroundColor					:= (TooltipsBackgroundColor != "" and TooltipsBackgroundColor ~= "^0x[0-9A-Fa-f]{1,6}$") ? TooltipsBackgroundColor : "0x1F1F1F"

global isDisabled								:= 0
global TaskbarIDs								:= []
global TaskbarEdges								:= []
global currentDesktopNo							:= 0
global previousDesktopNo						:= 0
global doFocusAfterNextSwitch					:= 0
global numberedHotkeys							:= {}
global changeDesktopNamesPopupTitle				:= "Windows 10 Virtual Desktop Enhancer"
global changeDesktopNamesPopupText				:= "Change the desktop name of desktop #{:d}"
global numDesktops								:= _GetNumberOfDesktops()
global initialDesktopNo							:= _GetCurrentDesktopNumber()


; ======================================================================
; Set up tray tray menu
; ======================================================================

Menu, Tray, NoStandard
Menu, Tray, Click, 1
Menu, Tray, Add, Reload
Menu, Tray, Default, Reload
Menu, Tray, Add, Disable keys, DisableScript

Menu, Tray, Add ; separator

Loop, %numDesktops% {
	name := _GetDesktopName(A_Index)
	switchTo := Func("SwitchToDesktop").Bind(A_Index)
	Menu, Tray, Add, %name%, % SwitchTo, +Radio
	if (initialDesktopNo == A_Index) {
		Menu, Tray, Check, %name%
	}
}

Menu, Tray, Add ; separator

Menu, ScriptMenu, Add, Open in explorer, OpenExplorer
Menu, ScriptMenu, Add, Edit script, EditScript
Menu, ScriptMenu, Add, Edit config, EditConfig

Menu, ScriptMenu, Add ; separator

Menu, ScriptMenu, Add, Exit, ExitScript

Menu, Tray, Add, Script, :ScriptMenu

Reload() {
	Reload
}

ExitScript() {
	ExitApp
}

DisableScript() {
	isDisabled := isDisabled ? false : true
	Menu, Tray, Togglecheck, Disable keys
	_ShowTooltip(if isDisabled ? "Disabled" : "Enabled")
}

EditConfig() {
    ; Run, notepad.exe "%A_ScriptDir%\settings.ini"
    Run, % "rundll32.exe shell32.dll,ShellExec_RunDLL " A_ScriptDir "\settings.ini"
}

EditScript() {
    Run, notepad.exe "%A_ScriptDir%\virtual-desktop-enhancer.ahk"
}

OpenExplorer() {
	Run explorer.exe "%A_ScriptDir%"
}


; ======================================================================
; Initialize
; ======================================================================

if (GeneralDefaultDesktop != "" && GeneralDefaultDesktop > 0 && GeneralDefaultDesktop != initialDesktopNo) {
	SwitchToDesktop(GeneralDefaultDesktop)
} else {
	; Call "OnDesktopSwitch" since it wouldn't be called otherwise
	OnDesktopSwitch(initialDesktopNo)
}


; ======================================================================
; Set Up Key Bindings
; ======================================================================

; Translate the modifier keys strings

global hkModifiersSwitchNum						:= KeyboardShortcutsModifiersSwitchDesktopNum
global hkModifiersMoveNum						:= KeyboardShortcutsModifiersMoveWindowToDesktopNum
global hkModifiersMoveAndSwitchNum				:= KeyboardShortcutsModifiersMoveWindowAndSwitchToDesktopNum
global hkModifiersSwitchDir						:= KeyboardShortcutsModifiersSwitchDesktopDir
global hkModifiersMoveDir						:= KeyboardShortcutsModifiersMoveWindowToDesktopDir
global hkModifiersMoveAndSwitchDir				:= KeyboardShortcutsModifiersMoveWindowAndSwitchToDesktopDir
global hkIdentifierPrevious						:= KeyboardShortcutsIdentifiersPreviousDesktop
global hkIdentifierNext							:= KeyboardShortcutsIdentifiersNextDesktop
global hkIdentifierLastActive					:= KeyboardShortcutsIdentifiersLastActiveDesktop
global hkComboPinWin							:= KeyboardShortcutsCombinationsPinWindow
global hkComboUnpinWin							:= KeyboardShortcutsCombinationsUnpinWindow
global hkComboTogglePinWin						:= KeyboardShortcutsCombinationsTogglePinWindow
global hkComboPinApp							:= KeyboardShortcutsCombinationsPinApp
global hkComboUnpinApp							:= KeyboardShortcutsCombinationsUnpinApp
global hkComboTogglePinOnTopWin					:= KeyboardShortcutsCombinationsTogglePinOnTop
global hkComboPinOnTopApp						:= KeyboardShortcutsCombinationsPinOnTop
global hkComboUnpinFromTop						:= KeyboardShortcutsCombinationsUnpinFromTop
global hkComboTogglePinApp						:= KeyboardShortcutsCombinationsTogglePinApp
global hkComboOpenDesktopManager				:= KeyboardShortcutsCombinationsOpenDesktopManager
global hkComboChangeDesktopName					:= KeyboardShortcutsCombinationsChangeDesktopName

arrayS := Object(),								arrayR := Object()
arrayS.Insert("\s*|,"),							arrayR.Insert("")
arrayS.Insert("L(Ctrl|Shift|Alt|Win)"),			arrayR.Insert("<$1")
arrayS.Insert("R(Ctrl|Shift|Alt|Win)"),			arrayR.Insert(">$1")
arrayS.Insert("Ctrl"),							arrayR.Insert("^")
arrayS.Insert("Shift"),							arrayR.Insert("+")
arrayS.Insert("Alt"),							arrayR.Insert("!")
arrayS.Insert("Win"),							arrayR.Insert("#")

for index in arrayS {
	hkModifiersSwitchNum						:= RegExReplace(hkModifiersSwitchNum, arrayS[index], arrayR[index])
	hkModifiersMoveNum							:= RegExReplace(hkModifiersMoveNum, arrayS[index], arrayR[index])
	hkModifiersMoveAndSwitchNum					:= RegExReplace(hkModifiersMoveAndSwitchNum, arrayS[index], arrayR[index])
	hkModifiersSwitchDir						:= RegExReplace(hkModifiersSwitchDir, arrayS[index], arrayR[index])
	hkModifiersMoveDir							:= RegExReplace(hkModifiersMoveDir, arrayS[index], arrayR[index])
	hkModifiersMoveAndSwitchDir					:= RegExReplace(hkModifiersMoveAndSwitchDir, arrayS[index], arrayR[index])
	hkComboPinWin								:= RegExReplace(hkComboPinWin, arrayS[index], arrayR[index])
	hkComboUnpinWin								:= RegExReplace(hkComboUnpinWin, arrayS[index], arrayR[index])
	hkComboTogglePinWin							:= RegExReplace(hkComboTogglePinWin, arrayS[index], arrayR[index])
	hkComboPinApp								:= RegExReplace(hkComboPinApp, arrayS[index], arrayR[index])
	hkComboUnpinApp								:= RegExReplace(hkComboUnpinApp, arrayS[index], arrayR[index])
	hkComboTogglePinApp							:= RegExReplace(hkComboTogglePinApp, arrayS[index], arrayR[index])
	hkComboPinOnTopApp							:= RegExReplace(hkComboPinOnTopApp, arrayS[index], arrayR[index])
	hkComboUnpinFromTop							:= RegExReplace(hkComboUnpinFromTop, arrayS[index], arrayR[index])
	hkComboTogglePinOnTopWin					:= RegExReplace(hkComboTogglePinOnTopWin, arrayS[index], arrayR[index])
	hkComboOpenDesktopManager					:= RegExReplace(hkComboOpenDesktopManager, arrayS[index], arrayR[index])
	hkComboChangeDesktopName					:= RegExReplace(hkComboChangeDesktopName, arrayS[index], arrayR[index])
}

; Setup key bindings dynamically
;  If they are set incorrectly in the settings, an error will be thrown.

_setUpHotkey(hk, handler, settingPaths, n := 0) {
	Hotkey, %hk%, %handler%, UseErrorLevel
	if (ErrorLevel <> 0) {
		MsgBox, 16, Error, %hk%, %handler%, `n`nOne or more keyboard shortcut settings have been defined incorrectly in the settings file: `n%settingPaths%. `n`nPlease read the README for instructions.
		Exit
	}
	if (n) {
		numberedHotkeys[hk] := n
	}
}

_setUpHotkeyWithOneSetOfModifiersAndIdentifier(modifiers, identifier, handler, settingPaths, n := 0) {
	modifiers <> "" && identifier <> "" ? _setUpHotkey(modifiers . identifier, handler, settingPaths, n) :
}

_setUpHotkeyWithTwoSetOfModifiersAndIdentifier(modifiersA, modifiersB, identifier, handler, settingPaths, n := 0) {
	modifiersA <> "" && modifiersB <> "" && identifier <> "" ? _setUpHotkey(modifiersA . modifiersB . identifier, handler, settingPaths, n) :
}

_setUpHotkeyWithCombo(combo, handler, settingPaths) {
	combo <> "" ? _setUpHotkey(combo, handler, settingPaths) :
}

_IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierNextOrPrevious) {
	return ((hkModifiersSwitch == "<#<^" || hkModifiersSwitch == ">#<^" || hkModifiersSwitch == "#<^" || hkModifiersSwitch == "<#>^" || hkModifiersSwitch == ">#>^" || hkModifiersSwitch == "#>^" || hkModifiersSwitch == "<#^" || hkModifiersSwitch == ">#^" || hkModifiersSwitch == "#^") && (hkIdentifierNextOrPrevious == "Left" || hkIdentifierNextOrPrevious == "Right"))
}

_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitchDir, hkIdentifierLastActive, "OnShiftLastActivePress", "[KeyboardShortcutsModifiers] SwitchDesktopDir, [KeyboardShortcutsIdentifiers] LastActiveDesktop")

_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveDir, hkIdentifierPrevious, "OnMoveLeftPress", "[KeyboardShortcutsModifiers] MoveWindowToDesktopDir, [KeyboardShortcutsIdentifiers] PreviousDesktop")
_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveDir, hkIdentifierNext, "OnMoveRightPress", "[KeyboardShortcutsModifiers] MoveWindowToDesktopDir, [KeyboardShortcutsIdentifiers] NextDesktop")
_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveDir, hkIdentifierLastActive, "OnMoveLastActivePress", "[KeyboardShortcutsModifiers] MoveWindowToDesktopNum, [KeyboardShortcutsIdentifiers] LastActiveDesktop")

_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitchDir, hkIdentifierPrevious, "OnMoveAndShiftLeftPress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktopDir, [KeyboardShortcutsIdentifiers] PreviousDesktop")
_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitchDir, hkIdentifierNext, "OnMoveAndShiftRightPress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktopDir, [KeyboardShortcutsIdentifiers] NextDesktop")
_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitchDir, hkIdentifierLastActive, "OnMoveAndShiftLastActivePress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktopNum, [KeyboardShortcutsIdentifiers] LastActiveDesktop")

_setUpHotkeyWithCombo(hkComboPinWin, "OnPinWindowPress", "[KeyboardShortcutsCombinations] PinWindow")
_setUpHotkeyWithCombo(hkComboUnpinWin, "OnUnpinWindowPress", "[KeyboardShortcutsCombinations] UnpinWindow")
_setUpHotkeyWithCombo(hkComboTogglePinWin, "OnTogglePinWindowPress", "[KeyboardShortcutsCombinations] TogglePinWindow")

_setUpHotkeyWithCombo(hkComboPinApp, "OnPinAppPress", "[KeyboardShortcutsCombinations] PinApp")
_setUpHotkeyWithCombo(hkComboUnpinApp, "OnUnpinAppPress", "[KeyboardShortcutsCombinations] UnpinApp")
_setUpHotkeyWithCombo(hkComboTogglePinApp, "OnTogglePinAppPress", "[KeyboardShortcutsCombinations] TogglePinApp")

_setUpHotkeyWithCombo(hkComboPinOnTopApp, "PinToTop", "[KeyboardShortcutsCombinations] PinToTop")
_setUpHotkeyWithCombo(hkComboUnpinFromTop, "UnpinFromTop", "[KeyboardShortcutsCombinations] UnpinFromTop")
_setUpHotkeyWithCombo(hkComboTogglePinOnTopWin, "ToggleOnTop", "[KeyboardShortcutsCombinations] ToggleOnTop")

_setUpHotkeyWithCombo(hkComboChangeDesktopName, "ChangeDesktopName", "[KeyboardShortcutsCombinations] ChangeDesktopName")

i := 1
maxDesktops := Max(numDesktops, 9)
while (i <= maxDesktops) {
	hkDesktopI0 := KeyboardShortcutsIdentifiersDesktop%i%
	hkDesktopI1 := KeyboardShortcutsIdentifiersDesktopAlt%i%
	j := 0
	while (j < 2) {
		hkDesktopI := hkDesktopI%j%
		_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitchNum, hkDesktopI, "OnShiftNumberedPress", "[KeyboardShortcutsModifiers] SwitchDesktopNum", i)
		_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveNum, hkDesktopI, "OnMoveNumberedPress", "[KeyboardShortcutsModifiers] MoveWindowToDesktopNum", i)
		_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitchNum, hkDesktopI, "OnMoveAndShiftNumberedPress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktopNum", i)
		j := j + 1
	}
	i := i + 1
}

if (!(GeneralUseNativeDesktopSwitching && _IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitchDir, hkIdentifierPrevious))) {
	_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitchDir, hkIdentifierPrevious, "OnShiftLeftPress", "[KeyboardShortcutsModifiers] SwitchDesktopDir, [KeyboardShortcutsIdentifiers] PreviousDesktop")
}

if (!(GeneralUseNativeDesktopSwitching && _IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitchDir, hkIdentifierNext))) {
	_setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitchDir, hkIdentifierNext, "OnShiftRightPress", "[KeyboardShortcutsModifiers] SwitchDesktopDir, [KeyboardShortcutsIdentifiers] NextDesktop")
}

if (GeneralTaskbarScrollSwitching) {
	Hotkey, ~WheelUp, OnTaskbarScrollUp
	Hotkey, ~WheelDown, OnTaskbarScrollDown
}


; ======================================================================
; Event Handlers
; ======================================================================


OnShiftLastActivePress() {
	if (!isDisabled) {
		SwitchToDesktop(previousDesktopNo)
	}
}

OnMoveLastActivePress() {
	if (!isDisabled) {
		MoveToDesktop(previousDesktopNo)
	}
}

OnMoveAndShiftLastActivePress() {
	if (!isDisabled) {
		MoveAndSwitchToDesktop(previousDesktopNo)
	}
}

OnShiftNumberedPress() {
	if (!isDisabled) {
		n := numberedHotkeys[A_ThisHotkey]
		if (n) {
			SwitchToDesktop(n)
		}
	}
}

OnMoveNumberedPress() {
	if (!isDisabled) {
		n := numberedHotkeys[A_ThisHotkey]
		if (n) {
			MoveToDesktop(n)
		}
	}
}

OnMoveAndShiftNumberedPress() {
	if (!isDisabled) {
		n := numberedHotkeys[A_ThisHotkey]
		if (n) {
			MoveAndSwitchToDesktop(n)
		}
	}
}

OnShiftLeftPress() {
	if (!isDisabled) {
		SwitchToDesktop(_GetPreviousDesktopNumber())
	}
}

OnShiftRightPress() {
	if (!isDisabled) {
		SwitchToDesktop(_GetNextDesktopNumber())
	}
}

OnMoveLeftPress() {
	if (!isDisabled) {
		MoveToDesktop(_GetPreviousDesktopNumber())
	}
}

OnMoveRightPress() {
	if (!isDisabled) {
		MoveToDesktop(_GetNextDesktopNumber())
	}
}

OnMoveAndShiftLeftPress() {
	if (!isDisabled) {
		MoveAndSwitchToDesktop(_GetPreviousDesktopNumber())
	}
}

OnMoveAndShiftRightPress() {
	if (!isDisabled) {
		MoveAndSwitchToDesktop(_GetNextDesktopNumber())
	}
}

OnTaskbarScrollUp() {
	if (!isDisabled && _IsCursorHoveringTaskbar()) {
		OnShiftLeftPress()
	}
}

OnTaskbarScrollDown() {
	if (!isDisabled && _IsCursorHoveringTaskbar()) {
		OnShiftRightPress()
	}
}

OnPinWindowPress() {
	if (!isDisabled) {
		windowID := _GetCurrentWindowID()
		windowTitle := _GetCurrentWindowTitle()
		_PinWindow(windowID)
		_ShowTooltipForPinnedWindow(windowTitle)
	}
}

OnUnpinWindowPress() {
	if (!isDisabled) {
		windowID := _GetCurrentWindowID()
		windowTitle := _GetCurrentWindowTitle()
		_UnpinWindow(windowID)
		_ShowTooltipForUnpinnedWindow(windowTitle)
	}
}

OnTogglePinWindowPress() {
	if (!isDisabled) {
		windowID := _GetCurrentWindowID()
		windowTitle := _GetCurrentWindowTitle()
		if (_GetIsWindowPinned(windowID)) {
			_UnpinWindow(windowID)
			_ShowTooltipForUnpinnedWindow(windowTitle)
		} else {
			_PinWindow(windowID)
			_ShowTooltipForPinnedWindow(windowTitle)
		}
	}
}

OnPinAppPress() {
	if (!isDisabled) {
		windowID := _GetCurrentWindowID()
		windowTitle := _GetCurrentWindowTitle()
		_PinApp()
		_ShowTooltipForPinnedApp(windowTitle)
	}
}

OnUnpinAppPress() {
	if (!isDisabled) {
		windowID := _GetCurrentWindowID()
		windowTitle := _GetCurrentWindowTitle()
		_UnpinApp()
		_ShowTooltipForUnpinnedApp(windowTitle)
	}
}

OnTogglePinAppPress() {
	if (!isDisabled) {
		windowID := _GetCurrentWindowID()
		windowTitle := _GetCurrentWindowTitle()
		if (_GetIsAppPinned(windowID)) {
			_UnpinApp(windowID)
			_ShowTooltipForUnpinnedApp(windowTitle)
		} else {
			_PinApp(windowID)
			_ShowTooltipForPinnedApp(windowTitle)
		}
	}
}

OnDesktopSwitch(n := 1) {
	if (!isDisabled) {
		; Give focus first, then display the popup, otherwise the popup could
		; steal the focus from the legitimate window until it disappears.
		_FocusIfRequested()
		if (TooltipsEnabled) {
			_ShowTooltipForDesktopSwitch(n)
		}
		_ChangeAppearance(n)
		_ChangeBackground(n)

		if (currentDesktopNo) {
			_RunProgramWhenSwitchingFromDesktop(currentDesktopNo)
		}
		_RunProgramWhenSwitchingToDesktop(n)
		previousDesktopNo := currentDesktopNo
		currentDesktopNo := n
	}
}


; ======================================================================
; Functions
; ======================================================================

SwitchToDesktop(n := 1) {
	if (!isDisabled) {
		doFocusAfterNextSwitch = 1
		_ChangeDesktop(n)
	}
}

MoveToDesktop(n := 1) {
	if (!isDisabled) {
		_MoveCurrentWindowToDesktop(n)
		_Focus()
	}
}

MoveAndSwitchToDesktop(n := 1) {
	if (!isDisabled) {
		doFocusAfterNextSwitch = 1
		_MoveCurrentWindowToDesktop(n)
		_ChangeDesktop(n)
	}
}

OpenDesktopManager() {
	if (!isDisabled) {
		Send #{Tab}
	}
}

; Let the user change desktop names with a prompt, without having to edit the 'settings.ini'
; file and reload the program.
; The changes are temprorary (names will be overwritten by the default values of
; 'settings.ini' when the program will be restarted.
ChangeDesktopName() {
	if (!isDisabled) {
		currentDesktopNumber := _GetCurrentDesktopNumber()
		currentDesktopName := _GetDesktopName(currentDesktopNumber)
		InputBox, newDesktopName, % changeDesktopNamesPopupTitle, % Format(changeDesktopNamesPopupText, _GetCurrentDesktopNumber()), , , , , , , , %currentDesktopName%
		; If the user choose "Cancel" ErrorLevel is set to 1.
		if (ErrorLevel == 0) {
			_SetDesktopName(currentDesktopNumber, newDesktopName)
		}
		_ChangeAppearance(currentDesktopNumber)
	}
}

ToggleOnTop() {
	if (!isDisabled) {
		WinGet, windowStyle, ExStyle, A
		Winset, Alwaysontop, , A

		WinGetTitle, activeWindow, A
		_ShowTooltip((if (windowStyle & 0x8) ? "Unpin from top `n" : "Pin to top `n") . activeWindow)
	}
}

PinToTop() {
	if (!isDisabled) {
		Winset, Alwaysontop, On, A
		WinGetTitle, activeWindow, A
		_ShowTooltip("Pin to top `n" . activeWindow)
	}
}

UnpinFromTop() {
	if (!isDisabled) {
		Winset, Alwaysontop, Off, A
		WinGetTitle, activeWindow, A
		_ShowTooltip("Unpin from top `n" . activeWindow)
	}
}
