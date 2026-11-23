import Foundation

struct UnsplashPhotosImpl: PhotosAPI {
    let accessKey: String?
    let session: URLSession

    init(accessKey: String?, session: URLSession = .shared) {
        self.accessKey = accessKey
        self.session = session
    }

    func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
        let request = try request(for: collection, number: number)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PhotoAPIError.transport
        }
        guard let response = response as? HTTPURLResponse else {
            throw PhotoAPIError.invalidResponse
        }
        let remaining = response.value(forHTTPHeaderField: "X-Ratelimit-Remaining").flatMap(Int.init)
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 429 || (response.statusCode == 403 && remaining == 0) {
                throw PhotoAPIError.rateLimited
            }
            throw PhotoAPIError.httpStatus(response.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            switch collection {
            case .random:
                let photos = try decoder.decode([UnsplashPhotoDTO].self, from: data).map { $0.photo() }
                return PhotoPage(
                    photos: photos,
                    nextPage: photos.isEmpty ? nil : number + 1,
                    remainingRequests: remaining
                )
            case .editorial:
                let photos = try decoder.decode([UnsplashPhotoDTO].self, from: data).map { $0.photo() }
                let hasNext = response.value(forHTTPHeaderField: "Link")?
                    .split(separator: ",")
                    .contains { $0.contains("rel=\"next\"") } ?? false
                return PhotoPage(
                    photos: photos,
                    nextPage: hasNext && !photos.isEmpty ? number + 1 : nil,
                    remainingRequests: remaining
                )
            case .search:
                let result = try decoder.decode(UnsplashSearchDTO.self, from: data)
                let photos = result.results.map { $0.photo() }
                return PhotoPage(
                    photos: photos,
                    nextPage: number < result.totalPages && !photos.isEmpty ? number + 1 : nil,
                    remainingRequests: remaining
                )
            }
        } catch {
            throw PhotoAPIError.invalidResponse
        }
    }

    func request(for collection: PhotoCollection, number: Int) throws -> URLRequest {
        guard let accessKey = accessKey?.trimmingCharacters(in: .whitespacesAndNewlines),
            !accessKey.isEmpty
        else {
            throw PhotoAPIError.missingAccessKey
        }
        guard number > 0 else { throw PhotoAPIError.invalidResponse }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.queryItems = [
            URLQueryItem(name: "page", value: String(number)),
            URLQueryItem(name: "per_page", value: "30"),
        ]
        switch collection {
        case .random:
            components.path = "/photos/random"
            components.queryItems = [URLQueryItem(name: "count", value: "30")]
        case .editorial:
            components.path = "/photos"
        case let .search(query):
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { throw PhotoAPIError.invalidResponse }
            components.path = "/search/photos"
            components.queryItems?.append(URLQueryItem(name: "query", value: query))
        }
        guard let url = components.url else { throw PhotoAPIError.invalidResponse }

        var request = URLRequest(url: url)
        if collection == .random {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        return request
    }
}
