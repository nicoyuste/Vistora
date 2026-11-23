import ComposableArchitecture
import Foundation

package struct EmptyPhotosImpl: PhotosAPI {
    package func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
        PhotoPage(photos: [], nextPage: nil)
    }
}
