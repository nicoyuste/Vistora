import ComposableArchitecture
import Foundation

#if DEBUG
    package enum TestingScenario: String, Sendable {
        case initialFailure = "initial-failure"
        case sixThenFailure = "six-then-failure"
    }

    package struct TestingPhotosImpl: PhotosAPI {
        private let responses: [Int: Result<PhotoPage, PhotoAPIError>]

        init(scenario: TestingScenario) {
            switch scenario {
            case .initialFailure:
                responses = [1: .failure(.transport)]
            case .sixThenFailure:
                responses = [
                    1: .success(Self.sixPhotosPage()),
                    2: .failure(.transport),
                ]
            }
        }

        package func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
            guard collection == .random, let response = responses[number] else {
                throw PhotoAPIError.invalidResponse
            }
            return try response.get()
        }

        private static func sixPhotosPage() -> PhotoPage {
            let unavailableImage = URL(fileURLWithPath: "/dev/null")
            let photographer = Photographer(
                name: "Fixture photographer",
                profileURL: URL(string: "https://example.invalid/fixture")!
            )
            let photos = (1...6).map { number in
                Photo(
                    id: "fixture-\(number)",
                    caption: "Fixture photo \(number)",
                    width: 800,
                    height: 600,
                    imageURLs: PhotoImageURLs(thumb: unavailableImage, regular: unavailableImage),
                    photographer: photographer
                )
            }
            return PhotoPage(photos: photos, nextPage: 2)
        }
    }
#endif

