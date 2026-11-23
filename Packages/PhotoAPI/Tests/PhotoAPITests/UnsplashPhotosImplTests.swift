import Foundation
@testable import PhotoAPI
import Testing

@Suite(.serialized)
struct UnsplashPhotosAPITests {
    @Test func randomBatchCanLoadAnotherBatchAndPreservesRateLimit() async throws {
        StubURLProtocol.fixture.withLock {
            $0 = .response(
                status: 200,
                headers: [
                    "X-Ratelimit-Remaining": "42",
                ],
                body: "[\(photoJSON("one"))]"
            )
        }

        let page = try await api().page(for: .random, number: 1)
        #expect(page.photos.map(\.id) == ["one"])
        #expect(page.nextPage == 2)
        #expect(page.remainingRequests == 42)
        #expect(page.photos.first?.imageURLs.thumb.absoluteString == "https://example.com/one/thumb?token=keep")
    }

    @Test func randomBatchContinuesWithoutLinkAndStopsWhenEmpty() async throws {
        StubURLProtocol.fixture.withLock {
            $0 = .response(status: 200, headers: [:], body: "[\(photoJSON("one"))]")
        }
        let nextBatch = try await api().page(for: .random, number: 4)
        #expect(nextBatch.nextPage == 5)

        StubURLProtocol.fixture.withLock {
            $0 = .response(
                status: 200,
                headers: [:],
                body: "[]"
            )
        }
        let emptyPage = try await api().page(for: .random, number: 4)
        #expect(emptyPage.photos.isEmpty)
        #expect(emptyPage.nextPage == nil)
    }

    @Test func editorialPaginationUsesLinkHeaderAndPreservesRateLimit() async throws {
        StubURLProtocol.fixture.withLock {
            $0 = .response(
                status: 200,
                headers: [
                    "Link": "<https://api.unsplash.com/photos?page=2>; rel=\"next\"",
                    "X-Ratelimit-Remaining": "42",
                ],
                body: "[\(photoJSON("one"))]"
            )
        }

        let page = try await api().page(for: .editorial, number: 1)
        #expect(page.photos.map(\.id) == ["one"])
        #expect(page.nextPage == 2)
        #expect(page.remainingRequests == 42)

        StubURLProtocol.fixture.withLock {
            $0 = .response(status: 200, headers: [:], body: "[\(photoJSON("two"))]")
        }
        let lastPage = try await api().page(for: .editorial, number: 2)
        #expect(lastPage.nextPage == nil)
    }

    @Test func searchPaginationUsesTotalPagesAndStopsOnEmptyResults() async throws {
        StubURLProtocol.fixture.withLock {
            $0 = .response(
                status: 200,
                headers: [:],
                body: "{\"total_pages\":2,\"results\":[\(photoJSON("one"))]}"
            )
        }
        let firstPage = try await api().page(for: .search("flowers"), number: 1)
        #expect(firstPage.nextPage == 2)

        let lastPage = try await api().page(for: .search("flowers"), number: 2)
        #expect(lastPage.nextPage == nil)

        StubURLProtocol.fixture.withLock {
            $0 = .response(status: 200, headers: [:], body: "{\"total_pages\":3,\"results\":[]}")
        }
        let emptyPage = try await api().page(for: .search("flowers"), number: 1)
        #expect(emptyPage.nextPage == nil)
    }

    @Test func rateLimitAndOtherHTTPStatusesMapToDomainErrors() async {
        for (status, headers, expected) in [
            (429, [String: String](), PhotoAPIError.rateLimited),
            (403, ["X-Ratelimit-Remaining": "0"], PhotoAPIError.rateLimited),
            (403, ["X-Ratelimit-Remaining": "1"], PhotoAPIError.httpStatus(403)),
            (500, [String: String](), PhotoAPIError.httpStatus(500)),
        ] {
            StubURLProtocol.fixture.withLock {
                $0 = .response(status: status, headers: headers, body: "{}")
            }
            await expectPageError(expected) { try await api().page(for: .random, number: 1) }
        }
    }

