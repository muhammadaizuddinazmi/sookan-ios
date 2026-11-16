//
//  sookanUITests.swift
//  sookanUITests
//
//  Created by Muhammad Aizuddin on 07/08/2026.
//

import XCTest

final class sookanUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testDemoSignInAndSignOut() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        XCTAssertFalse(app.buttons["homeFindPlayers"].exists)
        XCTAssertFalse(app.buttons["homeBookCourt"].exists)
        XCTAssertTrue(app.staticTexts["Today's games"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sookan Arena"].exists)
        XCTAssertTrue(app.staticTexts["Kuala Lumpur Sports Hall"].exists)
        XCTAssertTrue(app.staticTexts["Green Court Center"].exists)
        app.buttons["viewAllAcceptedGames"].tap()
        XCTAssertTrue(app.staticTexts["Sookan Sports Center"].waitForExistence(timeout: 5))
        app.buttons["showFewerAcceptedGames"].tap()
        XCTAssertTrue(app.buttons["viewAllAcceptedGames"].waitForExistence(timeout: 5))
        let greeting = app.staticTexts["profileGreeting"]
        XCTAssertTrue(greeting.waitForExistence(timeout: 5))
        XCTAssertTrue(greeting.label.contains("demo@sookan.app"))
        XCTAssertTrue(app.buttons["locationPermissionButton"].exists)

        app.buttons["tab-activity"].tap()
        XCTAssertTrue(app.staticTexts["Sookan Sports Center"].waitForExistence(timeout: 5))

        app.buttons["tab-explore"].tap()
        XCTAssertTrue(app.staticTexts["Choose your sport"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["exploreSport-Badminton"].exists)

        app.buttons["tab-profile"].tap()
        XCTAssertTrue(app.textFields["profileDisplayNameField"].waitForExistence(timeout: 5))
        app.buttons["saveProfileButton"].tap()
        app.buttons["signOutButton"].tap()
        XCTAssertTrue(app.buttons["tryDemoAccount"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testManagerPublishesCourtAndPlayerBooksAvailableTime() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tryManagerAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        XCTAssertTrue(app.staticTexts["Manage your courts."].waitForExistence(timeout: 5))

        app.buttons["addCourtListing"].tap()
        let venueNameField = app.textFields["venueNameField"]
        XCTAssertTrue(venueNameField.waitForExistence(timeout: 5))
        venueNameField.tap()
        venueNameField.typeText("Test Sports Hall")
        let courtNameField = app.textFields["courtNameField"]
        courtNameField.tap()
        courtNameField.typeText("Court 1")
        let addressField = app.textFields["venueAddressField"]
        addressField.tap()
        addressField.typeText("Kuala Lumpur")
        app.buttons["publishCourtListing"].tap()

        XCTAssertTrue(app.staticTexts["Test Sports Hall"].waitForExistence(timeout: 5))
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'addAvailability-'")
        ).firstMatch.tap()
        app.buttons["publishAvailability"].tap()
        XCTAssertTrue(app.staticTexts["Available"].waitForExistence(timeout: 5))

        app.buttons["tab-profile"].tap()
        app.buttons["signOutButton"].tap()
        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["tab-explore"].tap()
        app.buttons["exploreCourts"].tap()

        XCTAssertTrue(app.staticTexts["Test Sports Hall"].waitForExistence(timeout: 5))
        let bookButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'bookSlot-'")
        ).firstMatch
        XCTAssertTrue(bookButton.waitForExistence(timeout: 5))
        bookButton.tap()
        XCTAssertTrue(app.alerts["Booking confirmed"].waitForExistence(timeout: 5))
        app.alerts.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Your bookings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Test Sports Hall · Court 1"].exists)
        XCTAssertTrue(app.staticTexts["No available times"].waitForExistence(timeout: 5))

        app.buttons["tab-activity"].tap()
        XCTAssertTrue(app.staticTexts["Court booked"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Test Sports Hall"].exists)
        app.buttons["tab-home"].tap()
        app.buttons["Go back"].tap()
        app.buttons["tab-profile"].tap()
        app.buttons["signOutButton"].tap()
        app.buttons["tryManagerAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        XCTAssertTrue(app.staticTexts["Booked · demo@sookan.app"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeeAllOpensPlayerDiscovery() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["tab-explore"].tap()
        app.buttons["exploreSport-Tennis"].tap()
        app.buttons["explorePlayers"].tap()

        XCTAssertTrue(app.staticTexts["Players nearby"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["discoverySport"].label.contains("TENNIS"))
    }

    @MainActor
    func testAllCustomTabsAreInteractiveAndKeepTheirNavigationState() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["tab-explore"].tap()
        app.buttons["explorePlayers"].tap()
        XCTAssertTrue(app.staticTexts["Players nearby"].waitForExistence(timeout: 5))

        app.buttons["tab-home"].tap()
        app.buttons["tab-explore"].tap()
        XCTAssertTrue(app.staticTexts["Players nearby"].waitForExistence(timeout: 5))

        app.buttons["tab-activity"].tap()
        XCTAssertTrue(app.staticTexts["ACTIVITY"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your activity"].exists)
        app.buttons["tab-chat"].tap()
        XCTAssertTrue(app.staticTexts["Chat is coming soon"].waitForExistence(timeout: 5))
        app.buttons["tab-profile"].tap()
        XCTAssertTrue(app.staticTexts["ACCOUNT TYPE"].waitForExistence(timeout: 5))
        app.buttons["tab-home"].tap()
        XCTAssertTrue(app.staticTexts["profileGreeting"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDemoConnectionRequestEndToEnd() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["tab-explore"].tap()
        app.buttons["explorePlayers"].tap()

        let ainaConnectButton = app.buttons["connect-aina@sookan.app"]
        XCTAssertTrue(ainaConnectButton.waitForExistence(timeout: 5))
        ainaConnectButton.tap()
        XCTAssertEqual(ainaConnectButton.label, "Connection sent")

        app.buttons["Go back"].tap()
        app.buttons["tab-home"].tap()
        let notificationsButton = app.buttons["homeNotifications"]
        notificationsButton.tap()
        XCTAssertTrue(app.staticTexts["NOTIFICATIONS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Aina N."].waitForExistence(timeout: 5))

        app.buttons["tab-profile"].tap()
        app.buttons["signOutButton"].tap()

        app.buttons["tryAinaAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["homeNotifications"].tap()
        XCTAssertTrue(app.staticTexts["demo@sookan.app"].waitForExistence(timeout: 5))
        app.buttons["acceptConnectionRequest"].tap()
        XCTAssertTrue(app.staticTexts["Connected"].waitForExistence(timeout: 5))

        app.buttons["tab-profile"].tap()
        app.buttons["signOutButton"].tap()
        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["tab-explore"].tap()
        app.buttons["explorePlayers"].tap()

        let inviteButton = app.buttons["connect-aina@sookan.app"]
        XCTAssertEqual(inviteButton.label, "Invite")
        inviteButton.tap()
        XCTAssertTrue(app.staticTexts["Invite Aina N."].waitForExistence(timeout: 5))
        let venueField = app.textFields["gameInvitationVenueField"]
        venueField.tap()
        venueField.typeText("KL Sports Hub")
        app.buttons["sendGameInvitationButton"].tap()
        XCTAssertEqual(app.buttons["connect-aina@sookan.app"].label, "Invite sent")

        app.buttons["Go back"].tap()
        app.buttons["tab-home"].tap()
        app.buttons["homeNotifications"].tap()

        app.buttons["tab-profile"].tap()
        app.buttons["signOutButton"].tap()

        app.buttons["tryAinaAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        app.buttons["homeNotifications"].tap()
        let acceptGameButton = app.buttons["acceptGameInvitation"]
        for _ in 0..<6 {
            if acceptGameButton.isHittable {
                break
            }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["KL Sports Hub"].waitForExistence(timeout: 5))
        acceptGameButton.tap()
        XCTAssertTrue(app.staticTexts["Accepted"].waitForExistence(timeout: 5))

        app.buttons["Go back"].tap()
        app.buttons["tab-home"].tap()
        XCTAssertTrue(app.staticTexts["KL Sports Hub"].waitForExistence(timeout: 5))
        let cancelGameButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'cancelHomeGame-'")
        ).firstMatch
        for _ in 0..<4 {
            if cancelGameButton.exists {
                break
            }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(cancelGameButton.waitForExistence(timeout: 5))
        cancelGameButton.tap()
        app.buttons["confirmHomeGameCancellation"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["Accepted game invitations will appear here."]
                .waitForExistence(timeout: 5)
        )
        app.buttons["tab-profile"].tap()
        app.buttons["signOutButton"].tap()
        app.buttons["tryDemoAccount"].tap()
        app.buttons["authSubmitButton"].tap()
        XCTAssertTrue(app.staticTexts["Today's games"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sookan Arena"].exists)
        app.buttons["homeNotifications"].tap()
        for _ in 0..<8 {
            if app.staticTexts["Cancelled by Aina N."].exists {
                break
            }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Cancelled by Aina N."].exists)
        app.buttons["Go back"].tap()
        app.buttons["tab-activity"].tap()
        XCTAssertTrue(app.staticTexts["Game invitation sent"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Accepted"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Cancelled by Aina N."].exists)
        XCTAssertTrue(app.staticTexts["KL Sports Hub"].exists)
        XCTAssertTrue(app.staticTexts["Connection request sent"].exists)
        app.buttons["tab-explore"].tap()
        app.buttons["explorePlayers"].tap()
        XCTAssertEqual(app.buttons["connect-aina@sookan.app"].label, "Invite")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
