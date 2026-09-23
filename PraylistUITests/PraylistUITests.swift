import XCTest

@MainActor
final class PraylistUITests: XCTestCase {
    func testEnglishOnboardingAndLanguageChoicePersistWithoutTranslatingUserText() {
        let app = launch(["--uitesting", "--reset"], language: "en")
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["onboardingContinue"].label, "Start with these categories")
        XCTAssertTrue(app.buttons["Becoming me"].exists)
        app.buttons["onboardingContinue"].tap()
        let first = app.textViews["firstPrayTitle"].exists ? app.textViews["firstPrayTitle"] : app.textFields["firstPrayTitle"]
        first.tap(); first.typeText("My family trip")
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.textFields["prayField0"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.textFields["prayField0"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["languageSettings"].tap()
        XCTAssertTrue(app.buttons["language-ko"].waitForExistence(timeout: 5))
        app.buttons["language-ko"].tap()
        XCTAssertTrue(app.navigationBars["언어"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.textFields["prayField0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["prayField0"].value as? String, "My family trip")
        XCTAssertTrue(app.staticTexts["Becoming me"].exists)
        XCTAssertTrue(app.buttons["prayerButton"].label.contains("오늘의 기도"))
        app.buttons["settingsButton"].tap()
        app.buttons["languageSettings"].tap()
        app.buttons["language-en"].tap()
        XCTAssertTrue(app.navigationBars["Language"].waitForExistence(timeout: 5))
        app.navigationBars["Language"].buttons.firstMatch.tap()
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["prayerButton"].label.contains("Today's prayer"))
        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.staticTexts["My journey"].waitForExistence(timeout: 5))
        app.buttons["prayer calendar"].tap()
        XCTAssertTrue(app.otherElements["prayerCalendar"].waitForExistence(timeout: 5))
        capture("localization-english-calendar", app: app)
    }

    func testCaptureLocalizedScreenshots() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["PRAYLIST_CAPTURE_SCREENSHOTS"] == "1" || env["TEST_RUNNER_PRAYLIST_CAPTURE_SCREENSHOTS"] == "1" else {
            throw XCTSkip("Release screenshot capture only.")
        }
        let english = (env["PRAYLIST_CAPTURE_LANGUAGE"] ?? env["TEST_RUNNER_PRAYLIST_CAPTURE_LANGUAGE"]) == "en"
        func label(_ ko: String, _ en: String) -> String { english ? en : ko }
        let app = launch(["--screenshots"], language: english ? "en" : "ko")
        XCTAssertTrue(app.textFields["prayField9"].waitForExistence(timeout: 10))
        capture("01-notebook", app: app)
        app.buttons[label("다음 항목", "Next category")].tap()
        app.buttons[label("다음 항목", "Next category")].tap()
        XCTAssertTrue(app.staticTexts[label("가보고 싶은 곳", "Places to go")].exists)
        capture("02-travel", app: app)
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 5))
        capture("03-prayer", app: app)
        app.buttons["Close"].tap()
        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.staticTexts[label("나의 발자취", "My journey")].waitForExistence(timeout: 5))
        capture("04-achievements", app: app)
        app.buttons[label("기도 기록", "prayer calendar")].tap()
        XCTAssertTrue(app.otherElements["prayerCalendar"].waitForExistence(timeout: 5))
        capture("07-prayer-calendar", app: app)
        app.buttons["Close"].tap()
        app.buttons["settingsButton"].tap()
        app.cells.containing(.staticText, identifier: label("매일 기도 알림", "Daily prayer reminder")).firstMatch.tap()
        let toggle = app.switches["reminderToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        capture("05-reminder", app: app)
        app.navigationBars[label("기도 알림", "prayer reminder")].buttons.firstMatch.tap()
        app.buttons[label("카테고리 관리", "Manage categories")].tap()
        app.buttons[label("새 카테고리 생성", "Create a category")].tap()
        XCTAssertTrue(app.textFields[label("예: 배우고 싶은 것", "e.g. Things to learn")].waitForExistence(timeout: 5))
        capture("08-new-category", app: app)
        app.terminate()
        let fresh = launch(["--uitesting", "--reset"], language: english ? "en" : "ko")
        XCTAssertTrue(fresh.buttons["onboardingContinue"].waitForExistence(timeout: 10))
        capture("06-onboarding", app: fresh)
    }

    func testCaptureAllAppScreens() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PRAYLIST_CAPTURE_ALL_SCREENS"] == "1" || environment["TEST_RUNNER_PRAYLIST_CAPTURE_ALL_SCREENS"] == "1" else {
            throw XCTSkip("Complete app-screen capture only.")
        }

        let onboarding = launch(["--uitesting", "--reset"])
        XCTAssertTrue(onboarding.buttons["onboardingContinue"].waitForExistence(timeout: 10))
        capture("01-onboarding-categories", app: onboarding)
        onboarding.buttons["onboardingContinue"].tap()
        XCTAssertTrue(onboarding.textFields["firstPrayTitle"].waitForExistence(timeout: 5) || onboarding.textViews["firstPrayTitle"].exists)
        capture("02-onboarding-first-pray", app: onboarding)
        onboarding.terminate()

        let app = launch(["--screenshots"])
        XCTAssertTrue(app.textFields["prayField9"].waitForExistence(timeout: 10))
        capture("03-main-notebook", app: app)

        app.buttons["achievePray0"].tap()
        XCTAssertTrue(app.buttons["saveAchievementButton"].waitForExistence(timeout: 5))
        capture("04-achievement-answered", app: app)
        app.buttons["Close"].tap()

        app.buttons["다음 항목"].tap()
        XCTAssertTrue(app.staticTexts["갖고 싶은 것"].waitForExistence(timeout: 5))
        app.buttons["achievePray0"].tap()
        XCTAssertTrue(app.buttons["saveAchievementButton"].waitForExistence(timeout: 5))
        capture("05-achievement-new", app: app)
        app.buttons["Close"].tap()

        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 5))
        capture("06-prayer-reading", app: app)
        for _ in 0..<4 {
            XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 5))
            app.buttons["prayerContinueButton"].tap()
        }
        XCTAssertTrue(app.buttons["prayerDoneButton"].waitForExistence(timeout: 5))
        capture("07-prayer-complete", app: app)
        app.buttons["prayerDoneButton"].tap()

        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.staticTexts["나의 발자취"].waitForExistence(timeout: 5))
        capture("08-history-answered", app: app)
        app.buttons["기도 기록"].tap()
        XCTAssertTrue(app.otherElements["prayerCalendar"].waitForExistence(timeout: 5))
        capture("09-history-calendar", app: app)
        app.buttons["Close"].tap()

        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.staticTexts["설정"].waitForExistence(timeout: 5))
        capture("10-settings", app: app)

        app.cells.containing(.staticText, identifier: "매일 기도 알림").firstMatch.tap()
        XCTAssertTrue(app.switches["reminderToggle"].waitForExistence(timeout: 5))
        capture("11-reminder-settings", app: app)
        app.navigationBars["기도 알림"].buttons.firstMatch.tap()

        app.buttons["카테고리 관리"].tap()
        XCTAssertTrue(app.navigationBars["카테고리 관리"].waitForExistence(timeout: 5))
        capture("12-category-management", app: app)
        app.buttons["새 카테고리 생성"].tap()
        XCTAssertTrue(app.navigationBars["새 카테고리"].waitForExistence(timeout: 5))
        capture("13-new-category", app: app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["기본 카테고리"].waitForExistence(timeout: 5))
        capture("14-new-category-defaults", app: app)
        app.buttons["Cancel"].tap()
        app.navigationBars["카테고리 관리"].buttons["Close"].tap()

        app.buttons["languageSettings"].tap()
        XCTAssertTrue(app.navigationBars["언어"].waitForExistence(timeout: 5))
        capture("15-language-settings", app: app)
        app.navigationBars["언어"].buttons.firstMatch.tap()

        app.buttons["사용 방법"].tap()
        XCTAssertTrue(app.navigationBars["사용 방법"].waitForExistence(timeout: 5))
        capture("16-help", app: app)
        app.navigationBars["사용 방법"].buttons.firstMatch.tap()

        app.buttons["개인정보 처리방침"].tap()
        XCTAssertTrue(app.navigationBars["개인정보 처리방침"].waitForExistence(timeout: 5))
        capture("17-privacy", app: app)
    }

    // Opt-in real UI capture. Pauses are intentional reading time for the preview.
    func testCaptureAppPreview() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["PRAYLIST_CAPTURE_PREVIEW"] == "1" || env["TEST_RUNNER_PRAYLIST_CAPTURE_PREVIEW"] == "1" else {
            throw XCTSkip("Release media capture only.")
        }
        let english = (env["PRAYLIST_CAPTURE_LANGUAGE"] ?? env["TEST_RUNNER_PRAYLIST_CAPTURE_LANGUAGE"]) == "en"
        let app = launch(["--screenshots"], language: english ? "en" : "ko")
        XCTAssertTrue(app.textFields["prayField9"].waitForExistence(timeout: 10))
        func scene(_ name: String, hold: TimeInterval) {
            print("PRAYLIST_CAPTURE \(name) \(Date().timeIntervalSince1970)")
            capture("preview-\(name)", app: app)
            Thread.sleep(forTimeInterval: hold)
        }
        scene("notebook", hold: 4)
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts[english ? "Things to have" : "갖고 싶은 것"].waitForExistence(timeout: 5))
        scene("swipe", hold: 2)
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts[english ? "Places to go" : "가보고 싶은 곳"].waitForExistence(timeout: 5))
        scene("travel", hold: 3)
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 5))
        scene("prayer", hold: 5)
        app.buttons[english ? "Close" : "닫기"].tap()
        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.staticTexts[english ? "My journey" : "나의 발자취"].waitForExistence(timeout: 5))
        scene("answers", hold: 4)
        app.buttons[english ? "prayer calendar" : "기도 기록"].tap()
        XCTAssertTrue(app.otherElements["prayerCalendar"].waitForExistence(timeout: 5))
        scene("calendar", hold: 5)
        print("PRAYLIST_CAPTURE end \(Date().timeIntervalSince1970)")
    }

    // Opt in after granting notification permission through the reminder settings test.
    func testDeliveredReminderOpensPrayer() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PRAYLIST_VERIFY_DELIVERY"] == "1" || environment["TEST_RUNNER_PRAYLIST_VERIFY_DELIVERY"] == "1" else {
            throw XCTSkip("Waits for an actual daily reminder; see docs/QA.md.")
        }
        let app = launch(["--uitesting", "--verify-reminder-delivery"])
        XCTAssertTrue(app.buttons["prayerButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["설정"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
        let notification = springboard.staticTexts["마음에 품은 pray를 꺼내 볼 시간"]
        XCTAssertTrue(notification.waitForExistence(timeout: 180))
        capture("notification-center", app: springboard)
        notification.tap()
        let openNotification = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["열기", "Open"])).firstMatch
        if openNotification.waitForExistence(timeout: 2) { openNotification.tap() }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 10))
        capture("notification-opened-prayer", app: app)
    }
    private func capture(_ name: String, app: XCUIApplication) {
        // Wait for page and sheet transitions to settle before release screenshots.
        Thread.sleep(forTimeInterval: 0.7)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
    }
    private func launch(_ arguments: [String], language: String = "ko", resetLanguage: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments + (resetLanguage ? ["--reset-language", "--reset-appearance"] : []) + ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US"]
        app.launch()
        return app
    }
    func testDailyPrayerCompletionAndSameDayReentry() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.buttons["prayerButton"].waitForExistence(timeout: 10))
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["prayerStateReading"].waitForExistence(timeout: 5))
        for _ in 0..<10 {
            let button = app.buttons["prayerContinueButton"]
            guard button.waitForExistence(timeout: 1) else { break }
            button.tap()
            if app.buttons["prayerDoneButton"].exists { break }
        }
        XCTAssertTrue(app.descendants(matching: .any)["prayerStateCompleted"].waitForExistence(timeout: 5))
        let message = app.staticTexts["prayerCompletionMessage"]
        XCTAssertTrue(message.exists)
        let originalMessage = message.label
        XCTAssertFalse(originalMessage.isEmpty)
        XCTAssertTrue([
            "오늘의 pray를 마음에 담았어요.",
            "잠시 멈춘 이 시간을 기억할게요.",
            "오늘도 기도할 자리를 만들었어요.",
            "천천히 돌아온 오늘을 기록했어요.",
            "기도한 오늘을 차분히 남겼어요."
        ].contains(originalMessage))
        XCTAssertEqual(message.label, originalMessage)
        app.buttons["prayerDoneButton"].tap()
        XCTAssertTrue(app.buttons["prayerButton"].label.contains("오늘도"))
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["prayerStateAlreadyPrayed"].waitForExistence(timeout: 5))
        app.buttons["prayerAgainButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["prayerStateReading"].waitForExistence(timeout: 5))
    }
    func testPrayerWriteFailureNeverShowsCompletion() {
        let app = launch(["--uitesting", "--prayer-write-failure"])
        XCTAssertTrue(app.buttons["prayerButton"].waitForExistence(timeout: 10))
        app.buttons["prayerButton"].tap()
        for _ in 0..<10 {
            let button = app.buttons["prayerContinueButton"]
            guard button.waitForExistence(timeout: 1) else { break }
            button.tap()
            if app.buttons["prayerRetrySaveButton"].exists { break }
        }
        XCTAssertTrue(app.descendants(matching: .any)["prayerStateSaveFailed"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["prayerRetrySaveButton"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["prayerStateCompleted"].exists)
    }
    func testPrayerEmptyStateReturnsToNotebook() {
        let app = launch(["--uitesting", "--prayer-empty"])
        XCTAssertTrue(app.buttons["prayerButton"].waitForExistence(timeout: 10))
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.buttons["prayerEmptyDoneButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["첫 pray를 적어볼까요?"].exists)
        app.buttons["prayerEmptyDoneButton"].tap()
        XCTAssertTrue(app.buttons["prayerButton"].waitForExistence(timeout: 5))
    }
    func testPrayerPrimaryActionAtAccessibilityTextSizeAndReduceMotion() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--screenshots", "--reset-language", "--reset-appearance",
            "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityLarge",
            "-UIAccessibilityReduceMotionEnabled", "YES"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["prayerButton"].waitForExistence(timeout: 10))
        app.buttons["prayerButton"].tap()
        let action = app.buttons["prayerContinueButton"]
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        XCTAssertTrue(action.isHittable)
        XCTAssertTrue(app.progressIndicators.firstMatch.exists)
    }
    func testAppearanceSelectionPersistsAcrossRelaunch() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["appearanceSettings"].tap()
        XCTAssertTrue(app.buttons["appearance-dark"].waitForExistence(timeout: 5))
        app.buttons["appearance-dark"].tap()
        XCTAssertTrue(app.buttons["appearance-dark"].isSelected)
        XCTAssertEqual(app.staticTexts["appearanceResolved"].value as? String, "dark")
        app.terminate()
        app.launchArguments = ["--screenshots", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["appearanceSettings"].tap()
        XCTAssertTrue(app.buttons["appearance-dark"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["appearance-dark"].isSelected)
        XCTAssertEqual(app.staticTexts["appearanceResolved"].value as? String, "dark")
    }
    func testAutomaticAppearanceFollowsLiveSystemChange() throws {
        #if PRAYLIST_VERIFY_SYSTEM_APPEARANCE
        let liveAppearanceCheckEnabled = true
        #else
        let liveAppearanceCheckEnabled = false
        #endif
        guard liveAppearanceCheckEnabled else {
            throw XCTSkip("Run with the opt-in environment and toggle Simulator appearance from Light to Dark while this test waits.")
        }
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["appearanceSettings"].tap()
        XCTAssertTrue(app.buttons["appearance-automatic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["appearance-automatic"].isSelected)
        let resolved = app.staticTexts["appearanceResolved"]
        XCTAssertEqual(resolved.value as? String, "light")
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "dark"), object: resolved)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 20), .completed)
    }
    func testOnboardingAchievementPrayerAndRelaunch() {
        let app = launch(["--uitesting", "--reset"])
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 10))
        capture("06-onboarding", app: app)
        app.buttons["onboardingContinue"].tap()
        let first = app.textViews["firstPrayTitle"].exists ? app.textViews["firstPrayTitle"] : app.textFields["firstPrayTitle"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap(); first.typeText("매일 감사하는 사람 되기")
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.textFields["prayField0"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["prayField0"].value as? String, "매일 감사하는 사람 되기")
        app.buttons["achievePray0"].tap()
        XCTAssertTrue(app.buttons["saveAchievementButton"].waitForExistence(timeout: 5))
        app.buttons["saveAchievementButton"].tap()
        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.staticTexts["매일 감사하는 사람 되기"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 5))
        app.buttons["prayerContinueButton"].tap()
        XCTAssertTrue(app.buttons["prayerDoneButton"].waitForExistence(timeout: 5))
        app.buttons["prayerDoneButton"].tap()
        XCTAssertTrue(app.buttons["prayerButton"].label.contains("오늘도"))
        app.textFields["prayField0"].tap()
        app.textFields["prayField0"].typeText(" 매일\n")
        let savedTitle = app.textFields["prayField0"].value as? String
        XCTAssertTrue(savedTitle?.contains("매일") == true)
        app.terminate()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCTAssertTrue(app.textFields["prayField0"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["achievePray0"].label.contains("달성일 보기"))
        XCTAssertTrue(app.buttons["prayerButton"].label.contains("오늘도"))
        XCTAssertEqual(app.textFields["prayField0"].value as? String, savedTitle)
    }
    func testTenRowsVisibleAndSwipeToNextCategory() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.textFields["prayField9"].waitForExistence(timeout: 10))
        let last = app.textFields["prayField9"]
        XCTAssertTrue(last.isHittable)
        XCTAssertLessThan(last.frame.maxY, app.buttons["prayerButton"].frame.minY)
        XCTAssertFalse(app.buttons["addPrayButton"].exists)
        XCTAssertLessThan(app.buttons["historyButton"].frame.maxY, app.staticTexts["되고 싶은 나"].frame.minY)
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["갖고 싶은 것"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["prayField0"].value as? String, "햇살이 드는 작은 작업실")
    }
    func testInlineCreateEditAndDeleteWithoutEditorSheet() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.buttons["다음 항목"].waitForExistence(timeout: 10))
        app.buttons["다음 항목"].tap()
        let field = app.textFields["prayField3"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["새 Pray"].exists)
        field.typeText("가족을 위한 작은 집\n")
        XCTAssertEqual(field.value as? String, "가족을 위한 작은 집")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        field.tap()
        field.typeText(" 함께\n")
        XCTAssertTrue((field.value as? String ?? "").contains("함께"))
        XCTAssertFalse(app.navigationBars["나의 Pray"].exists)
        app.buttons["achievePray3"].tap()
        XCTAssertTrue(app.buttons["pray 삭제"].waitForExistence(timeout: 5))
        app.buttons["pray 삭제"].tap()
        app.sheets.buttons["pray 삭제"].tap()
        XCTAssertTrue(app.textFields["prayField3"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["achievePray3"].exists)
    }
    func testCustomCategoryAndFirstPray() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["카테고리 관리"].tap()
        XCTAssertTrue(app.buttons["새 카테고리 생성"].waitForExistence(timeout: 5))
        app.buttons["새 카테고리 생성"].tap()
        let name = app.textFields["예: 배우고 싶은 것"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        capture("08-new-category", app: app)
        name.tap(); name.typeText("배우고 싶은 것")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["배우고 싶은 것"].waitForExistence(timeout: 5))
        app.navigationBars["카테고리 관리"].buttons["Close"].tap()
        app.navigationBars["설정"].buttons["Close"].tap()
        for _ in 0..<4 { app.buttons["다음 항목"].tap() }
        XCTAssertTrue(app.staticTexts["배우고 싶은 것"].waitForExistence(timeout: 5))
        let field = app.textFields["prayField0"]
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        field.typeText("피아노 한 곡 배우기")
        let entered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "피아노 한 곡 배우기"), object: field)
        XCTAssertEqual(XCTWaiter.wait(for: [entered], timeout: 5), .completed)
        let done = app.keyboards.buttons.matching(NSPredicate(format: "label IN %@", ["완료", "Done", "Return"])).firstMatch
        XCTAssertTrue(done.exists)
        done.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "피아노 한 곡 배우기")
    }
    func testNewCategoryCanUseOnlyMissingDefaultCategories() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        app.buttons["카테고리 관리"].tap()
        app.buttons["새 카테고리 생성"].tap()
        let name = app.textFields["예: 배우고 싶은 것"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertFalse(app.buttons["defaultCategory-sparkles"].exists)
        let category = app.buttons["defaultCategory-heart"]
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        category.tap()
        XCTAssertEqual(name.value as? String, "함께하고 싶은 순간")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["함께하고 싶은 순간"].waitForExistence(timeout: 5))
    }
    func testReleaseScreenshotsAndReminderSettings() {
        let app = launch(["--screenshots"])
        XCTAssertTrue(app.textFields["prayField9"].waitForExistence(timeout: 10))
        capture("01-notebook", app: app)
        app.buttons["다음 항목"].tap()
        app.buttons["다음 항목"].tap()
        XCTAssertTrue(app.staticTexts["가보고 싶은 곳"].exists)
        capture("02-travel", app: app)
        app.buttons["prayerButton"].tap()
        XCTAssertTrue(app.buttons["prayerContinueButton"].waitForExistence(timeout: 5))
        capture("03-prayer", app: app)
        app.buttons["Close"].tap()
        app.buttons["historyButton"].tap()
        XCTAssertTrue(app.staticTexts["나의 발자취"].waitForExistence(timeout: 5))
        capture("04-achievements", app: app)
        app.buttons["기도 기록"].tap()
        XCTAssertTrue(app.otherElements["prayerCalendar"].waitForExistence(timeout: 5))
        capture("07-prayer-calendar", app: app)
        app.buttons["Close"].tap()
        app.buttons["settingsButton"].tap()
        app.cells.containing(.staticText, identifier: "매일 기도 알림").firstMatch.tap()
        let toggle = app.switches["reminderToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
        capture("05-reminder", app: app)
        app.buttons["saveReminderButton"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.firstMatch.waitForExistence(timeout: 5) {
            let allow = springboard.buttons["허용"].exists ? springboard.buttons["허용"] : springboard.buttons["Allow"]
            XCTAssertTrue(allow.exists); allow.tap()
        }
        XCTAssertTrue(app.staticTexts["설정"].waitForExistence(timeout: 5))
        app.cells.containing(.staticText, identifier: "매일 기도 알림").firstMatch.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        app.buttons["saveReminderButton"].tap()
        XCTAssertTrue(app.staticTexts["설정"].waitForExistence(timeout: 5))
    }
}
