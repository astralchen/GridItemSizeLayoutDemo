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

    func testSectionHeadersFootersAndBackgroundsAreLaidOut() throws {
        let controller = SectionLayoutsController()
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 700)
        controller.view.layoutIfNeeded()
        let collection = try XCTUnwrap(controller.collectionView)
        collection.reloadData()
        collection.layoutIfNeeded()
        let layout = collection.collectionViewLayout
        for section in SectionDemoStyle.all.indices {
            let indexPath = IndexPath(item: 0, section: section)
            // 逐段滚动，实际创建 cell、supplementary 和 decoration，捕获注册遗漏。
            collection.scrollToItem(at: indexPath, at: .top, animated: false)
            collection.layoutIfNeeded()
            let header = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader, at: indexPath))
            let footer = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter, at: indexPath))
            let background = try XCTUnwrap(layout.layoutAttributesForDecorationView(
                ofKind: SectionBackgroundView.elementKind, at: indexPath))
            XCTAssertEqual(header.size.height, SectionDemoStyle.all[section].headerHeight)
            XCTAssertEqual(footer.size.height, SectionDemoStyle.all[section].footerHeight)
            XCTAssertLessThan(background.zIndex, header.zIndex)
            XCTAssertGreaterThan(background.frame.height, 0)
        }
    }

    func testPinnedHeaderMovesWhileOrdinaryHeaderStaysInPlace() throws {
        let controller = SectionLayoutsController()
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 500)
        controller.view.layoutIfNeeded()
        let collection = try XCTUnwrap(controller.collectionView)
        collection.reloadData()
        collection.layoutIfNeeded()
        let layout = collection.collectionViewLayout
        let ordinaryPath = IndexPath(item: 0, section: 0)
        let pinnedPath = IndexPath(item: 0, section: 1)
        let kind = UICollectionView.elementKindSectionHeader
        let ordinaryY = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(ofKind: kind, at: ordinaryPath)).frame.minY
        let pinnedY = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(ofKind: kind, at: pinnedPath)).frame.minY
        collection.contentOffset.y = pinnedY + 100
        collection.layoutIfNeeded()
        let ordinaryAfter = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(ofKind: kind, at: ordinaryPath)).frame.minY
        let pinnedAfter = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(ofKind: kind, at: pinnedPath)).frame.minY
        XCTAssertEqual(ordinaryAfter, ordinaryY, accuracy: 0.5)
        XCTAssertGreaterThan(pinnedAfter, pinnedY + 90)
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
