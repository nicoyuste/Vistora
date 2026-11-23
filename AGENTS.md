# Vistora engineering contract

Vistora is an iOS 17+ iPhone and iPad SwiftUI app with English and Spanish localization. Read this file before making changes, then inspect existing implementations before introducing a pattern.

## Stack and structure

- Swift 6 language mode, SwiftUI, TCA, SwiftPM, XcodeGen, Swift Testing, and XCTest for UI tests. Follow versions declared in package manifests and the root lockfile.
- `App/Sources` is the lightweight composition root. Features live in local packages under `Packages/`; the root package composes child packages.
- `project.yml` is the sole Xcode project spec. `Package.swift` files declare dependencies. Never edit `project.pbxproj` or the generated `.xcodeproj`.
- Register local feature packages in `project.yml` for Xcode navigator visibility without adding them as direct app target dependencies.
- Parents may depend on children; children must not depend on parents. Avoid sibling dependencies and circular imports. Keep public APIs small.
- `Packages/DesignSystem` owns shared visual foundations and common UI elements. Feature-specific UI belongs in its owning feature package and should compose shared elements when useful. Read [Design system](Documentation/Design%20System.md) before changing UI. Keep the design system free of feature logic and TCA.

## Feature conventions

- Use `@Reducer`, `@ObservableState`, `StoreOf`, and `ReducerOf` with explicit State and Action types. Scope stores to children. Child-to-parent events use delegate actions when needed.
- Own state in the feature that uses it. Use root state only for composition and genuinely shared choices. Keep business logic and effects out of views.
- Navigation is state-driven. Use tree composition for flows and tabs, `StackState`/`StackAction` for drill-down journeys, and `@Presents`/`PresentationAction` for presentations when those destinations exist. Do not add a competing mutable router.
- Keep domain types independent of SwiftUI/TCA where practical. External effects go through TCA dependencies with live, preview, and test values as appropriate. Use structured concurrency and cancellation; fix concurrency diagnostics instead of suppressing them.
- Construct specific states directly for previews, tests, and Debug launch scenarios. Do not assume all state is serializable or add state restoration without a product requirement.
- Use `VistoraStyle` for shared colours and font styles; keep shared style values in the design system package. Review light and dark previews when changing shared UI. Preserve Dynamic Type and native accessibility behaviour.

## Changes and validation

1. Keep changes scoped to the requested functionality and follow existing naming and package conventions.
2. Add meaningful `TestStore` tests for reducer behavior and representative previews for significant screens. Use XCUITest for critical visible flows.
3. Regenerate with `./Scripts/bootstrap.sh` after changing project configuration. Run builds and tests only when the user explicitly requests them; otherwise state that validation was not run. Report failures and unresolved issues.
4. Update relevant Markdown documentation. Never silently introduce a new architecture pattern or external dependency.

See [Architecture](Documentation/Architecture.md) and [Navigation](Documentation/Navigation.md) for the detailed structure.
