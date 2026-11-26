# Musixvoice

An offline and online music player with AI, built with Flutter for Android.

- **Offline**: plays all the music on your phone (asks for music access on first run), with albums, artists and folder filters.
- **Background playback**: media notification and lock-screen controls.
- **Settings**: Look & Feel, Visualizer, Audio (equalizer, speed, loudness), User Interface, Full Player, Files & Folder, Advanced (sleep timer).
- **Online**: stream full-length tracks from Audius (free, open music network).
- **AI**: learns your genres on-device. Add your own DeepSeek or Claude key in Settings for taste analysis and mood mixes.
- **Themes**: Aurora, Neon Grid, Sunset, Emerald, Midnight, Rose Quartz, Solar.

## Download

[**⬇️ Download Musixvoice.apk (v1.0.3)**](https://github.com/EphraimSib/Musixvoice/releases/download/v1.0.3/Musixvoice.apk)

Get the latest `Musixvoice.apk` from the link above (or check the [Releases](../../releases) page), then open it on your Android phone and allow "Install unknown apps" when asked.

## Build it yourself

```bash
flutter pub get
flutter run
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Publishing a release

Push a version tag and GitHub builds the APK for you:

```bash
git tag v1.0.3
git push origin v1.0.3
```

Built by Ephraim Sibale.
