#!/bin/sh
# Pemasang DikNom System Monitor untuk berbagai distro Linux.
# Default: instalasi user-local tanpa root.
set -eu

APP_NAME="DikNom System Monitor"
SRC_DIR=$(dirname -- "$0")
SRC_DIR=$(cd -- "$SRC_DIR" && pwd)
PREFIX=${PREFIX:-"$HOME/.local"}
BIN_DIR="$PREFIX/bin"
ICON_DIR="$PREFIX/share/icons"
APP_DIR="$PREFIX/share/applications"
DATA_DIR="$PREFIX/share/diknom-monitor"
DEPS=1
PIP=0

usage() {
    cat <<'EOF'
DikNom System Monitor - pemasang

Pemakaian:
  ./install.sh                 Instal; dependensi yang kurang dipasang otomatis
  ./install.sh --no-deps       Hanya cek dependensi, jangan pasang
  ./install.sh --deps          Paksa pasang dependensi (sama dengan default)
  ./install.sh --pip           Pasang psutil via pip --user bila belum ada
  ./install.sh --system        Instal ke /usr/local (butuh root)
  ./install.sh --prefix=DIR    Instal ke DIR (default: ~/.local)
  ./install.sh --help          Tampilkan bantuan ini

Pemasangan dependensi memakai package manager distro dan bisa meminta
password sudo. Gunakan --no-deps bila ingin memeriksa tanpa mengubah sistem.
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

for arg in "$@"; do
    case "$arg" in
        --deps) DEPS=1 ;;
        --no-deps) DEPS=0 ;;
        --pip) PIP=1 ;;
        --system) PREFIX=/usr/local ;;
        --prefix=*) PREFIX=${arg#*=} ;;
        -h|--help) usage; exit 0 ;;
        *) die "Opsi tidak dikenal: $arg (gunakan --help)" ;;
    esac
done

[ -n "$PREFIX" ] || die "PREFIX kosong."
BIN_DIR="$PREFIX/bin"
ICON_DIR="$PREFIX/share/icons"
APP_DIR="$PREFIX/share/applications"
DATA_DIR="$PREFIX/share/diknom-monitor"

if [ "$PREFIX" = "/usr/local" ] && [ "$(id -u)" -ne 0 ]; then
    die "Instalasi --system butuh root. Jalankan dengan sudo, atau pakai ./install.sh biasa."
fi

# ---------------------------------------------------------------------------
# Python dan dependensi
# ---------------------------------------------------------------------------
PYTHON=${PYTHON:-}
if [ -z "$PYTHON" ]; then
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            PYTHON=$candidate
            break
        fi
    done
fi
[ -n "$PYTHON" ] || die "Python 3 tidak ditemukan."

deps_ok() {
    "$1" -c 'import tkinter, psutil' >/dev/null 2>&1
}

if "$PYTHON" -c 'import tkinter' >/dev/null 2>&1; then
    HAVE_TK=1
else
    HAVE_TK=0
fi
if "$PYTHON" -c 'import psutil' >/dev/null 2>&1; then
    HAVE_PSUTIL=1
else
    HAVE_PSUTIL=0
fi

DISTRO_NAME="Linux"
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_NAME=${PRETTY_NAME:-${NAME:-Linux}}
fi

PM=""
for candidate in apt-get dnf yum pacman zypper apk xbps-install emerge; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PM=$candidate
        break
    fi
done

PKGS=""
case "$PM" in
    apt-get) PKGS="python3-tk python3-psutil" ;;
    dnf|yum) PKGS="python3-tkinter python3-psutil" ;;
    pacman) PKGS="tk python-psutil" ;;
    zypper) PKGS="python3-tk python3-psutil" ;;
    apk) PKGS="python3-tkinter py3-psutil" ;;
    xbps-install) PKGS="python3-tkinter python3-psutil" ;;
    *) PKGS="" ;;
esac

run_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return 0
    fi
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
        return $?
    fi
    if command -v doas >/dev/null 2>&1; then
        doas "$@"
        return $?
    fi
    echo "Butuh hak root; tidak ada sudo/doas." >&2
    return 1
}

install_deps() {
    # PKGS sengaja dipecah menjadi argumen per paket.
    # shellcheck disable=SC2086
    set -- $PKGS
    case "$PM" in
        apt-get)
            run_root apt-get update || true
            run_root apt-get install -y "$@" ;;
        dnf|yum)
            run_root "$PM" install -y "$@" ;;
        pacman)
            run_root pacman -S --needed --noconfirm "$@" ;;
        zypper)
            run_root zypper --non-interactive install "$@" ;;
        apk)
            run_root apk add --no-cache "$@" ;;
        xbps-install)
            run_root xbps-install -Sy "$@" ;;
        *)
            return 1 ;;
    esac
}

