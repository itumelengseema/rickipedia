# Changelog

Notable changes to Rickipedia are recorded here.

## [Unreleased]
## [1.0.0] - 2026-10-14
### Added
- Browse characters with pagination.
- Search characters by name.
- View character details.
- Cache character images with loading and error placeholders.

### Fixed
- Preserve existing character results during refresh.
- Prevent duplicate character IDs during pagination.
- Improve pagination error feedback.

### Validation
- Android release tested on a Pixel 10 Pro XL emulator, Android 17.
- iOS release tested on a physical iPhone 11, iOS 26.5.
- CI line coverage baseline: 96.84% (429/443 lines).

### Known limitations
- Web support is planned after responsive improvements.
- Android validation used an emulator, not a physical device.
- App Store and Play Store distribution are not included.
- Android and CI used Flutter 3.47.4; iOS used Flutter 3.47.7.