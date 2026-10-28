import SwiftUI
import UIKitGridLayouts

enum GridAxis: String, CaseIterable, Identifiable {
    case vertical = "VGrid"
    case horizontal = "HGrid"
    var id: Self { self }
}

enum GridSizing: String, CaseIterable, Identifiable {
    case fixed, flexible, adaptive
    case mixed = "混合"
    var id: Self { self }

    var explanation: String {
        switch self {
        case .fixed: return "固定 3 列，每列 72 pt；容器变宽时列宽不变。"
        case .flexible: return "固定 3 列，平分扣除列间距后的宽度，最小 64 pt。"
        case .adaptive: return "每列最小 80 pt，按容器宽度自动增减列数。"
        case .mixed: return "混合：固定 70 + 弹性 80…140 + 自适应最小 60；列间距 12 pt。"
        }
    }
}

typealias GridAlignment = UIKitGridAlignment

extension UIKitGridAlignment {
    var swiftUI: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

enum PreviewWidth: String, CaseIterable, Identifiable {
    case compact = "260 pt"
    case medium = "340 pt"
    case available = "自适应"
    var id: Self { self }

    func resolve(available: CGFloat) -> CGFloat {
        switch self {
        case .compact: return min(260, available)
        case .medium: return min(340, available)
        case .available: return available
        }
    }
}

/// 两个框架只共享输入参数；SwiftUI 的列宽由真正的 LazyVGrid 自行计算。
struct GridConfiguration: Hashable {
    var axis: GridAxis = .vertical
    var sizing: GridSizing = .fixed
    var alignment: GridAlignment = .center
    var rowSpacing: CGFloat = 12
    var pinHeaders = true
    var limitMaximum = false

    static let columnSpacing: CGFloat = 12
    static let rowHeight: CGFloat = 56
    static let headerHeight: CGFloat = 28
    static let itemsPerSection = 18
    static let sectionCount = 2

    var verticalAlignment: UIKitGridVerticalAlignment {
        switch alignment {
        case .leading: return .top
        case .center: return .center
        case .trailing: return .bottom
        }
    }

    var swiftUIVerticalAlignment: VerticalAlignment {
        switch alignment {
        case .leading: return .top
        case .center: return .center
        case .trailing: return .bottom
        }
    }

    var alignmentName: String {
        axis == .vertical ? alignment.rawValue : verticalAlignment.rawValue
    }

    var explanation: String {
        let text = sizing == .mixed && limitMaximum
            ? "混合：固定 70 + 弹性 80…112 + 自适应 60…112；列间距 12 pt。"
            : sizing.explanation
        return axis == .vertical ? text
            : text.replacingOccurrences(of: "列", with: "行")
                .replacingOccurrences(of: "宽", with: "高")
    }

    var maximum: CGFloat { limitMaximum ? 112 : .infinity }

    var columns: [GridItem] {
        let size: GridItem.Size
        switch sizing {
        case .mixed:
            return [
                GridItem(.fixed(70), spacing: Self.columnSpacing),
                GridItem(.flexible(minimum: 80, maximum: min(140, maximum)), spacing: Self.columnSpacing),
                GridItem(.adaptive(minimum: 60, maximum: maximum), spacing: Self.columnSpacing)
            ]
        case .fixed: size = .fixed(72)
        case .flexible: size = .flexible(minimum: 64, maximum: maximum)
        case .adaptive: size = .adaptive(minimum: 80, maximum: maximum)
        }
        return Array(
            repeating: GridItem(size, spacing: Self.columnSpacing),
            count: sizing == .adaptive ? 1 : 3
        )
    }

    var uiKitColumns: [UIKitGridItem] {
        let size: UIKitGridItem.Size
        switch sizing {
        case .mixed:
            return [
                UIKitGridItem(.fixed(70), spacing: Self.columnSpacing),
                UIKitGridItem(.flexible(minimum: 80, maximum: min(140, maximum)), spacing: Self.columnSpacing),
                UIKitGridItem(.adaptive(minimum: 60, maximum: maximum), spacing: Self.columnSpacing)
            ]
        case .fixed: size = .fixed(72)
        case .flexible: size = .flexible(minimum: 64, maximum: maximum)
        case .adaptive: size = .adaptive(minimum: 80, maximum: maximum)
        }
        return Array(
            repeating: UIKitGridItem(size, spacing: Self.columnSpacing),
            count: sizing == .adaptive ? 1 : 3
        )
    }

    private func columnCode(type: String) -> String {
        let maximumText = limitMaximum ? "112" : ".infinity"
        switch sizing {
        case .fixed:
            return "Array(repeating: \(type)(.fixed(72), spacing: 12), count: 3)"
        case .flexible:
            return "Array(repeating: \(type)(.flexible(minimum: 64, maximum: \(maximumText)), spacing: 12), count: 3)"
        case .adaptive:
            return "[\(type)(.adaptive(minimum: 80, maximum: \(maximumText)), spacing: 12)]"
        case .mixed:
            return """
            [
                \(type)(.fixed(70), spacing: 12),
                \(type)(.flexible(minimum: 80, maximum: \(limitMaximum ? "112" : "140")), spacing: 12),
                \(type)(.adaptive(minimum: 60, maximum: \(maximumText)), spacing: 12)
            ]
            """
        }
    }

    var swiftUICode: String {
        let tracks = axis == .vertical ? "columns" : "rows"
        let grid = axis == .vertical ? "LazyVGrid" : "LazyHGrid"
        return """
        let \(tracks) = \(columnCode(type: "GridItem"))

        ScrollView(\(axis == .vertical ? ".vertical" : ".horizontal")) {
            \(grid)(
                \(tracks): \(tracks),
                alignment: .\(alignmentName),
                spacing: \(Int(rowSpacing)),
                pinnedViews: \(pinHeaders ? "[.sectionHeaders]" : "[]")
            ) {
                Section {
                    ForEach(items) { item in
                        Cell(item: item).frame(\(axis == .vertical ? "height" : "width"): 56)
                    }
                } header: {
                    Text("分组标题").frame(\(axis == .vertical ? "height" : "width"): 28)
                }
            }
        }
        """
    }

    var uiKitCode: String {
        let tracks = axis == .vertical ? "columns" : "rows"
        let grid = axis == .vertical ? "UIKitLazyVGridLayout" : "UIKitLazyHGridLayout"
        return """
        let \(tracks) = \(columnCode(type: "UIKitGridItem"))

        let layout = \(grid)(
            \(tracks): \(tracks),
            alignment: .\(alignmentName),
            spacing: \(Int(rowSpacing)),
            pinnedViews: \(pinHeaders ? "[.sectionHeaders]" : "[]"),
            \(axis == .vertical ? "rowHeight" : "columnWidth"): 56,
            \(axis == .vertical ? "headerHeight" : "headerWidth"): 28
        )

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        // 注册 cell、header，并设置 dataSource。
        // 数据源提供的内容对应 LazyVGrid.content。
        """
    }
}

enum GridPalette {
    static func uiColor(for index: Int) -> UIColor {
        [.systemBlue, .systemTeal, .systemIndigo, .systemOrange, .systemPink, .systemPurple][index % 6]
    }
}
