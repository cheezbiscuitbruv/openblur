#!/data/data/com.termux/files/usr/bin/bash

set -Eeuo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_ROOT="$HOME/.openblur-build"
OPENBLUR_DIR="$HOME/openblur"

echo "================================"
echo "        🎬 OpenBlur"
echo " Android / Termux Installer"
echo "================================"
echo

# --------------------------------------------------
# Basic checks
# --------------------------------------------------

if [ "$(uname -m)" != "aarch64" ]; then
    echo "❌ OpenBlur currently requires a 64-bit ARM Android device."
    echo "Detected: $(uname -m)"
    exit 1
fi

echo "📦 Installing build dependencies..."

pkg update -y
pkg install -y \
    python \
    ffmpeg \
    git \
    clang \
    cmake \
    ninja \
    pkg-config \
    make \
    fftw \
    termux-api

python -m pip install meson cython

PY_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

echo
echo "Python: $PY_VERSION"
echo "FFmpeg: $(ffmpeg -version | head -n1)"
echo

mkdir -p "$INSTALL_ROOT"
mkdir -p "$OPENBLUR_DIR"

# --------------------------------------------------
# VapourSynth R80RC2
# --------------------------------------------------

echo "🎞️ Installing VapourSynth R80RC2..."

VS_OK=0

if python - <<'PY'
try:
    import vapoursynth as vs
    assert vs.__api_version__.api_major >= 4
    print(vs.__version__)
except Exception:
    raise SystemExit(1)
PY
then
    VS_OK=1
    echo "✅ VapourSynth already works."
fi

if [ "$VS_OK" -eq 0 ]; then

    rm -rf "$INSTALL_ROOT/vapoursynth"

    git clone \
        --branch R80RC2 \
        --depth 1 \
        https://github.com/vapoursynth/vapoursynth.git \
        "$INSTALL_ROOT/vapoursynth"

    cd "$INSTALL_ROOT/vapoursynth"

    python -m mesonbuild.mesonmain setup build \
        --buildtype=release \
        --prefix="$PREFIX"

    python -m mesonbuild.mesonmain compile -C build
    python -m mesonbuild.mesonmain install -C build

    mkdir -p "$PREFIX/bin"

    VSPipe="$PREFIX/lib/python${PY_VERSION}/site-packages/vapoursynth/vspipe"

    if [ -f "$VSPipe" ]; then
        ln -sf "$VSPipe" "$PREFIX/bin/vspipe"
    fi
fi

# --------------------------------------------------
# VSScript configuration
# --------------------------------------------------

echo
echo "⚙️ Configuring VapourSynth..."

VS_PYTHON_DIR="$PREFIX/lib/python${PY_VERSION}/site-packages/vapoursynth"
VSLIB="$VS_PYTHON_DIR/libvsscript.so"
PYBIN="$(command -v python)"
PYLIB="$PREFIX/lib/libpython${PY_VERSION}.so"

if [ ! -f "$VSLIB" ]; then
    echo "❌ VapourSynth VSScript library not found:"
    echo "$VSLIB"
    exit 1
fi

if [ ! -f "$PYLIB" ]; then
    echo "❌ Python library not found:"
    echo "$PYLIB"
    exit 1
fi

PYMTIME="$(stat -c %Y "$PYLIB")"

mkdir -p "$HOME/.config/vapoursynth"

printf '"%s" = ["%s", "%s", "%s"]\n' \
    "$VSLIB" \
    "$PYBIN" \
    "$PYLIB" \
    "$PYMTIME" \
    > "$HOME/.config/vapoursynth/vapoursynth.toml"

# Make sure vspipe is available
if ! command -v vspipe >/dev/null 2>&1; then
    echo "❌ vspipe could not be installed."
    exit 1
fi

vspipe --version >/dev/null

echo "✅ VapourSynth + VSScript ready."

# --------------------------------------------------
# Discover actual VapourSynth plugin directory
# --------------------------------------------------

PLUGIN_DIR="$(
    python -c 'import vapoursynth as vs; print(vs.get_plugin_dir())'
)"

mkdir -p "$PLUGIN_DIR"

