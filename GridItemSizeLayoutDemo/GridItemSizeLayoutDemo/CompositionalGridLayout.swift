import UIKit
import UIKitGridLayouts

/// 示例调用处只描述规则；计算细节由两种布局类型封装。
enum CompositionalGridLayout {
    static func make(configuration: GridConfiguration) -> UICollectionViewCompositionalLayout {
        if configuration.axis == .vertical {
            return UIKitLazyVGridLayout(
                columns: configuration.uiKitColumns,
                alignment: configuration.alignment,
                spacing: configuration.rowSpacing,
                pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : [],
                rowHeight: GridConfiguration.rowHeight,
                headerHeight: GridConfiguration.headerHeight
            )
        } else {
            return UIKitLazyHGridLayout(
                rows: configuration.uiKitColumns,
                alignment: configuration.verticalAlignment,
                spacing: configuration.rowSpacing,
                pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : [],
                columnWidth: GridConfiguration.rowHeight,
                headerWidth: GridConfiguration.headerHeight
            )
        }
    }
}
