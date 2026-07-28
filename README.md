<div align="center">

<img src="art/icon/Icon-1024.png" alt="AutoClicker Pro" width="220"/>

# AutoClicker Pro

A high-precision auto clicker for macOS built with **Swift** and **SwiftUI**.

Designed for users who require accurate scheduled clicking with millisecond-level countdowns and optional SNTP time synchronization.

</div>

---

## Features

- 🎯 Target Time Mode
- ⏱ Delay Start Mode
- 🌐 SNTP/NTP Time Synchronization
- ⚡ High-Precision DispatchSourceTimer Scheduling
- ⌛ Millisecond Countdown Display
- 🖱 Mouse & Keyboard Automation
- 🔁 Configurable Click Interval
- 🔢 Configurable Click Count
- ⌨ Global Keyboard Shortcuts
- 📌 Keep Window on Top
- 💾 Automatically Saves Settings
- 🎨 Modern SwiftUI Interface
- 🌍 Multi-language Support

---

## What's New

### Target Time Mode

Schedule clicking at an exact time.

Example:

```
15:00:00.000
```

Perfect for appointments, ticket sales and other time-sensitive tasks.

---

### High Precision Timer

AutoClicker Pro uses **DispatchSourceTimer** instead of a standard `Timer` for improved scheduling accuracy.

---

### SNTP Time Synchronization

Synchronize with public NTP servers including:

- time.apple.com
- time.cloudflare.com
- pool.ntp.org

Automatically measures:

- Clock Offset
- Round Trip Delay
- Synchronization Status

If synchronization fails, AutoClicker Pro automatically falls back to the local system clock.

---

## Requirements

- macOS 13 Ventura or later
- Accessibility permission

---

## Installation

Clone the repository:

```bash
git clone https://github.com/almost109/AutoClicker-Pro.git
```

Open:

```
AutoClicker Pro.xcodeproj
```

Build and run with Xcode.

---

## Permissions

AutoClicker Pro requires:

- Accessibility permission

Grant permission under:

```
System Settings
→ Privacy & Security
→ Accessibility
```

---

## Tech Stack

- Swift
- SwiftUI
- DispatchSourceTimer
- Network Framework (SNTP)
- Defaults
- KeyboardShortcuts

---

## Project Structure

```
AutoClicker Pro

├── DelayTimer
├── AutoClickSimulator
├── SNTPService
├── NotificationService
├── PermissionsService
├── MenuBarService
└── LoggerService
```

---

## Roadmap

### Completed

- Delay Mode
- Target Time Mode
- High Precision Timer
- DispatchSourceTimer Refactor
- Millisecond Countdown
- SNTP Time Synchronization

### Planned

- Network Time Display
- Clock Offset Display
- Click Accuracy Log
- Synchronization Status UI

---

## License

Distributed under the MIT License.

See the LICENSE file for details.

---

## Acknowledgements

This project was originally based on the open-source project:

https://github.com/othyn/macos-auto-clicker

AutoClicker Pro has since been extended with new features and architectural improvements, including high-precision scheduling and SNTP time synchronization.

---

<div align="center">

Built with ❤️ using Swift & SwiftUI

</div>