echo
echo "VapourSynth plugin directory:"
echo "$PLUGIN_DIR"

# --------------------------------------------------
# MVTools
# --------------------------------------------------

echo
echo "🌀 Installing MVTools..."

if python - <<'PY'
import vapoursynth as vs
print(vs.core.mv)
PY
then
    echo "✅ MVTools already works."
else
    rm -rf "$INSTALL_ROOT/vapoursynth-mvtools"

    git clone \
        --depth 1 \
        https://github.com/dubhater/vapoursynth-mvtools.git \
        "$INSTALL_ROOT/vapoursynth-mvtools"

    cd "$INSTALL_ROOT/vapoursynth-mvtools"

    python -m mesonbuild.mesonmain setup build \
        --buildtype=release \
        --prefix="$PREFIX"

    python -m mesonbuild.mesonmain compile -C build

    if [ ! -f build/mvtools.so ]; then
        echo "❌ MVTools build produced no mvtools.so"
        exit 1
    fi

    cp build/mvtools.so "$PLUGIN_DIR/"
fi

# --------------------------------------------------
# BestSource R17
# --------------------------------------------------

echo
echo "📦 Installing BestSource R17..."

if python - <<'PY'
import vapoursynth as vs
print(vs.core.bs)
PY
then
    echo "✅ BestSource already works."
else
    rm -rf "$INSTALL_ROOT/bestsource"

    git clone \
        --branch R17 \
        --depth 1 \
        https://github.com/vapoursynth/bestsource.git \
        "$INSTALL_ROOT/bestsource"

    cd "$INSTALL_ROOT/bestsource"

    git submodule update --init --recursive

    python -m mesonbuild.mesonmain setup build \
        --buildtype=release \
        --prefix="$PREFIX"

    python -m mesonbuild.mesonmain compile -C build
    python -m mesonbuild.mesonmain install -C build
fi

# --------------------------------------------------
# Final plugin verification
# --------------------------------------------------

echo
echo "🧪 Verifying processing stack..."

python - <<'PY'
import vapoursynth as vs

core = vs.core

print("VapourSynth:", vs.__version__)
print("MVTools:", "OK" if hasattr(core, "mv") else "FAIL")
print("BestSource:", "OK" if hasattr(core, "bs") else "FAIL")

if not hasattr(core, "mv"):
    raise SystemExit("MVTools verification failed")

if not hasattr(core, "bs"):
    raise SystemExit("BestSource verification failed")
PY

# --------------------------------------------------
# OpenBlur engine
# --------------------------------------------------

echo
echo "🎬 Installing OpenBlur..."

cat > "$OPENBLUR_DIR/openblur.vpy" <<'VEOF'
import vapoursynth as vs

core = vs.core

src_path = "__INPUT__"
blur_amount = __BLUR__

src = core.bs.VideoSource(src_path)

sup = core.mv.Super(
    src,
    pel=2,
    sharp=1
)

bv = core.mv.Analyse(
    sup,
    isb=True,
    delta=1,
    blksize=8,
    overlap=4,
    search=3,
    truemotion=True
)

fv = core.mv.Analyse(
    sup,
    isb=False,
    delta=1,
    blksize=8,
    overlap=4,
    search=3,
    truemotion=True
)

out = core.mv.FlowBlur(
    src,
    sup,
    bv,
    fv,
    blur=blur_amount,
    prec=2
)

out.set_output()
VEOF

# --------------------------------------------------
# OpenBlur CLI
# --------------------------------------------------

cat > "$OPENBLUR_DIR/openblur" <<'VEOF'
#!/data/data/com.termux/files/usr/bin/bash

set -Eeuo pipefail

INPUT="$HOME/.openblur-input"
RUNSCRIPT="$HOME/.openblur-run.vpy"
ENGINE="$HOME/openblur/openblur.vpy"
OUTDIR="$HOME/storage/shared/Movies/OpenBlur"

cleanup() {
    rm -f "$INPUT" "$RUNSCRIPT"
}
trap cleanup EXIT

echo
echo "================================"
echo "           🎬 OpenBlur"
echo "================================"
echo

