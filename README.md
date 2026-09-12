🎬 OpenBlur

Open-source RSMB-style motion blur for Android / Termux.

OpenBlur is a command-line video processing tool that brings high-quality, motion-compensated blur to Android devices through "Termux" (https://termux.dev/).

It uses VapourSynth, MVTools, and BestSource to analyze motion between frames and generate smooth, directional motion blur without requiring a desktop computer.

«OpenBlur is inspired by the workflow and visual characteristics of RSMB, but it is not an implementation of RE:Vision Effects RSMB and does not contain proprietary RSMB code.»

---

✨ Features

- 🎥 Motion-compensated video blur
- 📱 Designed for Android / Termux
- 🌀 Powered by MVTools motion analysis
- 🎞️ VapourSynth processing engine
- 🔊 Preserves the original audio
- 📂 Native Android file picker
- ⚡ Fully command-line based
- 💾 Automatic output naming
- 📁 Outputs directly to "Movies/OpenBlur"
- 📦 One-command installation
- 🚫 Never overwrites existing output files

Blur levels

Preset| Value| Intended use
Light| "25"| Subtle motion smoothing
Balanced| "50"| General-purpose motion blur
Heavy| "100"| Strong cinematic motion
Real Heavy| "200"| Extreme motion blur

---

🧠 How it works
```
OpenBlur uses a motion-compensated processing pipeline:

Android Video
     │
     ▼
 BestSource
     │
     ▼
 VapourSynth
     │
     ▼
   MVTools
     │
     ├── Motion vectors
     │
     └── Frame analysis
     │
     ▼
   FlowBlur
     │
     ▼
   FFmpeg
     │
     ├── H.264 video
     └── Original audio
     │
     ▼
 Movies/OpenBlur/
```
MVTools analyzes the movement between frames and FlowBlur uses those motion vectors to generate the blur.

This makes the blur motion-aware, rather than simply blending neighboring frames.

---

📱 Requirements

Android

- Android device with 64-bit ARM ("aarch64")
- Android 7+ recommended
- Termux
- Termux:API companion application
- Sufficient storage for video processing

Software

The installer automatically installs and builds the required components:

- Python
- FFmpeg
- Git
- Clang
- CMake
- Ninja
- Meson
- Cython
- FFTW
- VapourSynth
- MVTools
- BestSource

---

🚀 Installation

Install OpenBlur directly from your Android terminal:
```
curl -fsSL https://raw.githubusercontent.com/cheezbiscuitbruv/openblur/main/install-openblur.sh | bash
```
The installer will:

1. Install required dependencies.
2. Build VapourSynth.
3. Configure VSScript for Termux.
4. Build MVTools.
5. Build BestSource.
6. Install the OpenBlur processing engine.
7. Create the "openblur" command.
8. Verify the complete processing stack.

After installation:
```
openblur
```
---

🎬 Usage

Run:
```
openblur
```
OpenBlur will launch the Android file picker.

Select your video, then choose a blur intensity:
```
Choose blur intensity:

  1) Light       25
  2) Balanced    50
  3) Heavy      100
  4) Real Heavy 200
```
The processed video is automatically saved to:
```
Movies/OpenBlur/
```
Example:
```
Movies/OpenBlur/openblur_50.mp4
```
If that file already exists, OpenBlur automatically creates:
```
openblur_50_1.mp4
openblur_50_2.mp4
openblur_50_3.mp4
```
Existing files are never overwritten.

---

⚙️ Processing pipeline

The current processing engine uses:
```
BestSource
     ↓
MVTools Super
     ↓
MVTools Analyse
     ↓
MVTools FlowBlur
     ↓
FFmpeg H.264/AAC
```
Motion analysis currently uses:
```
- "pel=2"
- "blksize=8"
- "overlap=4"
- "search=3"
- "truemotion=true"
- "prec=2"
```
These settings are designed as a practical balance between motion quality and processing performance on Android hardware.

---

📦 Output

OpenBlur produces Android-compatible MP4 files using:

- H.264 / AVC video
- AAC audio
- "yuv420p"
- Fast-start MP4
- Original audio stream preserved when available

The default video encoding settings prioritize compatibility and reasonable quality:
```
Codec:       H.264
Pixel format: yuv420p
Preset:      veryfast
CRF:         18
Audio:       AAC 192 kbps
```
---

🛠️ Technology

OpenBlur is built around several established open-source projects.

VapourSynth

Video processing framework used as the core scripting engine.

MVTools

Provides motion-vector analysis and motion-compensated processing.

BestSource

Provides reliable video source handling for VapourSynth.

FFmpeg

Handles final video encoding, audio preservation, and MP4 generation.

---

📂 Project structure
```
openblur/
├── install-openblur.sh
├── openblur
└── openblur.vpy
```
The installer generates the required runtime files automatically.

---

⚡ Performance

Motion-compensated blur is computationally expensive.

Processing speed depends heavily on:

- CPU performance
- Video resolution
- Frame rate
- Motion complexity
- Blur intensity
- MVTools settings

Higher blur values do not necessarily mean proportionally higher processing time, but stronger blur can make artifacts more noticeable in difficult motion.

For faster testing, start with:

Light 25

or:

Balanced 50

---

🎯 Why OpenBlur?

Desktop motion-blur workflows often rely on expensive commercial software or plugins.

OpenBlur aims to provide a practical alternative for Android users who want:

- motion-compensated blur
- command-line processing
- open-source components
- no desktop PC
- no proprietary motion-blur plugin

Everything runs directly on the Android device.

---

⚠️ Limitations

OpenBlur is still an evolving project.

You may encounter artifacts with:

- Very fast camera movement
- Occlusions
- Complex backgrounds
- Large objects crossing the frame
- Extremely low frame rates
- Heavy blur settings

Motion estimation cannot perfectly predict every type of movement.

---

🔒 Open source

OpenBlur itself is open source.

It is built using open-source projects including VapourSynth, MVTools, BestSource, and FFmpeg.

OpenBlur does not include proprietary RSMB code.

---

🤝 Contributing

Contributions, testing, bug reports, and improvements are welcome.

If you find a problem:

1. Reproduce the issue.
2. Record the relevant terminal output.
3. Include your Android version and CPU architecture.
4. Include the input video's resolution and frame rate.
5. Open an issue with the information above.

Pull requests are welcome for:

- Performance improvements
- Better motion estimation
- New processing modes
- Android compatibility
- CLI improvements
- Documentation
- Testing

---

📜 License

OpenBlur's license is defined by the repository's "LICENSE" file.

Its third-party dependencies retain their respective licenses.

---

⭐ Credits

Built with:

- VapourSynth
- MVTools
- BestSource
- FFmpeg
- Termux

Created for Android video creators who want serious motion-blur processing without needing a desktop workflow.

---

🚀 OpenBlur

Motion blur. Open source. Android-native workflow.

openblur
