# Vistora

Vistora is an iPhone and iPad SwiftUI application built with The Composable Architecture. The minimum deployment target is iOS 17; English and Spanish localization are supported. Features are developed in local Swift packages and composed by the app target.

## Requirements

- Xcode 27.1 or newer with Swift 6.4 and an iOS Simulator runtime
- XcodeGen 2.46 or newer

The packages use Swift 6 language mode. Dependency versions are declared in package manifests; the root `Package.resolved` records the versions used by the Xcode project.

## Bootstrap

From a clean checkout, run:

```sh
./Scripts/bootstrap.sh
```

This generates `Vistora.xcodeproj`, restores the tracked package resolution, and resolves dependencies. It also copies the example Unsplash plist if the local one does not exist. The generated project, `App/Info.plist`, and local `App/Resources/UnsplashConfig.plist` are ignored by Git. Edit `project.yml` or package manifests, then run bootstrap again; never edit the generated project.

## Open and run in Xcode

Open `Vistora.xcodeproj`, select the **Vistora** scheme and an iPhone or iPad simulator, then run the app. On first use, Xcode may error out asking to enable some package macros, you will need to trust those for the app to run in the simulator. Choose **Trust & Enable** for each prompt. If a prompt is no longer visible, open Xcode’s Issue navigator (⌘5), select the corresponding “Macro … must be enabled before it can be used” issue, and approve it there.

The command-line examples below use `-skipMacroValidation` for unattended runs. Interactive Xcode use relies on the trust prompts above.

## Build and test from command line

```sh
xcodebuild build -project Vistora.xcodeproj -scheme Vistora -derivedDataPath "$PWD/DerivedData" -clonedSourcePackagesDirPath "$PWD/DerivedData/SourcePackages" -skipMacroValidation -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Vistora.xcodeproj -scheme Vistora -derivedDataPath "$PWD/DerivedData" -clonedSourcePackagesDirPath "$PWD/DerivedData/SourcePackages" -skipMacroValidation -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
swift test --package-path Packages/AppFeature
swift test --package-path Packages/Features/ExploreFeature
swift test --package-path Packages/Features/SettingsFeature
swift test --package-path Packages/PhotoAPI
```

## Debug scenarios

The Debug build accepts `-vistora-scenario settings` to launch with the Settings sheet open. Explore is the default screen. The scenario parser is excluded from Release builds.

The Debug-only `-vistora-photo-api` launch argument configures a local photo API fixture for UI tests. `initial-failure` fails every request, producing a first-page error; `six-then-failure` returns six fixture photos on page 1 and fails page 2.

## Unsplash access key

The photo metadata API requires an Unsplash Access Key. Run `./Scripts/bootstrap.sh`, then edit the `UNSPLASH_ACCESS_KEY` string in `App/Resources/UnsplashConfig.plist` directly. Bootstrap creates this Git ignored file from `App/UnsplashConfig.example.plist` only if it does not already exist; it never overwrites your key. Build and install the app after changing the plist.


## Third-party libraries

- **The Composable Architecture (TCA):** TCA defines the app's architecture. Its reducers own state changes and effects, while scoped stores compose the Explore and Settings features. Its dependency system also keeps the Unsplash API client replaceable for previews and tests. Since the app is structured around these TCA concepts, the library is a deliberate architectural dependency rather than an add-on for a single feature.
- **SDWebImageSwiftUI:** The image grid uses `WebImage` to load Unsplash image URLs with memory and disk caching. This avoids repeatedly downloading images as cells leave and re-enter the screen. SwiftUI's `AsyncImage` is available on iOS 17, but it does not provide an image cache that the app can configure for this browsing pattern. The app uses SDWebImageSwiftUI's default cache configuration; no custom cache limits or prefetching are currently implemented.

## Trade-offs and potential improvements

- Settings lets people choose Random or Editorial for Explore. Random requests batches of 30 through Unsplash's [random photo endpoint](https://unsplash.com/documentation#get-a-random-photo); Editorial requests pages of 30 from the [latest photos feed](https://unsplash.com/documentation#list-photos). Changing the choice reloads Explore, while an active search stays visible until it is cleared. Search continues to request 30 results per page.
- The feed choice persists across launches. Photo metadata remains only in memory, so relaunching or changing feeds requests it again. Each metadata request counts against Unsplash's rate limit; image loading uses SDWebImageSwiftUI's default memory and disk cache.
- Pull to refresh functionallity. The app supports two modes, random mode and editorial mode. Having a pull to refresh would be nice, specially in the random mode.

## AI usage

I used ChatGPT in two early conversations: one to explore the app's visual identity, including its logo and colour palette, and another to discuss the architecture. I turned the outcomes into prompts for two separate Codex sessions, which generated an initial empty app skeleton.

From there, I used multiple Codex sessions, each focused on one problem or small feature. This kept the changes small enough to review and avoided generating a large amount of code at once. The smaller context in each session also reduced token use and cost. I used GPT-6 Sol for most sessions and switched to GPT-6 Astra for a few tasks that needed a more capable model.

## Repository guidance

- [AGENTS.md](AGENTS.md) before changing code. 
- Architecture and project documentation are in [Documentation] folder.
