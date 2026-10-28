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

extension CompositionalGridLayout {
    /// 同一集合视图中的五个分区独立选择规则，最后一个分区使用 UIKit 原生横向轮播。
    static func makeSections() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16
        return UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            let insets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16)
            switch index {
            case 0:
                return UIKitLazyVGridLayout.makeSection(
                    columns: Array(repeating: UIKitGridItem(.fixed(72), spacing: 10), count: 3),
                    alignment: .leading, spacing: 8, rowHeight: 48, headerHeight: 32,
                    contentInsets: insets, environment: environment
                )
            case 1:
                return UIKitLazyVGridLayout.makeSection(
                    columns: Array(repeating: UIKitGridItem(.flexible(), spacing: 16), count: 2),
                    spacing: 12, rowHeight: 64, headerHeight: 32,
                    contentInsets: insets, environment: environment
                )
            case 2:
                return UIKitLazyVGridLayout.makeSection(
                    columns: [UIKitGridItem(.adaptive(minimum: 85), spacing: 8)],
                    spacing: 8, rowHeight: 52, headerHeight: 32,
                    contentInsets: insets, environment: environment
                )
            case 3:
                return UIKitLazyVGridLayout.makeSection(
                    columns: [UIKitGridItem(.fixed(60), spacing: 12),
                              UIKitGridItem(.flexible(minimum: 70, maximum: 100), spacing: 12),
                              UIKitGridItem(.adaptive(minimum: 55), spacing: 12)],
                    alignment: .trailing, spacing: 10, rowHeight: 60, headerHeight: 32,
                    contentInsets: insets, environment: environment
                )
            default:
                // 原生 section 可与库生成的网格共存，并使用 UIKit 正交滚动。
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)
                ))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(90)),
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.interGroupSpacing = 12
                section.contentInsets = insets
                section.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(32)),
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top
                )]
                return section
            }
        }, configuration: configuration)
    }
}
