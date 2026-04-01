# Chrome Web Store Submission Notes

## Package To Upload

Upload a ZIP whose root contains these items directly:

- `manifest.json`
- `background/`
- `popup/`
- `icons/`
- `audio/`
- `images/`

Do not upload a ZIP where everything is nested one level too deep.

## Current Version

- Extension version: `1.0.1`

## Store Listing Draft

### Name
SlapMac - Tap Sound Effect

### Short Description
Tap your laptop or device and hear funny sounds using microphone or motion detection.

### Description
SlapMac turns taps and slaps into instant sound effects.

Features:
- Microphone mode for desktops and most laptops
- Motion sensor mode for supported mobile devices
- Adjustable sensitivity, volume, and cooldown
- Real-time slap counter
- Local-only operation with no analytics or tracking
- Free and open source

Notes:
- Microphone mode works best on desktops and laptops
- Motion sensor mode only works when the browser exposes device motion data
- The popup must stay open while detection is active

## Privacy Policy

Use this file as the source text:

- `SlapMac-Extension/PRIVACY-POLICY.md`

Chrome Web Store usually expects a public URL for the privacy policy.
Practical options:
- Publish the markdown contents on GitHub Pages
- Copy the text into a public page in the repository wiki
- Host a simple static HTML page anywhere public

## Recommended Store Assets

Prepare these before submission:

- Extension icon: 128x128 PNG
- Small promo tile: 440x280 PNG
- At least 1 screenshot, ideally 1280x800 or 640x400

Suggested screenshots:
- Main popup in microphone mode
- Donate modal open
- Popup showing live slap counter updates

## Submission Checklist

1. Create a Chrome Web Store Developer account.
2. Generate a release ZIP from the extension contents.
3. Make the privacy policy available at a public URL.
4. Capture screenshots and promo graphics.
5. Upload the ZIP in the Chrome Web Store Developer Dashboard.
6. Paste the listing text above and fill category/language fields.
7. Set single purpose clearly: local slap/tap sound effect utility.
8. Submit for review.

## Local Packaging Example

From inside `SlapMac-Extension/`:

```powershell
Compress-Archive -Path manifest.json, background, popup, icons, audio, images -DestinationPath ..\SlapMac-Extension-v1.0.1.zip -Force
```