if [ "$HAVE_TK" -eq 0 ] || [ "$HAVE_PSUTIL" -eq 0 ]; then
    echo "Dependensi belum lengkap:"
    [ "$HAVE_TK" -eq 1 ] || echo "  - tkinter belum ada"
    [ "$HAVE_PSUTIL" -eq 1 ] || echo "  - psutil belum ada"
    echo "Distro terdeteksi: $DISTRO_NAME"
    if [ -n "$PM" ]; then
        echo "Manajer paket: $PM"
        [ -n "$PKGS" ] && echo "Paket yang diperlukan: $PKGS"
    fi

    if [ "$DEPS" -eq 1 ] && [ -n "$PM" ] && [ -n "$PKGS" ]; then
        echo "Memasang dependensi otomatis lewat $PM..."
        echo "(bisa meminta password sudo; Ctrl+C untuk membatalkan)"
        install_deps || true
        # Jika Python yang dipakai adalah venv, paket distro mungkin masuk
        # ke Python sistem. Pilih interpreter yang benar-benar lengkap.
        if ! deps_ok "$PYTHON"; then
            for candidate in /usr/bin/python3 /usr/local/bin/python3; do
                if [ -x "$candidate" ] && deps_ok "$candidate"; then
                    PYTHON=$candidate
                    break
                fi
            done
        fi
        if "$PYTHON" -c 'import tkinter' >/dev/null 2>&1; then HAVE_TK=1; fi
        if "$PYTHON" -c 'import psutil' >/dev/null 2>&1; then HAVE_PSUTIL=1; fi
    fi

    if [ "$HAVE_PSUTIL" -eq 0 ] && [ "$PIP" -eq 1 ]; then
        echo "Mencoba memasang psutil untuk pengguna..."
        "$PYTHON" -m pip install --user psutil ||
            "$PYTHON" -m pip install --user --break-system-packages psutil ||
            true
        if ! deps_ok "$PYTHON"; then
            for candidate in /usr/bin/python3 /usr/local/bin/python3; do
                if [ -x "$candidate" ] && deps_ok "$candidate"; then
                    PYTHON=$candidate
                    break
                fi
            done
        fi
        if "$PYTHON" -c 'import psutil' >/dev/null 2>&1; then HAVE_PSUTIL=1; fi
        if "$PYTHON" -c 'import tkinter' >/dev/null 2>&1; then HAVE_TK=1; fi
    fi

    if [ "$HAVE_TK" -eq 0 ] || [ "$HAVE_PSUTIL" -eq 0 ]; then
        echo
        echo "Dependensi masih belum lengkap. Pasang manual:"
        case "$PM" in
            apt-get) echo "Debian/Ubuntu/Mint: sudo apt install $PKGS" ;;
            dnf|yum) echo "Fedora/RHEL: sudo $PM install $PKGS" ;;
            pacman) echo "Arch/Manjaro: sudo pacman -S $PKGS" ;;
            zypper) echo "openSUSE: sudo zypper install $PKGS" ;;
            apk) echo "Alpine: sudo apk add $PKGS" ;;
            xbps-install) echo "Void: sudo xbps-install $PKGS" ;;
            *)
                echo "Instal tkinter dari repositori distro, lalu:"
                echo "  $PYTHON -m pip install --user psutil"
                ;;
        esac
        echo "Setelah itu jalankan: ./install.sh"
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# Pasang aplikasi
# ---------------------------------------------------------------------------
[ -f "$SRC_DIR/diknom-monitor" ] || die "Berkas diknom-monitor tidak ditemukan di $SRC_DIR"
[ -f "$SRC_DIR/assets/icon.png" ] || die "Ikon tidak ditemukan di $SRC_DIR/assets/icon.png"

mkdir -p "$BIN_DIR" "$ICON_DIR" "$APP_DIR" "$DATA_DIR"
cp "$SRC_DIR/diknom-monitor" "$DATA_DIR/diknom-monitor"
chmod 644 "$DATA_DIR/diknom-monitor"
cp "$SRC_DIR/assets/icon.png" "$ICON_DIR/diknom-monitor.png"
chmod 644 "$ICON_DIR/diknom-monitor.png"

# Wrapper memakai interpreter yang sudah diverifikasi punya tkinter+psutil,
# sehingga menu desktop tidak bergantung pada PATH atau shebang.
PYTHON_ABS=$(command -v "$PYTHON")
cat > "$BIN_DIR/diknom-monitor" <<EOF
#!/bin/sh
exec "$PYTHON_ABS" "$DATA_DIR/diknom-monitor" "\$@"
EOF
chmod 755 "$BIN_DIR/diknom-monitor"

cat > "$APP_DIR/diknom-monitor.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DikNom System Monitor
GenericName=System Monitor
Comment=Monitor sistem ringan: CPU per core, suhu, RAM, baterai, proses
Exec="$BIN_DIR/diknom-monitor"
TryExec=$BIN_DIR/diknom-monitor
Icon=$ICON_DIR/diknom-monitor.png
Terminal=false
Categories=System;Monitor;
Keywords=monitor;task manager;cpu;ram;memory;process;battery;baterai;
StartupNotify=true
EOF
chmod 644 "$APP_DIR/diknom-monitor.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$PREFIX/share/icons" >/dev/null 2>&1 || true
fi

echo
echo "$APP_NAME terpasang."
echo "  Aplikasi : $BIN_DIR/diknom-monitor"
echo "  Data     : $DATA_DIR/diknom-monitor"
echo "  Ikon     : $ICON_DIR/diknom-monitor.png"
echo "  Menu     : $APP_DIR/diknom-monitor.desktop"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo
        echo "Catatan: $BIN_DIR belum ada di PATH."
        echo "Tambahkan baris ini ke ~/.profile lalu login ulang:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        echo "Atau jalankan langsung: $BIN_DIR/diknom-monitor"
        ;;
esac
echo
echo "Jalankan: diknom-monitor"
