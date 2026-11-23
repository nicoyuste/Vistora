import SwiftUI

public enum VistoraStyle {
    /// The app background, white in light appearance and deep green in dark appearance.
    public static let backgroundColor = Color("Background", bundle: .module)

    /// The app's default surface, resolved for the current appearance.
    public static let defaultColor = Color("Default", bundle: .module)

    /// The brand interaction colour, resolved for the current appearance.
    public static let accentColor = Color("Accent", bundle: .module)

    /// Text on the accent colour, resolved for the current appearance.
    public static let invertedAccentColor = Color("InvertedAccent", bundle: .module)

    public enum Fonts {
        public static let title: Font = .largeTitle.bold()
        public static let secondaryTitle: Font = .title2.bold()
        public static let body: Font = .body
        public static let caption: Font = .caption.bold()
    }
}
