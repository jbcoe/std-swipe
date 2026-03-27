# std-swipe

A native iOS/macOS app for reviewing C++ standards committee (WG21) papers using a Tinder-like swipe interface. Browse proposals one at a time and vote to approve or reject them with a simple swipe gesture.

## Overview

[WG21](https://isocpp.org/std/the-committee) publishes hundreds of papers each year as part of the ISO C++ standardisation process. **std-swipe** provides an interactive way to work through these papers, helping you decide which proposals deserve your support.

- Swipe **right** to approve a paper ✅
- Swipe **left** to reject a paper ❌

Papers are fetched live from [open-std.org](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/) and can be browsed by year (2020–2026).

## Features

- **Swipe-based voting** – Tinder-style card interface built with SwiftUI gestures
- **PDF previews** – First-page thumbnail rendered inline for each paper
- **Year selection** – Browse papers from 2020 through 2026
- **Vote history** – Review all your approved and rejected papers, with direct links to the originals
- **Live data** – Papers fetched in real time from the official WG21 repository

## Requirements

- Xcode 15 or later
- iOS 17+ / macOS 14+ deployment target
- An active internet connection (papers are fetched from open-std.org)

## Building

1. Clone the repository:
   ```sh
   git clone https://github.com/jbcoe/std-swipe.git
   cd std-swipe
   ```

2. Open the Xcode project:
   ```sh
   open std-swipe.xcodeproj
   ```

3. Select your target device or simulator and press **⌘R** to build and run.

No external package dependencies are required; the project uses only Apple system frameworks.

## Project Structure

```
std-swipe/
├── std_swipeApp.swift       – App entry point
├── ContentView.swift        – Root view
├── SwipeView.swift          – Main card deck interface
├── PaperCardView.swift      – Swipeable card with gesture handling
├── PaperThumbnailView.swift – Async PDF thumbnail renderer
├── Paper.swift              – Data model and paper-fetching service
├── VotedPapersView.swift    – Vote history list
└── Persistence.swift        – Core Data / CloudKit setup
```

## Architecture

The app follows a straightforward SwiftUI/ObservableObject pattern:

- **`PaperStore`** (`Paper.swift`) is the central `@ObservableObject`. It fetches papers from `open-std.org`, parses the HTML listing with regex, and tracks votes for the current session.
- **`SwipeView`** observes `PaperStore` and renders the card deck, a progress indicator, and year-selection controls.
- **`PaperCardView`** handles drag gestures, showing an APPROVE or REJECT overlay as the card is dragged, and calls back into `PaperStore` when a swipe threshold is crossed.
- **`PaperThumbnailView`** downloads the PDF for each paper asynchronously and renders the first page as a thumbnail using `PDFKit`.
- **`VotedPapersView`** shows the full vote history and supports filtering by approval status.

## Contributing

Contributions are welcome. Please open an issue or pull request on [GitHub](https://github.com/jbcoe/std-swipe).

## License

See [LICENSE](LICENSE) for details.
