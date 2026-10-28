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
            let swift = configuration.swiftUITracks
            let ui = configuration.uiKitTracks
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
            XCTAssertEqual(header.size.height, SectionDemoStyle.all[section].headerExtent)
            XCTAssertEqual(footer.size.height, SectionDemoStyle.all[section].footerExtent)
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

    func testHorizontalSectionSupplementaryWidthsAndBackgrounds() throws {
        let controller = SectionLayoutsController(axis: .horizontal)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        controller.view.layoutIfNeeded()
        let collection = try XCTUnwrap(controller.collectionView)
        collection.reloadData()
        collection.layoutIfNeeded()
        let layout = collection.collectionViewLayout
        let styles = SectionDemoStyle.styles(for: .horizontal)
        XCTAssertEqual((layout as? UICollectionViewCompositionalLayout)?.configuration.scrollDirection, .horizontal)
        for section in styles.indices {
            let path = IndexPath(item: 0, section: section)
            collection.scrollToItem(at: path, at: .left, animated: false)
            collection.layoutIfNeeded()
            let header = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader, at: path))
            let footer = try XCTUnwrap(layout.layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter, at: path))
            let background = try XCTUnwrap(layout.layoutAttributesForDecorationView(
                ofKind: SectionBackgroundView.elementKind, at: path))
            XCTAssertEqual(header.size.width, styles[section].headerExtent, accuracy: 0.5)
            XCTAssertEqual(footer.size.width, styles[section].footerExtent, accuracy: 0.5)
            XCTAssertGreaterThan(footer.frame.minX, header.frame.minX)
            XCTAssertLessThan(background.zIndex, header.zIndex)
            XCTAssertGreaterThan(background.size.width, 0)
        }
    }

    func testHorizontalHeaderAndFooterPinIndependently() throws {
        let controller = SectionLayoutsController(axis: .horizontal)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 300, height: 600)
        controller.view.layoutIfNeeded()
        let collection = try XCTUnwrap(controller.collectionView)
        collection.reloadData()
        collection.layoutIfNeeded()
        let layout = collection.collectionViewLayout
        func x(_ kind: String, _ section: Int) throws -> CGFloat {
            try XCTUnwrap(layout.layoutAttributesForSupplementaryView(
                ofKind: kind, at: IndexPath(item: 0, section: section))).frame.minX
        }
        let headerKind = UICollectionView.elementKindSectionHeader
        let footerKind = UICollectionView.elementKindSectionFooter
        let ordinaryX = try x(headerKind, 0)
        let pinnedX = try x(headerKind, 1)
        collection.contentOffset.x = pinnedX + 100
        collection.layoutIfNeeded()
        XCTAssertEqual(try x(headerKind, 0), ordinaryX, accuracy: 0.5)
        XCTAssertGreaterThan(try x(headerKind, 1), pinnedX + 90)
        let start = try x(headerKind, 2)
        collection.contentOffset.x = start + 20
        collection.layoutIfNeeded()
        let footerBefore = try x(footerKind, 2)
        collection.contentOffset.x += 40
        collection.layoutIfNeeded()
        XCTAssertEqual(try x(footerKind, 2) - footerBefore, 40, accuracy: 0.5)
        XCTAssertEqual(try x(headerKind, 2), start, accuracy: 0.5)
    }

    func testSectionAxisSwitchRebuildsLayoutAndResetsScroll() throws {
        let controller = SectionLayoutsController()
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        controller.view.layoutIfNeeded()
        let collection = try XCTUnwrap(controller.collectionView)
        collection.contentOffset.y = 200
        for axis in [GridAxis.horizontal, .vertical] {
            controller.update(axis: axis)
            collection.layoutIfNeeded()
            XCTAssertEqual((collection.collectionViewLayout as? UICollectionViewCompositionalLayout)?.configuration.scrollDirection,
                           axis == .vertical ? .vertical : .horizontal)
            XCTAssertEqual(collection.contentOffset, .zero)
            XCTAssertEqual(collection.numberOfItems(inSection: 0), SectionDemoStyle.styles(for: axis)[0].itemCount)
            let item = try XCTUnwrap(collection.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)))
            XCTAssertEqual(axis == .vertical ? item.size.width : item.size.height, 72, accuracy: 0.5)
        }
    }

    func testSizingDemoMeasuresRealTextAndSupportsAllModes() throws {
        for horizontal in [false, true] {
            let controller = MainAxisSizingController(horizontal: horizontal, mode: .estimated, expanded: false)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
            window.rootViewController = controller
            window.isHidden = false
            defer { window.isHidden = true; window.rootViewController = nil }
            let collection = try XCTUnwrap(controller.collectionView)
            func settle() {
                for _ in 0..<8 {
                    window.layoutIfNeeded()
                    collection.setNeedsLayout()
                    collection.layoutIfNeeded()
                    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
                }
            }
            func frame(_ i: Int = 0) throws -> CGRect {
                try XCTUnwrap(collection.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: i, section: 0))).frame
            }
            func main(_ r: CGRect) -> CGFloat { horizontal ? r.width : r.height }
            settle()
            let initial = try frame()
            controller.update(horizontal: horizontal, mode: .estimated, expanded: true)
            settle()
            XCTAssertGreaterThan(main(try frame()), main(initial))
            controller.update(horizontal: horizontal, mode: .estimated, expanded: false)
            settle()
            XCTAssertEqual(main(try frame()), main(initial), accuracy: 1)
            if #available(iOS 17.0, *) {
                let expected = try [max(main(frame(0)), main(frame(1))), max(main(frame(2)), main(frame(3)))]
                controller.update(horizontal: horizontal, mode: .uniform, expanded: false)
                settle()
                for i in 0..<4 {
                    XCTAssertEqual(main(try frame(i)), expected[i / 2], accuracy: 1)
                }
                controller.update(horizontal: horizontal, mode: .uniform, expanded: true)
                settle()
                XCTAssertEqual(main(try frame(0)), main(try frame(1)), accuracy: 1)
                XCTAssertGreaterThan(main(try frame(0)), expected[0])
            } else {
                XCTAssertFalse(MainAxisSizeMode.availableCases.contains(.uniform))
            }
            controller.update(horizontal: horizontal, mode: .fixed, expanded: true)
            settle()
            XCTAssertEqual(main(try frame()), 80, accuracy: 0.5)
            controller.update(horizontal: horizontal, mode: .ratio, expanded: true)
            settle()
            for i in 0..<2 {
                let r = try frame(i)
                XCTAssertEqual(r.width / r.height, 1.5, accuracy: 0.001)
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
