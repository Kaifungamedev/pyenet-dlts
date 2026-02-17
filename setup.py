from setuptools import setup, Extension
from Cython.Build import cythonize

import glob
import os
import platform
import subprocess
import sys

# Apply patches to enet submodule if needed
patches_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "patches")
enet_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "enet")
if os.path.isdir(patches_dir) and os.path.isdir(enet_dir):
    for patch_file in sorted(glob.glob(os.path.join(patches_dir, "*.patch"))):
        try:
            # Check if patch is already applied (reverse-apply dry run succeeds)
            subprocess.check_call(
                ["git", "apply", "--reverse", "--check", patch_file],
                cwd=enet_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except (subprocess.CalledProcessError, FileNotFoundError):
            # Patch not yet applied, apply it
            try:
                subprocess.check_call(
                    ["git", "apply", patch_file],
                    cwd=enet_dir)
                print(f"pyenet: Applied patch {os.path.basename(patch_file)}")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"pyenet: Warning: Failed to apply patch {os.path.basename(patch_file)}")

source_files = ["enet.pyx"]

_enet_files = glob.glob("enet/*.c")
source_files.extend(_enet_files)


define_macros = [('HAS_POLL', None), ('HAS_FCNTL', None),
                 ('HAS_MSGHDR_FLAGS', None), ('HAS_SOCKLEN_T', None)]

libraries = []
include_dirs = ["enet/include/"]
library_dirs = ["enet/"]

if sys.platform == 'win32':
    define_macros.extend([('WIN32', None)])
    libraries.extend(['Winmm', 'ws2_32'])

if sys.platform != 'darwin':
    define_macros.extend([('HAS_GETHOSTBYNAME_R', None),
                          ('HAS_GETHOSTBYADDR_R', None)])

# DTLS support via OpenSSL (required)
have_openssl = False

# Try pkg-config first
try:
    cflags = subprocess.check_output(
        ['pkg-config', '--cflags', 'openssl'],
        text=True, stderr=subprocess.DEVNULL).strip()
    libs = subprocess.check_output(
        ['pkg-config', '--libs', 'openssl'],
        text=True, stderr=subprocess.DEVNULL).strip()
    for flag in cflags.split():
        if flag.startswith('-I'):
            include_dirs.append(flag[2:])
    for flag in libs.split():
        if flag.startswith('-l'):
            libraries.append(flag[2:])
        elif flag.startswith('-L'):
            library_dirs.append(flag[2:])
    have_openssl = True
except (subprocess.CalledProcessError, FileNotFoundError):
    # Try common locations
    for prefix in ['/usr', '/usr/local', '/opt/homebrew']:
        ssl_header = os.path.join(prefix, 'include', 'openssl', 'ssl.h')
        if os.path.exists(ssl_header):
            include_dirs.append(os.path.join(prefix, 'include'))
            library_dirs.append(os.path.join(prefix, 'lib'))
            libraries.extend(['ssl', 'crypto'])
            have_openssl = True
            break

if sys.platform == 'win32' and not have_openssl:
    # On Windows, try to find OpenSSL via common install paths
    win_search_paths = []
    # Check vcpkg first (used in CI)
    vcpkg_root = os.environ.get('VCPKG_INSTALLATION_ROOT')
    if vcpkg_root:
        # Pick the right triplet for the target architecture
        machine = platform.machine().lower()
        if machine in ('arm64', 'aarch64'):
            vcpkg_triplet = 'arm64-windows'
        else:
            vcpkg_triplet = 'x64-windows'
        print(f"pyenet: Detected architecture: {platform.machine()}, vcpkg triplet: {vcpkg_triplet}")
        win_search_paths.append(os.path.join(vcpkg_root, 'installed', vcpkg_triplet))
    # Also check OPENSSL_ROOT_DIR env var
    openssl_root = os.environ.get('OPENSSL_ROOT_DIR')
    if openssl_root:
        win_search_paths.append(openssl_root)
    # Common manual install paths
    win_search_paths.extend([
        r'C:\OpenSSL-Win64', r'C:\OpenSSL-Win32',
        r'C:\Program Files\OpenSSL',
        r'C:\Program Files\OpenSSL-Win64',
        r'C:\Program Files\OpenSSL-Win32',
    ])
    print(f"pyenet: Searching for OpenSSL in: {win_search_paths}")
    for prefix in win_search_paths:
        ssl_header = os.path.join(prefix, 'include', 'openssl', 'ssl.h')
        print(f"pyenet:   Checking {ssl_header} ... {os.path.exists(ssl_header)}")
        if os.path.exists(ssl_header):
            include_dirs.append(os.path.join(prefix, 'include'))
            # Walk the entire lib tree to find .lib files
            lib_base = os.path.join(prefix, 'lib')
            print(f"pyenet:   Walking {lib_base} for .lib files...")
            ssl_lib_names = None
            ssl_lib_dir = None
            for root, dirs, files in os.walk(lib_base):
                lib_files = [f for f in files if f.endswith('.lib')]
                if lib_files:
                    print(f"pyenet:   Found in {root}: {lib_files}")
                    # Check for libssl.lib (standard name)
                    if 'libssl.lib' in lib_files:
                        ssl_lib_names = ['libssl', 'libcrypto']
                        ssl_lib_dir = root
                        break
                    # Check for versioned names (e.g. libssl-3-x64.lib)
                    for f in lib_files:
                        if f.startswith('libssl') and f.endswith('.lib'):
                            name = f[:-4]  # strip .lib
                            crypto_name = name.replace('libssl', 'libcrypto')
                            if crypto_name + '.lib' in lib_files:
                                ssl_lib_names = [name, crypto_name]
                                ssl_lib_dir = root
                                break
                    if ssl_lib_names:
                        break
            if ssl_lib_names:
                library_dirs.append(ssl_lib_dir)
                libraries.extend(ssl_lib_names)
                have_openssl = True
                print(f"pyenet: Found OpenSSL libs: {ssl_lib_names} in {ssl_lib_dir}")
            else:
                print(f"pyenet:   Headers found at {prefix} but no .lib files found!")
            break

if not have_openssl:
    raise RuntimeError(
        "OpenSSL development headers are required to build pyenet-dtls. "
        "Install them with your package manager:\n"
        "  Debian/Ubuntu: sudo apt install libssl-dev\n"
        "  Fedora/RHEL:   sudo dnf install openssl-devel\n"
        "  macOS:         brew install openssl\n"
        "  Windows:       Install OpenSSL from https://slproweb.com/products/Win32OpenSSL.html"
    )

print("pyenet: OpenSSL found, building with DTLS support")

ext_modules = cythonize(
    [Extension(
        "enet",
        sources=source_files,
        include_dirs=include_dirs,
        define_macros=define_macros,
        libraries=libraries,
        library_dirs=library_dirs)],
    compiler_directives={'language_level': 3},
)

from setuptools.command.build_ext import build_ext as _build_ext
import shutil

class build_ext(_build_ext):
    def run(self):
        super().run()
        # Copy enet.pyi alongside the built extension
        pyi_src = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'enet.pyi')
        if os.path.exists(pyi_src) and self.build_lib:
            shutil.copy2(pyi_src, self.build_lib)

setup(
    ext_modules=ext_modules,
    cmdclass={'build_ext': build_ext},
)
