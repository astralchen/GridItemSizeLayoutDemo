import XCTest

@MainActor
final class GridItemSizeLayoutDemoUITests: XCTestCase {
    func testCustomKindsInBothDirectionsAndEntrypoints() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["show.kinds"].tap()
        for axis in ["纵向", "横向"] {
            app.buttons[axis].tap()
            for factory in [false, true] {
                setSwitch(app, id: "kinds.factory", enabled: factory)
                for kind in ["demo.header", "demo.footer"] {
                    let boundary = element(app, kind)
                    XCTAssertTrue(boundary.waitForExistence(timeout: 5))
                    XCTAssertTrue(boundary.isHittable)
                    XCTAssertEqual(boundary.label, kind)
                }
                capture(app, name: "custom-kinds-\(axis)-factory-\(factory)")
            }
        }
    }

    func testMixedSizingAndWrappingMatchSwiftUI() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["混合"].tap()
        for axis in [Axis.vertical, .horizontal] {
            app.buttons[axis == .vertical ? "VGrid" : "HGrid"].tap()
            setSwitch(app, id: "limit.maximum", enabled: false)
            for extent in ["260 pt", "340 pt", "自适应"] {
                app.buttons[extent].tap()
                assertMatchingCells(app, axis: axis, count: 6)
            }
            // At 340 pt, the cap makes adaptive expand to two 61 pt tracks.
            app.buttons["340 pt"].tap()
            setSwitch(app, id: "limit.maximum", enabled: true)
            assertMatchingCells(app, axis: axis, count: 6)
            capture(app, name: axis == .vertical ? "VGrid-mixed" : "HGrid-mixed")
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testVerticalSizingAndAlignmentMatchSwiftUI() {
        let app = XCUIApplication()
        app.launch()
        for mode in ["fixed", "flexible", "adaptive"] {
            app.buttons[mode].tap()
            for width in ["260 pt", "340 pt", "自适应"] {
                app.buttons[width].tap()
                assertMatchingCells(app, axis: .vertical)
            }
            capture(app, name: "VGrid-\(mode)")
        }
        app.buttons["fixed"].tap()
        for alignment in ["leading", "center", "trailing"] {
            app.buttons[alignment].tap()
            assertMatchingCells(app, axis: .vertical)
        }
    }

    func testHorizontalSizingAndAlignmentMatchSwiftUI() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["HGrid"].tap()
        for mode in ["fixed", "flexible", "adaptive"] {
            app.buttons[mode].tap()
            for height in ["260 pt", "340 pt", "自适应"] {
                app.buttons[height].tap()
                assertMatchingCells(app, axis: .horizontal)
            }
            capture(app, name: "HGrid-\(mode)")
        }
        app.buttons["fixed"].tap()
        for alignment in ["top", "center", "bottom"] {
            app.buttons[alignment].tap()
            assertMatchingCells(app, axis: .horizontal)
        }
    }

    func testMaximumAndSpacingMatchSwiftUI() {
        let app = XCUIApplication()
        app.launch()
        for axis in [Axis.vertical, .horizontal] {
            app.buttons[axis == .vertical ? "VGrid" : "HGrid"].tap()
            for mode in ["flexible", "adaptive"] {
                app.buttons[mode].tap()
                app.buttons[mode == "flexible" ? "自适应" : "260 pt"].tap()
                setSwitch(app, id: "limit.maximum", enabled: true)
                for alignment in axis == .vertical ? ["leading", "center", "trailing"] : ["top", "center", "bottom"] {
                    app.buttons[alignment].tap()
                    assertMatchingCells(app, axis: axis)
                }
            }
            app.sliders["line.spacing"].adjust(toNormalizedSliderPosition: 1)
            assertMatchingCells(app, axis: axis)
        }
    }

    func testPinnedHeadersInBothDirections() {
        let app = XCUIApplication()
        app.launch()
        for axis in [Axis.vertical, .horizontal] {
            app.buttons[axis == .vertical ? "VGrid" : "HGrid"].tap()
            app.buttons["fixed"].tap()
            app.buttons["260 pt"].tap()
            setSwitch(app, id: "pin.headers", enabled: true)
            for framework in ["swiftui", "uikit"] {
                let grid = element(app, "\(framework).grid")
                let header = element(app, "\(framework).header.0")
                XCTAssertTrue(header.waitForExistence(timeout: 5))
                scrollSmall(grid, axis: axis)
                XCTAssertTrue(header.exists)
                let origin = axis == .vertical ? grid.frame.minY : grid.frame.minX
                let headerOrigin = axis == .vertical ? header.frame.minY : header.frame.minX
                XCTAssertEqual(headerOrigin, origin, accuracy: 1, framework)
            }
            setSwitch(app, id: "pin.headers", enabled: false) // 两边回到起点。
            for framework in ["swiftui", "uikit"] {
                let grid = element(app, "\(framework).grid")
                scrollSmall(grid, axis: axis)
                let header = element(app, "\(framework).header.0")
                XCTAssertFalse(header.isHittable, framework)
            }
        }
    }

    private func setSwitch(_ app: XCUIApplication, id: String, enabled: Bool) {
        let control = app.switches[id]
        let value = enabled ? "1" : "0"
        if control.value as? String != value {
            // SwiftUI Toggle 的 AX frame 包含 label 与 switch 之间的空隙；
            // 点右侧实际开关，并断言值真的改变，避免“点击了但没有切换”的假通过。
            control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: control)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed, id)
    }

    private enum Axis { case vertical, horizontal }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func assertMatchingCells(_ app: XCUIApplication, axis: Axis, count: Int = 4) {
        let swiftGrid = element(app, "swiftui.grid")
        let uiGrid = element(app, "uikit.grid")
        for index in 0..<count {
            let swiftCell = element(app, "swiftui.cell.\(index)")
            let uiCell = element(app, "uikit.cell.\(index)")
            XCTAssertTrue(swiftCell.exists || swiftCell.waitForExistence(timeout: 5))
            XCTAssertTrue(uiCell.exists || uiCell.waitForExistence(timeout: 5))
            let s = swiftCell.frame
            let u = uiCell.frame
            XCTAssertEqual(s.width, u.width, accuracy: 1, "cell \(index) width")
            XCTAssertEqual(s.height, u.height, accuracy: 1, "cell \(index) height")
            if axis == .vertical {
                XCTAssertEqual(s.minX - swiftGrid.frame.minX, u.minX - uiGrid.frame.minX, accuracy: 1)
            } else {
                XCTAssertEqual(s.minY - swiftGrid.frame.minY, u.minY - uiGrid.frame.minY, accuracy: 1)
            }
            // 比较主轴相对第一个 cell 的距离，验证换行和行/列间距。
            let s0 = element(app, "swiftui.cell.0").frame
            let u0 = element(app, "uikit.cell.0").frame
            XCTAssertEqual(axis == .vertical ? s.minY - s0.minY : s.minX - s0.minX,
                           axis == .vertical ? u.minY - u0.minY : u.minX - u0.minX,
                           accuracy: 1)
        }
    }

    private func scrollSmall(_ grid: XCUIElement, axis: Axis) {
        let start = grid.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75))
        let end = grid.coordinate(withNormalizedOffset: axis == .vertical
                                  ? CGVector(dx: 0.75, dy: 0.4)
                                  : CGVector(dx: 0.4, dy: 0.75))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
