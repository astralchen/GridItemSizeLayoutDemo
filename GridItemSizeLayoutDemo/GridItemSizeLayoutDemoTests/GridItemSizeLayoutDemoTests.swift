import XCTest
import SwiftUI
import UIKitGridLayouts
@testable import GridItemSizeLayoutDemo

@MainActor
final class GridItemSizeLayoutDemoTests: XCTestCase {
    func testMixedInputsStayEquivalentBetweenFrameworks() {
        var configuration = GridConfiguration()
        configuration.sizing = .mixed
        for capped in [false, true] {
            configuration.limitMaximum = capped
            let swift = configuration.columns
            let ui = configuration.uiKitColumns
            XCTAssertEqual(swift.count, 3)
            XCTAssertEqual(ui.count, 3)
            for (s, u) in zip(swift, ui) {
                XCTAssertEqual(s.spacing, u.spacing)
                switch (s.size, u.size) {
                case let (.fixed(a), .fixed(b)):
                    XCTAssertEqual(a, b)
                case let (.flexible(a, b), .flexible(c, d)),
                     let (.adaptive(a, b), .adaptive(c, d)):
                    XCTAssertEqual(a, c)
                    XCTAssertEqual(b, d)
                default: XCTFail("Both frameworks must receive the same sizing rule")
                }
            }
        }
    }

    func testFactoryUsesLocalPackageForBothAxes() {
        var configuration = GridConfiguration()
        XCTAssertTrue(CompositionalGridLayout.make(configuration: configuration) is UIKitLazyVGridLayout)
        configuration.axis = .horizontal
        let layout = CompositionalGridLayout.make(configuration: configuration)
        XCTAssertTrue(layout is UIKitLazyHGridLayout)
        XCTAssertEqual(layout.configuration.scrollDirection, .horizontal)
    }
}
