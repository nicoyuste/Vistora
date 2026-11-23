# Design system

`Packages/DesignSystem` owns visual foundations and UI elements shared by multiple features. Feature packages depend on it directly when they render UI. The app target continues to link only `AppFeature`; local packages are registered in `project.yml` for Xcode navigator visibility.

## Ownership

- Add reusable colours, typography, spacing, surfaces, controls, and other common UI elements to `DesignSystem` when a concrete use calls for them.
- Keep feature-specific views and styling in the feature package that owns the experience. Build those views from shared design system elements where useful.
- Keep the design system independent of TCA, feature state, navigation, and business logic. 

## Use

`VistoraStyle` exposes background, default, accent, and inverted accent colours, plus four Dynamic Type font styles. The colours adapt to light and dark appearance through named assets. Use them where they apply, and use native SwiftUI foreground and control styling for other needs. Keep literal colour values out of feature views.

Keep text and interactive controls legible on every surface where they appear. Pair status colour with text or a symbol so meaning does not rely on colour alone. Let photographs provide most of the visual variation.