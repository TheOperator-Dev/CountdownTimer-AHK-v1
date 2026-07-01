#SingleInstance Off
SetBatchLines, -1

; Create unique identifier for this instance
global InstanceID := A_TickCount

; If no other Countdown Timer window exists, reset the temp tracking files
; (handles stale files left behind by a crashed/killed previous instance)
AnyExisting := False
Loop, 99 {
    testTitle := "Countdown Timer #" . Format("{:02d}", A_Index)
    IfWinExist, %testTitle%
    {
        AnyExisting := True
        break
    }
}
if (!AnyExisting) {
    FileDelete, %A_Temp%\CountdownTimerCounter.txt
    FileDelete, %A_Temp%\CountdownTimerActive.txt
}

; Sequential counter for display
global InstanceCounter := 0
if (!FileExist(A_Temp . "\CountdownTimerCounter.txt")) {
    FileAppend, 0, %A_Temp%\CountdownTimerCounter.txt
}
FileRead, InstanceCounter, %A_Temp%\CountdownTimerCounter.txt
InstanceCounter++
if (InstanceCounter > 99)
    InstanceCounter := 1
FileDelete, %A_Temp%\CountdownTimerCounter.txt
FileAppend, %InstanceCounter%, %A_Temp%\CountdownTimerCounter.txt

; Track active instances
FileRead, ActiveCount, %A_Temp%\CountdownTimerActive.txt
if (ActiveCount = "") {
    ActiveCount := 0
}
ActiveCount++
FileDelete, %A_Temp%\CountdownTimerActive.txt
FileAppend, %ActiveCount%, %A_Temp%\CountdownTimerActive.txt

global TotalSeconds := 0
global RemainingSeconds := 0
global IsRunning := False
global IsPaused := False
global IsMinimized := False

; Create icon from base64
CreateIconFromBase64()

; Dark mode colors
Gui, Color, 1E1E1E, 2D2D30
Gui, Font, s9 cEEEEEE, Segoe UI

; --- Quick preset buttons (5-30 minutes) ---
Gui, Add, Text, x7 y3 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 5
Gui, Add, Text, x56 y3 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 10
Gui, Add, Text, x105 y3 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 15
Gui, Add, Text, x154 y3 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 20
Gui, Add, Text, x203 y3 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 25
Gui, Add, Text, x252 y3 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 30

; --- Quick preset buttons (35-60 minutes) ---
Gui, Add, Text, x7 y25 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 35
Gui, Add, Text, x56 y25 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 40
Gui, Add, Text, x105 y25 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 45
Gui, Add, Text, x154 y25 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 50
Gui, Add, Text, x203 y25 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 55
Gui, Add, Text, x252 y25 w47 h20 gSetPreset Background000000 cEEEEEE Center +0x200 +Border, 60

; --- Time input fields with Enter hotkey ---
Gui, Add, Edit, x7 y48 w21 h20 vHours Number Background2D2D30 cEEEEEE gCheckEnter
Gui, Add, Text, x30 y52 w10 h20 cEEEEEE, H
Gui, Add, Edit, x42 y48 w21 h20 vMinutes Number Background2D2D30 cEEEEEE gCheckEnter
Gui, Add, Text, x64 y52 w15 h20 cEEEEEE, M
Gui, Add, Edit, x80 y48 w21 h20 vSeconds Number Background2D2D30 cEEEEEE gCheckEnter
Gui, Add, Text, x102 y52 w10 h20 cEEEEEE, S

; --- Control buttons ---
Gui, Add, Text, x112 y47 w50 h23 gStartTimer Background000000 cEEEEEE Center +0x200 +Border, START
Gui, Add, Text, x165 y47 w73 h23 gPauseTimer vPauseButton Background000000 cEEEEEE Center +0x200 +Border, PAUSE
Gui, Add, Text, x241 y47 w53 h23 gCancelTimer Background000000 cEEEEEE Center +0x200 +Border, RESET

; --- Time display ---
Gui, Font, s35 cEEEEEE, DSEG7 Classic-Italic
Gui, Add, Text, x10 y75 w280 h120 Center vTimeDisplay Background1E1E1E, 00:00:00

