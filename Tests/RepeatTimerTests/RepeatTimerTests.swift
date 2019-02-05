import XCTest
@testable import RepeatTimer

final class RepeatTimerTests: XCTestCase {

    static var allTests = [
        ("testStartAndDeinit", testStartAndDeinit),
        ("testStartAndStop", testStartAndStop),
        ("testStartPauseAndResume", testStartPauseAndResume),
        ("testDeinitOnPaused", testDeinitOnPaused)
    ]

    func testStartAndDeinit() {
        var counter = 0
        let expectation = self.expectation(description: "Counted to 10")
        let timer = RepeatTimer { _ in
            counter += 1
            if counter == 10 {
                expectation.fulfill()
            }
        }
        XCTAssertTrue(timer.state is RepeatTimer.StoppedState)
        timer.start()
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        self.wait(for: [expectation], timeout: 10)
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
    }

    func testStartAndStop() {
        var counter = 0
        let expectation = self.expectation(description: "Counted to 10")
        let timer = RepeatTimer { _ in
            counter += 1
            if counter == 10 {
                expectation.fulfill()
            }
        }
        XCTAssertTrue(timer.state is RepeatTimer.StoppedState)
        timer.start()
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        self.wait(for: [expectation], timeout: 10)
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        timer.stop()
        XCTAssertTrue(timer.state is RepeatTimer.StoppedState)
    }

    func testStartPauseAndResume() {
        var counter = 0
        var expectation = self.expectation(description: "Counted to 10")
        let timer = RepeatTimer { _ in
            counter += 1
            if counter == 10 {
                expectation.fulfill()
            }
        }
        XCTAssertTrue(timer.state is RepeatTimer.StoppedState)
        timer.start()
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        self.wait(for: [expectation], timeout: 10)
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        timer.pause()
        XCTAssertTrue(timer.state is RepeatTimer.PausedState)
        expectation = self.expectation(description: "Counted to 10 again")
        counter = 0
        timer.start()
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        self.wait(for: [expectation], timeout: 10)
    }

    func testDeinitOnPaused() {
        var counter = 0
        let expectation = self.expectation(description: "Counted to 10")
        let timer = RepeatTimer { _ in
            counter += 1
            if counter == 10 {
                expectation.fulfill()
            }
        }
        XCTAssertTrue(timer.state is RepeatTimer.StoppedState)
        timer.start()
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        self.wait(for: [expectation], timeout: 10)
        XCTAssertTrue(timer.state is RepeatTimer.RunningState)
        timer.pause()
    }
}
