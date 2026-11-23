import ComposableArchitecture
import Foundation

extension DependencyValues {
    public var photosAPI: any PhotosAPI {
        get { self[PhotosAPIKey.self] }
        set { self[PhotosAPIKey.self] = newValue }
    }
}

private enum PhotosAPIKey: DependencyKey {

    // Photos API that is returned when the app is ran in production or in debug builds
    static var liveValue: any PhotosAPI {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "-vistora-photo-api"),
                arguments.indices.contains(index + 1),
                let scenario = TestingScenario(rawValue: arguments[index + 1])
            {
                return TestingPhotosImpl(scenario: scenario)
            }
        #endif
        return UnsplashPhotosImpl(accessKey: bundledAccessKey)
    }

    private static var bundledAccessKey: String? {
        guard let url = Bundle.main.url(forResource: "UnsplashConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else {
            return nil
        }
        return values["UNSPLASH_ACCESS_KEY"]
    }

    // Photos API that is returned for SwitUI Previews
    static var previewValue: any PhotosAPI { EmptyPhotosImpl() }

    // Photos API that is returned while running unit tests
    static var testValue: any PhotosAPI { EmptyPhotosImpl() }
}
