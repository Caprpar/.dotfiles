#!/usr/bin/env python3
"""Clear the XKB Caps Lock state without changing the keyboard mapping."""

import ctypes


x11 = ctypes.CDLL("libX11.so.6")
x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XkbLockModifiers.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_uint, ctypes.c_uint]
x11.XkbLockModifiers.restype = ctypes.c_int
x11.XCloseDisplay.argtypes = [ctypes.c_void_p]

display = x11.XOpenDisplay(None)
if not display:
    raise SystemExit("Could not open X display")

try:
    # Core keyboard, Lock modifier: unlock Caps without touching other modifiers.
    if not x11.XkbLockModifiers(display, 0x100, 1 << 1, 0):
        raise SystemExit("Could not unlock Caps Lock")
finally:
    x11.XCloseDisplay(display)
