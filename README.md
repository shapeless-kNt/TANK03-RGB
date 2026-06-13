# TANK03 RGB Controller

ACEMAGIC looked at your TANK03 and apparently decided that every reboot deserved a free christmas tree, a full RGB reminder that your machine has opinions.

I got you covered.

**TANK03 RGB Controller** is a tiny native Windows tray utility written in Assembly for controlling the RGB lighting modes of the ACEMAGIC TANK03. It keeps the useful part of the original RGB control workflow, removes the bloat, and adds the one thing that should probably have been there from the beginning: boot persistence.

This project is based on my first minimal tool for turning the RGB off:

[https://github.com/shapeless-kNt/M1A_TANK_03-RGB_OFF](https://github.com/shapeless-kNt/M1A_TANK_03-RGB_OFF)

That first version still does its dirty job perfectly.  
This version goes further: it can read the current hardware mode, change all RGB modes like the bundled ACEMAGIC software, remember your choice, and reapply it automatically at boot with a very low memory footprint.

## What it does

- Lives silently in the Windows system tray.
- Lets you switch the TANK03 RGB mode between:
  - AUTO
  - OFF
  - RAINBOW
  - BREATHING
  - COLOR CYCLE
- Shows the current physical performance knob state:
  - SILENT
  - AUTO
  - PERFORMANCE
  - UNKNOWN, when the value cannot be read
- Can persist your selected RGB mode across reboots.
- Can enable or disable boot persistence from the tray menu.
- Stores the selected RGB mode in the current user's registry.
- Uses the standard Windows startup registry key when boot persistence is enabled.
- Uses a tiny dynamic tray icon to show RGB and power status.
- Avoids the usual heavyweight GUI stack.
- Keeps memory usage extremely low compared with typical vendor utilities.

## Why this exists

The bundled ACEMAGIC RGB tool can control the lighting, but it is not exactly what I would call elegant, minimal, or considerate.

The original `RGB_OFF` script solved the most urgent problem: stop the machine from turning into a desk lamp. This utility keeps that spirit but turns it into a proper tray controller.

The goal is simple:

- keep the RGB under control
- keep the selected mode after reboot
- keep the software small
- keep the system clean
- avoid running a bloated vendor utility at every boot just to set a byte in the embedded controller

## How it works

The TANK03 RGB mode is controlled through the embedded controller using the same low-level mechanism used by the original ACEMAGIC tool.

The utility writes the RGB mode value to the EC register used by the vendor software and reads the hardware power mode from the EC register used to display the physical knob state.

The program is written as a small native Windows tray application, with no .NET runtime, no browser UI, and no background service.

## Boot persistence

When boot persistence is enabled, the utility adds itself to:

`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`

The selected RGB mode is saved under:

`HKCU\Software\Tank03RgbTray`

At startup, the program reloads the saved mode and applies it again.

This means that if ACEMAGIC wants your TANK03 to stay as a christmas tree, this tool politely disagrees before you have to look at it for too long.

## Requirements

- Windows
- ACEMAGIC TANK03 or compatible hardware
- `inpoutx64` driver available as `\\.\inpoutx64`

Without the low-level driver, the utility cannot access the embedded controller.

## Notes

This is not a generic RGB controller.  
It is specifically made around the behavior observed on the TANK03 and the same EC control path used by the original vendor software.

The utility intentionally stays small and direct. It does not try to be a full hardware management suite, because that is how a simple RGB switch becomes a 400 MB "control center" with three services and a login screen.

## HASHES

| Algorithm | Hash | Path |
|---|---|---|
| SHA256 | `BFE0E85FC93BFEF4F371A5128253EA28162F7FEAB27BF40DDAF0A420B83B7BC0` | `BUILD.BAT` |
| SHA256 | `94C046E8C9C02C1573D5669B13CE00A51FE56C2E9E79A6B72113B6C73FE48B94` | `TANKRGB.EXE` |
| SHA256 | `3F6E38162451B965C0E639E95BBDEC2113B21003C65ED7953F3A4E1470EDFFD5` | `TANKRGB.S` |
|
