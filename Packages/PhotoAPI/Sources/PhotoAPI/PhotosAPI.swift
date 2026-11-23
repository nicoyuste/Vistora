
/// Fetches photo metadata for Explore or search without exposing the photo provider or transport.
///
/// Implementations return app-facing `PhotoPage` values. The caller decides when to request
/// another batch or page and uses the returned `nextPage` to continue loading.
public protocol PhotosAPI: Sendable {

    /// Fetches one batch or page of photo metadata.
    ///
    /// - Parameters:
    ///   - collection: The random or editorial Explore feed, or a search query to fetch.
    ///   - number: The one-based batch number for random photos or page number otherwise.
    /// - Returns: The photos and continuation information for the request.
    /// - Throws: An error if the response cannot be loaded or decoded.
    func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage
}