    @Test func malformedPayloadAndTransportFailureMapToDomainErrors() async {
        StubURLProtocol.fixture.withLock {
            $0 = .response(status: 200, headers: [:], body: "{not-json}")
        }
        await expectPageError(.invalidResponse) {
            try await api().page(for: .random, number: 1)
        }

        StubURLProtocol.fixture.withLock { $0 = .nonHTTPResponse }
        await expectPageError(.invalidResponse) {
            try await api().page(for: .random, number: 1)
        }

        StubURLProtocol.fixture.withLock { $0 = .transportFailure }
        await expectPageError(.transport) {
            try await api().page(for: .random, number: 1)
        }
    }

    @Test func invalidRequestInputsFailBeforeLoading() {
        for key in [nil, "", " \n "] as [String?] {
            expectRequestError(.missingAccessKey) {
                try UnsplashPhotosImpl(accessKey: key).request(for: .random, number: 1)
            }
        }
        expectRequestError(.invalidResponse) {
            try UnsplashPhotosImpl(accessKey: "key").request(for: .random, number: 0)
        }
        expectRequestError(.invalidResponse) {
            try UnsplashPhotosImpl(accessKey: "key").request(for: .search(" \n "), number: 1)
        }
    }

    @Test func exploreRequestUsesTheRandomPhotosEndpoint() throws {
        let request = try UnsplashPhotosImpl(accessKey: "key").request(for: .random, number: 3)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/photos/random")
        #expect(components.queryItems == [URLQueryItem(name: "count", value: "30")])
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func editorialRequestUsesThePagedPhotosEndpoint() throws {
        let request = try UnsplashPhotosImpl(accessKey: "key").request(for: .editorial, number: 3)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/photos")
        #expect(components.queryItems == [
            URLQueryItem(name: "page", value: "3"),
            URLQueryItem(name: "per_page", value: "30"),
        ])
    }

    @Test func missingDescriptionsProduceNoCaption() throws {
        let json = photoJSON("one", altDescription: "   ", description: nil)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let photo = try decoder.decode(UnsplashPhotoDTO.self, from: Data(json.utf8)).photo()
        #expect(photo.caption == nil)
    }

    private func api() -> UnsplashPhotosImpl {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return UnsplashPhotosImpl(accessKey: "key", session: URLSession(configuration: configuration))
    }
}

private enum Fixture: Sendable {
    case response(status: Int, headers: [String: String], body: String)
    case nonHTTPResponse
    case transportFailure
}

private final class StubURLProtocol: URLProtocol {
    static let fixture = LockedFixture()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        switch Self.fixture.withLock({ $0 }) {
        case let .response(status, headers, body):
            guard let url = request.url,
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: status,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .nonHTTPResponse:
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            let response = URLResponse(
                url: url,
                mimeType: "application/json",
                expectedContentLength: 0,
                textEncodingName: nil
            )
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        case .transportFailure:
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        }
    }

    override func stopLoading() {}
}

private final class LockedFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Fixture = .transportFailure

    func withLock<T>(_ operation: (inout Fixture) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation(&value)
    }
}

private func expectPageError(
    _ expected: PhotoAPIError,
    operation: () async throws -> PhotoPage
) async {
    do {
        _ = try await operation()
        Issue.record("Expected \(expected), but the request succeeded")
    } catch let error as PhotoAPIError {
        #expect(error == expected)
    } catch {
        Issue.record("Expected \(expected), but got \(error)")
    }
}

private func expectRequestError(_ expected: PhotoAPIError, operation: () throws -> URLRequest) {
    do {
        _ = try operation()
        Issue.record("Expected \(expected), but the request was created")
    } catch let error as PhotoAPIError {
        #expect(error == expected)
    } catch {
        Issue.record("Expected \(expected), but got \(error)")
    }
}

private func photoJSON(
    _ id: String,
    altDescription: String? = "A photo",
    description: String? = "Fallback"
) -> String {
    let alt = altDescription.map { "\"\($0)\"" } ?? "null"
    let description = description.map { "\"\($0)\"" } ?? "null"
    return """
        {
          "id": "\(id)",
          "alt_description": \(alt),
          "description": \(description),
          "width": 800,
          "height": 600,
          "urls": {
            "thumb": "https://example.com/\(id)/thumb?token=keep",
            "regular": "https://example.com/\(id)/regular?token=keep"
          },
          "user": {
            "name": "Photographer",
            "links": { "html": "https://example.com/photographer" }
          }
        }
        """
}