# --------------------------------------------------
# Check Android storage
# --------------------------------------------------

if [ ! -d "$HOME/storage/shared" ]; then
    echo "📱 Requesting Android storage permission..."
    termux-setup-storage
    sleep 2
fi

if [ ! -d "$HOME/storage/shared" ]; then
    echo "❌ Android storage is unavailable."
    exit 1
fi

# --------------------------------------------------
# Native Android picker
# --------------------------------------------------

rm -f "$INPUT"

echo "📂 Select a video..."
echo

termux-storage-get "$INPUT"

for _ in $(seq 1 30); do
    [ -s "$INPUT" ] && break
    sleep 1
done

if [ ! -s "$INPUT" ]; then
    echo
    echo "❌ No video was selected."
    exit 1
fi

# --------------------------------------------------
# Blur intensity
# --------------------------------------------------

echo
echo "Choose blur intensity:"
echo
echo "  1) Light       25"
echo "  2) Balanced    50"
echo "  3) Heavy      100"
echo "  4) Real Heavy 200"
echo

read -r -p "Choice [1-4]: " CHOICE

case "$CHOICE" in
    1) BLUR=25 ;;
    2) BLUR=50 ;;
    3) BLUR=100 ;;
    4) BLUR=200 ;;
    *)
        echo "❌ Invalid choice."
        exit 1
        ;;
esac

# --------------------------------------------------
# Output naming
# --------------------------------------------------

mkdir -p "$OUTDIR"

BASE="openblur_${BLUR}"
OUTPUT="$OUTDIR/${BASE}.mp4"
N=1

while [ -e "$OUTPUT" ]; do
    OUTPUT="$OUTDIR/${BASE}_${N}.mp4"
    N=$((N + 1))
done

# --------------------------------------------------
# Generate VapourSynth script
# --------------------------------------------------

sed \
    -e "s|__INPUT__|$INPUT|g" \
    -e "s|__BLUR__|$BLUR|g" \
    "$ENGINE" \
    > "$RUNSCRIPT"

echo
echo "================================"
echo "⚙️ Processing"
echo "Blur: $BLUR"
echo "Output:"
echo "$OUTPUT"
echo "================================"
echo

# --------------------------------------------------
# Motion blur + audio
# --------------------------------------------------

vspipe "$RUNSCRIPT" - -c y4m |
ffmpeg \
    -hide_banner \
    -loglevel warning \
    -f yuv4mpegpipe \
    -i - \
    -i "$INPUT" \
    -map 0:v:0 \
    -map 1:a:0? \
    -map_metadata 1 \
    -c:v libx264 \
    -preset veryfast \
    -crf 18 \
    -profile:v high \
    -level:v 4.2 \
    -pix_fmt yuv420p \
    -tag:v avc1 \
    -c:a aac \
    -b:a 192k \
    -shortest \
    -movflags +faststart \
    -y "$OUTPUT"

echo
echo "📱 Updating Android media index..."

termux-media-scan "$OUTPUT" >/dev/null 2>&1 || true

echo
echo "✅ OpenBlur finished!"
echo
echo "📁 $OUTPUT"
echo
VEOF

chmod +x "$OPENBLUR_DIR/openblur"

# --------------------------------------------------
# Make "openblur" a real command
# --------------------------------------------------

ln -sf "$OPENBLUR_DIR/openblur" "$PREFIX/bin/openblur"

# --------------------------------------------------
# Final verification
# --------------------------------------------------

echo
echo "🧪 Final verification..."

command -v openblur >/dev/null
command -v vspipe >/dev/null

python - <<'PY'
import vapoursynth as vs

core = vs.core

assert hasattr(core, "mv"), "MVTools missing"
assert hasattr(core, "bs"), "BestSource missing"

print("✅ VapourSynth:", vs.__version__)
print("✅ MVTools: OK")
print("✅ BestSource: OK")
print("✅ vspipe: OK")
PY

echo
echo "================================"
echo "       ✅ OpenBlur READY"
echo "================================"
echo
echo "Run it with:"
echo
echo "    openblur"
echo
