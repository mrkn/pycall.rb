#!/usr/bin/env python

import ctypes.util
from distutils.sysconfig import get_config_var, get_python_version
import os
import sys

is_windows = os.name == "nt"

def linked_libpython():
    if is_windows:
        return _linked_libpython_windows()
    return _linked_libpython_unix()

class Dl_info(ctypes.Structure):
    _fields_ = [
        ("dli_fname", ctypes.c_char_p),
        ("dli_fbase", ctypes.c_void_p),
        ("dli_sname", ctypes.c_char_p),
        ("dli_saddr", ctypes.c_void_p),
    ]

def _linked_libpython_unix():
    libdl = ctypes.CDLL(ctypes.util.find_library("dl"))
    libdl.dladdr.argtypes = [ctypes.c_void_p, ctypes.POINTER(Dl_info)]
    libdl.dladdr.restype = ctypes.c_int

    dlinfo = Dl_info()
    retcode = libdl.dladdr(
            ctypes.cast(ctypes.pythonapi.Py_GetVersion, ctypes.c_void_p),
            ctypes.pointer(dlinfo))
    if retcode == 0:  # means error
        return None
    path = os.path.realpath(dlinfo.dli_fname.decode())
    if path == os.path.realpath(sys.executable):
        return None
    return path

def _linked_libpython_windows():
    # Based on: https://stackoverflow.com/a/16659821
    from ctypes.wintypes import HANDLE, LPWSTR, DWORD

    GetModuleFileName = ctypes.windll.kernel32.GetModuleFileNameW
    GetModuleFileName.argtypes = [HANDLE, LPWSTR, DWORD]
    GetModuleFileName.restype = DWORD

    MAX_PATH = 260
    try:
        buf = ctypes.create_unicode_buffer(MAX_PATH)
        GetModuleFileName(ctypes.pythonapi._handle, buf, MAX_PATH)
        return buf.value
    except (ValueError, OSError):
        return None

print("linked_libpython: {val}".format(val=(linked_libpython() or "None")))

sys_keys = [ "executable", "exec_prefix", "prefix" ]

for var in sys_keys:
    print("{var}: {val}".format(var=var, val=(getattr(sys, var) or "None")))

config_keys = [ "INSTSONAME", "LIBDIR", "LIBPL", "LIBRARY", "LDLIBRARY",
                "MULTIARCH", "PYTHONFRAMEWORKPREFIX", "SHLIB_SUFFIX", "srcdir" ]

for var in config_keys:
    print("{var}: {val}".format(var=var, val=(get_config_var(var) or "None")))

print("ABIFLAGS: {val}".format(val=get_config_var("ABIFLAGS") or get_config_var("abiflags") or "None"))

version = get_python_version() or \
          "{v.major}.{v.minor}".format(v=sys.version_info) or \
          get_config_var("VERSION")
print("VERSION: {val}".format(val=version))

if is_windows:
    if hasattr(sys, "base_exec_prefix"):
        PYTHONHOME = sys.base_exec_prefix
    else:
        PYTHONHOME = sys.exec_prefix
else:
    if hasattr(sys, "base_exec_prefix"):
        PYTHONHOME = ":".join([sys.base_prefix, sys.base_exec_prefix])
    else:
        PYTHONHOME = ":".join([sys.prefix, sys.exec_prefix])
print("PYTHONHOME: {val}".format(val=PYTHONHOME))
