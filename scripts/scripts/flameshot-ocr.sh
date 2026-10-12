#!/usr/bin/env bash
set -euo pipefail

# Öppna Flameshot, vänta på markering och kopiera OCR-texten till urklippet.
# OCR körs lokalt. Bilden laddas inte upp till någon extern tjänst.
# OCR_LANG=swe+eng kan användas för att välja språk uttryckligen.

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name='Flameshot OCR' 'Flameshot OCR' "$1" >/dev/null 2>&1 || true
  fi
}

fail() {
  printf 'Flameshot OCR: %s\n' "$1" >&2
  notify "$1"
  exit 1
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  cat <<'HELP'
Användning: flameshot-ocr.sh [--clipboard]

Öppnar Flameshot och väntar på att du markerar ett område. Markeringen
bekräftas automatiskt när du släpper musknappen och OCR-texten kopieras
till X11:s urklipp. Vid avbruten markering eller OCR-fel lämnas urklippet
oförändrat. OCR-texten skrivs inte ut i terminalen.

Med --clipboard används i stället en bild som redan finns i urklippet.

Kräver flameshot, xclip och tesseract samt minst ett av språkpaketen swe/eng.
Om båda finns används swe+eng. Välj andra installerade språk med:
  OCR_LANG=deu+eng flameshot-ocr.sh

i3-bindning (anpassa sökvägen vid behov):
  bindsym $mod+Shift+u exec --no-startup-id /home/caspar/scripts/flameshot-ocr.sh
HELP
  exit 0
fi

mode=capture
if (( $# == 1 )) && [[ $1 == --clipboard ]]; then
  mode=clipboard
elif (( $# != 0 )); then
  fail 'Okänt argument. Använd --help för instruktioner.'
fi

for tool in xclip tesseract; do
  command -v "$tool" >/dev/null 2>&1 || fail "Programmet $tool saknas."
done
if [[ "$mode" == capture ]]; then
  command -v flameshot >/dev/null 2>&1 || fail 'Programmet flameshot saknas.'
fi

[[ -n ${DISPLAY:-} ]] || fail 'DISPLAY saknas. Kör scriptet i din X11/i3-session.'

umask 077
workdir=$(mktemp -d "${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/flameshot-ocr.XXXXXXXX")
trap 'rm -f -- "$workdir/image" "$workdir/text" "$workdir/error" "$workdir/languages"; rmdir -- "$workdir"' EXIT

if [[ "$mode" == capture ]]; then
  # --raw väntar på resultatet och skriver PNG direkt till filen. Urklippet
  # ändras inte förrän OCR har lyckats. Escape avbryter utan att kopiera något.
  if ! flameshot gui --raw --accept-on-select > "$workdir/image" 2> "$workdir/error"; then
    notify 'Skärmbilden avbröts eller kunde inte tas. Urklippet lämnas oförändrat.'
    exit 1
  fi
else
  targets=$(xclip -selection clipboard -out -target TARGETS 2>/dev/null) || fail 'Urklippet kunde inte läsas.'
  image_type=''
  for candidate in image/png image/jpeg image/bmp image/tiff; do
    if grep -Fxq -- "$candidate" <<< "$targets"; then
      image_type=$candidate
      break
    fi
  done

  [[ -n "$image_type" ]] || fail 'Ingen stödd bild i urklippet. Kopiera skärmbilden från Flameshot först.'
  xclip -selection clipboard -out -target "$image_type" > "$workdir/image" 2> "$workdir/error" || fail 'Bilden kunde inte läsas. Urklippet lämnas oförändrat.'
fi
[[ -s "$workdir/image" ]] || fail 'Bilden är tom. Urklippet lämnas oförändrat.'

if [[ -n ${OCR_LANG:-} ]]; then
  languages=$OCR_LANG
else
  tesseract --list-langs > "$workdir/languages" 2> "$workdir/error" || fail 'Installerade OCR-språk kunde inte läsas.'
  languages=''
  for language in swe eng; do
    if grep -Fxq -- "$language" "$workdir/languages"; then
      languages="${languages:+$languages+}$language"
    fi
  done
  [[ -n "$languages" ]] || fail 'Installera Tesseracts svenska eller engelska språkpaket.'
fi

notify 'Läser text från bilden…'
tesseract "$workdir/image" stdout -l "$languages" > "$workdir/text" 2> "$workdir/error" || fail 'OCR misslyckades. Kontrollera bilden och språkpaketen. Urklippet lämnas oförändrat.'
grep -q '[^[:space:]]' "$workdir/text" || fail 'Ingen text hittades. Urklippet lämnas oförändrat.'

xclip -selection clipboard -in -target UTF8_STRING < "$workdir/text" 2> "$workdir/error" || fail 'Texten kunde inte skrivas till urklippet.'
notify "Texten finns nu i urklippet ($languages)."
