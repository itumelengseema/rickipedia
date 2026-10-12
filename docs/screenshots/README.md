# Screenshot captures

## Supplied app screenshots

The main README displays the seven user-supplied PNGs in `device/`. They are copied unchanged, retaining their original framing, debug banners, overlays, and crop. Some show profile/menu icons before their disabled styling was applied; the controls remain disabled placeholders in the current code.

| Supplied image | File | Content |
| --- | --- | --- |
| 1 | `device/list.png` | Initial character grid |
| 2 | `device/search.png` | Character search results for “rick” |
| 3 | `device/details.png` | Rick Sanchez details and episode count |
| 4 | `device/pagination-error.png` | Cropped pagination error snackbar with Retry |
| 5 | `device/list-error.png` | Browsing error with Retry |
| 6 | `device/search-error.png` | Search error without a dedicated Retry |
| 7 | `device/list-more.png` | Additional browsing results |

## Saved widget captures

This directory also retains `list.png`, `search.png`, `details.png`, `list-error.png`, `search-error.png`, and `pagination-error.png` from the earlier widget capture session. They are separate documentation artifacts, not emulator captures or pixel-comparison tests. They do not establish platform release validation.

`tool/fixtures/screenshot_characters.json` contains saved character records 1–4, and `portraits/1.jpeg` through `4.jpeg` contain their corresponding API portraits. The capture tool is not included in this branch, so no supported regeneration command is available. Running `flutter test` does not regenerate these screenshots.

Character data and artwork originate from the [Rick and Morty API](https://rickandmortyapi.com/); the characters and artwork belong to their respective rights holders. The saved records/portraits support documentation only and are not bundled as app assets.
