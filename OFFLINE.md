# Offline build (Windows, no internet)

This repository includes everything needed to install the JavaScript dependencies and build the Android app on a Windows machine with no internet access.

## What is bundled (`offline/`)

| Path | Contents |
|---|---|
| `offline/npm-packages/` | Yarn offline mirror: every npm package in `yarn.lock` as a `.tgz`, including the GitHub dependency `react-native-orientation-angle` |
| `offline/yarn/yarn-1.22.22.js` | Yarn 1 as a single JS file, run with `node` (no global install needed) |
| `offline/gradle/maven-repo/` | Local Maven repository with every Gradle plugin and Android/Java dependency the build uses (debug and release), plus the Windows `aapt2` |
| `offline/gradle/offline-init.gradle` | Gradle init script that makes Gradle resolve from `maven-repo` first |
| `offline/gradle/gradle-7.5.1-bin.zip.part-*` | Gradle 7.5.1 distribution, used by `gradlew.bat` |
| `offline/jdk/jdk17-win-x64.zip.part-*` | Eclipse Temurin JDK 17 for Windows x64 |
| `offline/setup.bat`, `offline/build.bat` | One-time setup and build scripts |

Files over 100 MB are stored as `*.part-aa`, `*.part-ab`, ... because of GitHub's file size limit. `setup.bat` joins them back together.

## What must already be on the Windows machine

- **Node.js** 16 or newer (on `PATH`)
- **Android SDK** with:
  - Platform `android-33`
  - Build-tools `33.0.0`
  - NDK `23.1.7779620` (used by react-native-vision-camera and react-native-worklets-core)
  - CMake `3.22.1`
  - Platform-tools (`adb`)

Android Studio's own JDK is usually 21, which Gradle 7.5.1 cannot run on. Use the bundled JDK 17 instead (see below).

## Steps

1. Copy or clone this repository to the Windows machine. If you use git, keep line endings unchanged.
2. Run the one-time setup:

   ```bat
   offline\setup.bat
   ```

   It does the following:
   1. Joins the split archives.
   2. Extracts JDK 17 to `offline\jdk\jdk-17`.
   3. Runs `yarn install --offline` from the mirror, which creates `node_modules`.
   4. Creates `android\local.properties` pointing at `%ANDROID_HOME%`, or at `%LOCALAPPDATA%\Android\Sdk` if that variable isn't set. Edit the file if your SDK is somewhere else.
   5. Registers the offline Maven repository in `%USERPROFILE%\.gradle\init.d\` so Android Studio builds use it too.
3. Build:

   ```bat
   offline\build.bat                  rem debug APK -> android\app\build\outputs\apk\debug\
   offline\build.bat assembleRelease  rem release APK
   offline\build.bat installDebug     rem install on a USB-connected device
   ```

4. Start Metro (the JS dev server) for debug builds:

   ```bat
   node node_modules\react-native\cli.js start
   ```

### Android Studio

1. Open the `android` folder.
2. **Settings > Build, Execution, Deployment > Build Tools > Gradle > Gradle JDK**: choose the folder `offline\jdk\jdk-17`.
3. Turn on Gradle **offline mode** (the toggle in the Gradle tool window).
4. Skip any prompts to upgrade AGP or Gradle.

## Changing the code

- **JS/TS changes** (`src/`) need nothing extra. Rebuild or reload Metro.
- **Adding or upgrading npm packages or native libraries** needs internet. On an online machine, run `yarn add <pkg>`. The repo's `.yarnrc` stores the new tarballs in `offline/npm-packages`. Then build once online to download the new Gradle dependencies, and copy them into `offline/gradle/maven-repo`.

## Changes made to the project for this bundle

- `android/build.gradle`: pins `com.transistorsoft:tsbackgroundfetch` to `1.0.2`, the version bundled with react-native-background-fetch. Its build file asks for `+` (latest), and the latest version now needs compileSdk 34 and a newer Android Gradle Plugin, so the build failed without the pin.
- `.yarnclean`: removed `assets` and `images`. They deleted images that libraries need, such as `@react-navigation/elements` icons, and broke the release JS bundle.
- `android/gradle/wrapper/gradle-wrapper.properties`: `distributionUrl` now points to the bundled Gradle zip.
- `.yarnrc`: enables the yarn offline mirror.
- **AWS credentials were removed** from `src/shared/utils/aws.ts`, `src/screens/capture/CaptureScreen.tsx` and `.env` because this repository is public. Put the real values back on the offline machine before you build a version that uploads to S3. Search for `YOUR_AWS_ACCESS_KEY_ID`.