; --- Progress bar ---
Gui, Font, s10 Normal
Gui, Add, Progress, x3 y135 w297 h20 vProgressBar Range0-100 Background2D2D30 c007ACC

; Window dimensions
GuiWidth := 305
GuiHeight := 165

; Get work area bounds (taskbar excluded)
SysGet, Mon, MonitorWorkArea

; --- Smart tiling: find the best position next to existing instances ---
bestX := MonLeft
bestY := MonTop
found := False

maxX := MonLeft
maxY := MonTop
rowY := MonTop   

; Enumerate existing windows and figure out the rightmost position in each row
winCount := 0
Loop, 99 {
    testTitle := "Countdown Timer #" . Format("{:02d}", A_Index)
    IfWinExist, %testTitle%
    {
        WinGetPos, wx, wy, ww, wh, %testTitle%
        winCount++
        wX%winCount% := wx
        wY%winCount% := wy
        wR%winCount% := wx + ww
        wB%winCount% := wy + wh
    }
}

if (winCount = 0) {
    ; No existing windows — place near mouse cursor
    CoordMode, Mouse, Screen
    MouseGetPos, MouseX, MouseY
    newX := MouseX + 10
    newY := MouseY - GuiHeight - 40
} else {
    ; Find the best tiling position:
    lowestRowY := MonTop
    Loop, %winCount% {
        if (wY%A_Index% > lowestRowY)
            lowestRowY := wY%A_Index%
    }

    lowestBottom := 0
    Loop, %winCount% {
        if (wB%A_Index% > lowestBottom)
            lowestBottom := wB%A_Index%
    }

    rightmostX := MonLeft
    Loop, %winCount% {
        if (wY%A_Index% = lowestRowY && wR%A_Index% > rightmostX)
            rightmostX := wR%A_Index%
    }

    candidateX := rightmostX + 2   ; 2px gap
    candidateY := lowestRowY

    if (candidateX + GuiWidth <= MonRight) {
        newX := candidateX
        newY := candidateY
    } else {
        newX := MonLeft
        newY := lowestBottom + 2   ; 2px gap below
    }
}

; Safety clamp
if (newX + GuiWidth > MonRight)
    newX := MonRight - GuiWidth
if (newY + GuiHeight > MonBottom)
    newY := MonBottom - GuiHeight
if (newX < MonLeft)
    newX := MonLeft
if (newY < MonTop)
    newY := MonTop

; Use sequential 2-digit number in title
GuiTitle := "Countdown Timer #" . Format("{:02d}", InstanceCounter)
Gui, Show, x%newX% y%newY% w%GuiWidth% h%GuiHeight%, %GuiTitle%

GuiControl, Focus, TimeDisplay

Menu, Tray, NoStandard
Menu, Tray, Add, Open, OpenWindow
Menu, Tray, Add, Exit, GuiClose
Menu, Tray, Default, Open
Menu, Tray, Click, 1
Menu, Tray, Tip, Countdown Timer

SetWindowIcon()
return

; --- Handles all preset button logic dynamically ---
SetPreset:
    PresetMinutes := A_GuiControl
    GuiControl,, Hours, 0
    GuiControl,, Minutes, %PresetMinutes%
    GuiControl,, Seconds, 0
    InitializeTimer(PresetMinutes * 60)
    GoSub, StartTimer
return

InitializeTimer(seconds) {
    global TotalSeconds, RemainingSeconds, IsRunning, IsPaused

    if (IsRunning && !IsPaused) {
        return
    }

    TotalSeconds := seconds
    RemainingSeconds := seconds
    IsPaused := False
    UpdateDisplay()
}

