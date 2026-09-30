# Wildbrew app icon

The icon depicts an amber wooden brewing barrel with green hops on a warm ivory background. ImageGen produced the square bitmap; Icon Composer authored the native `WildbrewAppIcon.icon` document and applies the platform mask.

`WildbrewIconSource.png` preserves the generated master. The document embeds the same bitmap at 82% scale to fit the 1,024-point canvas without cropping the subject. `Preview.png` is extracted from the compiled ICNS.

Liquid Glass is disabled on the image layer. Group specular highlights, translucency and shadows are disabled. Default and dark appearances preserve the artwork; the system derives the monochrome appearance.

Build with `scripts/build-app.sh` using Xcode with Icon Composer support. The build compiles the document with `actool`, embeds `Assets.car` and `WildbrewAppIcon.icns`, merges the generated icon keys into `Info.plist`, and signs the finished app. The SwiftUI app loads the compiled ICNS into `NSApplication.applicationIconImage` at launch so the Dock uses the same artwork. Validated with Xcode 27.0 and the retained macOS 26.6.2 Tart guest.

## Generation brief

Create a full-bleed square macOS app icon for Wildbrew, a native Homebrew GUI. Depict an amber wooden brewing barrel, two charcoal hoops, and a green hop cone with leaves at the upper right. Use a warm ivory background, matte illustration, a distinct silhouette, and generous space around the subject. No letters, wordmark, pre-rounded mask, glass, translucency, or glossy material.

## Acceptance

The compiled ICNS has the intended colors and mask. Finder and the running app in the guest Dock display the new icon. The guest's direct screenshot preserves colors; the experimental VNC view swaps red and blue channels, including system icons. Native screenshots are the color reference. Raw acceptance captures remain in `.local/acceptance/icon/` and are not committed.
