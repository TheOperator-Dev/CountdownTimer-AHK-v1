# CountdownTimer-AHK-v1

# ⏳ Multi-Instance Countdown Timer for Windows

A lightweight and visually SIMPLE multi-instance countdown timer built using **AutoHotkey (v1)**. Designed with dark theme and smart window tiling, it allows you to run and view multiple independent timers simultaneously without them overlapping or cluttering your workspace.

---

## ✨ Features

* **Multi-Instance Support:** Open as many individual timer windows as you need. Each window automatically keeps track of its own countdown state.
* **Smart Auto-Tiling Layout:** * The first instance spawns contextually near your mouse cursor for immediate accessibility.
  * Subsequent instances automatically scan your desktop for existing timer windows and neatly tile themselves to the right or wrap into a new row below with a clean 2px padding grid.
* **Persistent Instance Tracking:** Dynamically handle sequential window numbering (e.g., `CountdownTimer #01`, `#02`).
* **Quick Presets:** Includes 12 pre-configured quick buttons (ranging from 5 to 60 minutes in 5-minute increments) that immediately initialize and fire up the timer with a single click.
* **Granular Manual Inputs:** Dedicated input boxes for Hours (H), Minutes (M), and Seconds (S) that accept numeric inputs and respond to the `Enter` / `NumpadEnter` hotkeys for keyboard-driven control.
* **Polished Dark UI & Visual Assets:**
  * Clean, distraction-free dark interface featuring a high-contrast digital clock display.
  * Integrated custom tray icon embedded directly inside the script as a Base64-decoded binary resource.
  * Real-time progress bar rendering status using native Windows components.
**System Integration:** Flashes the window taskbar and delivers rhythmic acoustic signals (`SoundBeep`) upon countdown completion. Supports automatic background minification to the Windows System Tray.

---

## 🚀 Installation & Setup

### Prerequisites
To run or edit this script, you must have **AutoHotkey v1.1+** installed on your Windows machine.
* Download it from the [Official AutoHotkey Website](https://www.autohotkey.com/).

### Running the Script
1. Clone or download this repository, or copy the script content into a blank text file.
2. Save the file with an `.ahk` extension (e.g., `Timer.ahk`).
3. Double-click `Timer.ahk` to launch an instance. Double-click it again to spawn a perfectly aligned adjacent instance!

---

## 🕹️ How to Use

### 1. Setting a Quick Timer
Click any of the numbered black blocks at the top (`5`, `10`, `15` ... `60`). The timer will instantly set its duration to that amount of minutes and start ticking down.

### 2. Manual Custom Entry
1. Click into or focus on the **H**, **M**, or **S** fields.
2. Type your desired duration.
3. Hit `Enter` on your keyboard, or click the **START** button.

### 3. Controls
* **START:** Begins counting down from your configured inputs.
* **PAUSE / CONTINUE:** Toggles execution state. The button label dynamically flips to guide your next action.
* **RESET:** Wipes the current countdown state, clears input text boxes, and drops the progress bar back to `0`.

### 4. System Tray Behavior
* Minimizing a timer window automatically moves it into the taskbar system tray to reduce clutter.
* Right-click the system tray icon to access the context menu (**Open** or **Exit**).
* Single-click or double-click the tray icon to quickly bring that specific window back into view.

---

## 📝 License
This project is open-source and free to use or modify for personal and commercial workflows.