CreateIconFromBase64() {
    global hIcon
    base64 := "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAAXNSR0IArs4c6QAAAAlwSFlzAAAuIwAALiMBeKU/dgAAALRQTFRFR3BMAAAAdXV1T09PX19fPj4+REREt7e3AQEBTk5ONTU1Ozs7AAAAAAAAIiIiWVlZIiIiMzMzMzMzJiYmFhYWPDw8Ly8vFxcXDQ0NAQEBBAQENzc3////AAAAysrKxcXFqKiovLy8lJSU8PDwi4uL09PT7Ozstra2/Pz89/f3ra2tsLCwpaWlU1NTmZmZFxcX1tbW39/fz8/PKCgof39/wMDAXV1dd3d3Z2dn6Ojon5+fQUFBl7FIhwAAABx0Uk5TAOsKNRVpRgPhHJV40vGcK/L4upJkW9O1wq7KwMItcvwAAAFGSURBVHjaZZHnloIwEEZBpLPWtW4mTYr0FbCg7/9eGyJs8/7JnLnJnMz5lG+m89lsYSovmFoJsBbi1eilZSuvjA0HVF3782SkKfZShXme1+Dp5ng6zFisXbUuCBawBrbuTH8K+8OBporouaERJeRhOY7yRAdeZSeEcItikgS51c8aW9cgr1AP96t68hROKe7jvn8gQZSAJv9k+ewT9SSiSqvHshMaMHpEktjnojox3zOFWJUkku2WX65xp1OqjoV4n+OrNHeAbmTIefRmd6LG9NAJDJdQHMcTTaUwgCRI0kqPwqiwRkLYbzRt0S8Ivu2Ujk1epSjsu8cwzgispDAgYQ3rRcz94OaNFMkECD2LBdpYbF7gAowhj215JhkOC9yyLCjA/UlvAz4mUZYwzC6yP2C6Ktx4dvdz2Bv/Itd3nmrtJ8YQ+hcT5C3dOxVg6AAAAABJRU5ErkJggg=="
    nBytes := Base64ToBinary(base64, pBinary)
    
    if (nBytes > 0) {
        hIcon := DllCall("CreateIconFromResourceEx", "Ptr", pBinary, "UInt", nBytes, "Int", 1, "UInt", 0x30000, "Int", 16, "Int", 16, "UInt", 0, "Ptr")
        DllCall("GlobalFree", "Ptr", pBinary)
    }
}

Base64ToBinary(base64, ByRef pBinary) {
    nBytes := Floor(StrLen(base64) * 3 / 4)
    pBinary := DllCall("GlobalAlloc", "UInt", 0x40, "Ptr", nBytes, "Ptr")
    VarSetCapacity(size, 4, 0)
    result := DllCall("Crypt32\CryptStringToBinary", "Str", base64, "UInt", 0, "UInt", 1, "Ptr", pBinary, "UInt*", nBytes, "Ptr", 0, "Ptr", 0)
    
    if (!result) {
        DllCall("GlobalFree", "Ptr", pBinary)
        return 0
    }
    return nBytes
}

SetWindowIcon() {
    global hIcon, InstanceCounter
    
    if (hIcon) {
        GuiTitle := "Countdown Timer #" . Format("{:02d}", InstanceCounter)
        SendMessage, 0x80, 0, hIcon,, %GuiTitle%  ; WM_SETICON, ICON_SMALL
        SendMessage, 0x80, 1, hIcon,, %GuiTitle%  ; WM_SETICON, ICON_LARGE
        Menu, Tray, Icon, HICON:*%hIcon%
    }
}

CheckEnter:
    if (A_GuiEvent = "Normal") {
        return
    }
return

#IfWinActive, Countdown Timer
~Enter::
~NumpadEnter::
    GuiControlGet, focusedControl, FocusV
    if (focusedControl = "Hours" || focusedControl = "Minutes" || focusedControl = "Seconds") {
        GoSub, StartTimer
        GuiControl, Focus, TimeDisplay
    }
return

; Prevent text selection on double click
~LButton::
    KeyWait, LButton
    KeyWait, LButton, D T0.3
    if (!ErrorLevel) {
        Send, {Esc}
        Clipboard := ""
    }
return
#IfWinActive

StartTimer:
    global IsRunning, IsPaused, RemainingSeconds

    Gui, Submit, NoHide
    h := Hours != "" ? Hours : 0
    m := Minutes != "" ? Minutes : 0
    s := Seconds != "" ? Seconds : 0
    totalSec := (h * 3600) + (m * 60) + s

    if (totalSec > 0) {
        SetTimer, CountDown, Off
        IsRunning := False
        IsPaused := False
        InitializeTimer(totalSec)
        GuiControl,, PauseButton, PAUSE
    }

    if (RemainingSeconds <= 0) {
        GuiControl, Focus, TimeDisplay
        return
    }

    if (IsPaused) {
        IsPaused := False
        IsRunning := True
        SetTimer, CountDown, 1000
        GuiControl, Focus, TimeDisplay
        return
    }

    if (!IsRunning) {
        IsRunning := True
        SetTimer, CountDown, 1000
    }

    GuiControl, Focus, TimeDisplay
