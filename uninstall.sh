#!/bin/sh
# Copot pemasangan DikNom System Monitor.
set -eu

PREFIX=${PREFIX:-"$HOME/.local"}
case "${1:-}" in
    --system) PREFIX=/usr/local ;;
    --prefix=*) PREFIX=${1#*=} ;;
    "") ;;
    *) echo "Opsi tidak dikenal: $1" >&2; exit 2 ;;
esac

if [ "$PREFIX" = "/usr/local" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Untuk melepas instalasi sistem, jalankan dengan sudo." >&2
    exit 1
fi

rm -f "$PREFIX/bin/diknom-monitor"
rm -f "$PREFIX/share/icons/diknom-monitor.png"
rm -f "$PREFIX/share/applications/diknom-monitor.desktop"
rm -rf "$PREFIX/share/diknom-monitor"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$PREFIX/share/applications" >/dev/null 2>&1 || true
fi

echo "DikNom System Monitor dilepas."
echo "Konfigurasi di ~/.config/diknom-monitor tidak dihapus."
