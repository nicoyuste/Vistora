import XCTest

@MainActor
final class VistoraUITests: XCTestCase {

    func testLiveEditorialPhotoOpensLoadedFullSizeImage() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)"]
        app.launch()

        let loadedPhoto = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND identifier ENDSWITH %@",
                "explore.photo.",
                ".loaded"
            )
        ).firstMatch
        guard loadedPhoto.waitForExistence(timeout: 30) else {
            XCTFail("A live Unsplash thumbnail did not load; check the bundled UnsplashConfig.plist")
            return
        }
        let photoIdentifier = loadedPhoto.identifier
        let selectedPhoto = app.buttons[photoIdentifier]
        guard selectedPhoto.exists else {
            XCTFail("The loaded thumbnail disappeared before it could be opened")
            return
        }
        selectedPhoto.tap()

        let closeButton = app.buttons.matching(
            NSPredicate(format: "label == %@", "Close photo")
        ).firstMatch
        guard closeButton.waitForExistence(timeout: 10) else {
            XCTFail("The photo viewer did not open")
            return
        }
        let imageLoaded = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "identifier ENDSWITH %@", ".loaded"),
            object: closeButton
        )
        guard XCTWaiter.wait(for: [imageLoaded], timeout: 30) == .completed else {
            XCTFail("The regular-size photo did not report completion. Close button: \(closeButton.identifier)")
            return
        }

        closeButton.tap()
        XCTAssertTrue(selectedPhoto.waitForExistence(timeout: 5))
    }

    func testInitialPhotoRequestFailureShowsErrorAndRetry() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-vistora-photo-api", "initial-failure",
            "-AppleLanguages", "(en)",
        ]
        app.launch()

        let errorTitle = app.staticTexts["Could not load photos."]
        XCTAssertTrue(errorTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Please try again."].exists)
        XCTAssertTrue(app.buttons["Retry"].exists)
    }

    func testNextPageFailureKeepsSixPhotosInThreeColumnGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-vistora-photo-api", "six-then-failure",
            "-AppleLanguages", "(en)",
        ]
        app.launch()

        let settingsButton = app.buttons["explore.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        let gridStepper = app.steppers["settings.gridColumnCount"]
        XCTAssertTrue(gridStepper.waitForExistence(timeout: 5))
        if gridStepper.value as? String == "2" {
            let increment = gridStepper.buttons["settings.gridColumnCount-Increment"]
            if increment.exists {
                increment.tap()
            } else {
                gridStepper.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
                    .withOffset(CGVector(dx: -24, dy: 0))
                    .tap()
            }
        }
        XCTAssertEqual(gridStepper.value as? String, "3")

        app.buttons["Done"].tap()
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        let lastPhoto = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "explore.photo.fixture-6")
        ).firstMatch
        XCTAssertTrue(lastPhoto.waitForExistence(timeout: 5))

        let paginationError = app.descendants(matching: .any)["explore.paginationError"]
        let retry = paginationError.buttons["Retry"]
        if !retry.isHittable {
            app.scrollViews["explore.feed"].swipeUp()
        }
        XCTAssertTrue(paginationError.waitForExistence(timeout: 5))
        XCTAssertTrue(paginationError.staticTexts["Could not load photos."].exists)
        XCTAssertTrue(retry.isHittable)
        XCTAssertGreaterThanOrEqual(paginationError.frame.minY, lastPhoto.frame.maxY)

        app.scrollViews["explore.feed"].swipeDown()
        for number in 1...6 {
            let photo = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "explore.photo.fixture-\(number)")
            ).firstMatch
            XCTAssertTrue(photo.exists)
        }
    }
}