return

PauseTimer:
    global IsRunning, IsPaused

    if (!IsRunning)
        return

    IsPaused := !IsPaused

    if (IsPaused) {
        SetTimer, CountDown, Off
        GuiControl,, PauseButton, CONTINUE
    } else {
        SetTimer, CountDown, 1000
        GuiControl,, PauseButton, PAUSE
    }
return

CancelTimer:
    global IsRunning, IsPaused, RemainingSeconds, TotalSeconds

    SetTimer, CountDown, Off
    IsRunning := False
    IsPaused := False
    RemainingSeconds := 0
    TotalSeconds := 0

    GuiControl,, Hours,
    GuiControl,, Minutes,
    GuiControl,, Seconds,
    GuiControl,, ProgressBar, 0
    GuiControl,, TimeDisplay, 00:00:00
    GuiControl,, PauseButton, PAUSE
return

CountDown:
    global RemainingSeconds, IsRunning, IsPaused, InstanceCounter

    if (IsPaused || !IsRunning)
        return

    RemainingSeconds--
    UpdateDisplay()

    if (RemainingSeconds <= 0) {
        SetTimer, CountDown, Off
        IsRunning := False
        SoundBeep, 2100, 250
        Sleep, 10
        SoundBeep, 2100, 250
        Sleep, 1500
        SoundBeep, 2100, 250
        Sleep, 10
        SoundBeep, 2100, 250
        Sleep, 1500
        SoundBeep, 2100, 250
        Sleep, 10
        SoundBeep, 2100, 250
        GuiControl,, ProgressBar, 100
        GuiControl,, PauseButton, PAUSE

        global IsMinimized
        if (IsMinimized) {
            GuiTitle := "Countdown Timer #" . Format("{:02d}", InstanceCounter)
            WinGet, hwnd, ID, %GuiTitle%
            DllCall("ShowWindow", "UInt", hwnd, "Int", 6)
            IsMinimized := False
        }

        GuiTitle := "Countdown Timer #" . Format("{:02d}", InstanceCounter)
        WinGet, hwnd, ID, %GuiTitle%
        DllCall("FlashWindow", "UInt", hwnd, "Int", 1)
    }
return

UpdateDisplay() {
    global RemainingSeconds, TotalSeconds, IsMinimized

    hours := Floor(RemainingSeconds / 3600)
    mins := Floor(Mod(RemainingSeconds, 3600) / 60)
    secs := Mod(RemainingSeconds, 60)

    timeStr := Format("{:02d}:{:02d}:{:02d}", hours, mins, secs)
    GuiControl,, TimeDisplay, %timeStr%

    Menu, Tray, Tip, Countdown Timer - %timeStr%

    if (TotalSeconds > 0) {
        progress := Round(((TotalSeconds - RemainingSeconds) / TotalSeconds) * 100)
        GuiControl,, ProgressBar, %progress%
    }
}

OpenWindow:
    global IsMinimized
    Gui, Show
    IsMinimized := False
return

GuiSize:
    global IsMinimized
    if (A_EventInfo = 1) {  ; 1 = minimized
        Gui, Hide
        IsMinimized := True
        return
    }
return

GuiClose:
    ; Decrement active instance count
    global InstanceCounter, hIcon
    FileRead, ActiveCount, %A_Temp%\CountdownTimerActive.txt
    if (ActiveCount = "") {
        ActiveCount := 0
    }
    ActiveCount--
    if (ActiveCount <= 0) {
        ; Reset counter if this was the last instance
        FileDelete, %A_Temp%\CountdownTimerCounter.txt
        FileDelete, %A_Temp%\CountdownTimerActive.txt
    } else {
        FileDelete, %A_Temp%\CountdownTimerActive.txt
        FileAppend, %ActiveCount%, %A_Temp%\CountdownTimerActive.txt
    }

    ; Destroy icon handle
    if (hIcon)
        DllCall("DestroyIcon", "Ptr", hIcon)

    ExitApp
return
