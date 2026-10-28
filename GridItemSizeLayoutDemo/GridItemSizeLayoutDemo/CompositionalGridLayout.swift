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
                itemSize: .fixed(GridConfiguration.rowHeight),
                headerSize: .fixed(GridConfiguration.headerHeight)
            )
        } else {
            return UIKitLazyHGridLayout(
                rows: configuration.uiKitColumns,
                alignment: configuration.verticalAlignment,
                spacing: configuration.rowSpacing,
                pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : [],
                itemSize: .fixed(GridConfiguration.rowHeight),
                headerSize: .fixed(GridConfiguration.headerHeight)
            )
        }
    }
}

extension CompositionalGridLayout {
    /// 同一集合视图中的五个分区独立选择规则，最后一个分区使用 UIKit 原生横向轮播。
    static func makeSections() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            let style = SectionDemoStyle.all[index]
            let section: NSCollectionLayoutSection
            let insets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16)
            switch index {
            case 0:
                section = UIKitLazyVGridLayout.makeSection(
                    columns: Array(repeating: UIKitGridItem(.fixed(72), spacing: 10), count: 3),
                    alignment: .leading, spacing: 8, pinnedViews: style.pinnedViews, itemSize: .fixed(48),
                    headerSize: .fixed(style.headerHeight), footerSize: .fixed(style.footerHeight),
                    contentInsets: insets, environment: environment
                )
            case 1:
                section = UIKitLazyVGridLayout.makeSection(
                    columns: Array(repeating: UIKitGridItem(.flexible(), spacing: 16), count: 2),
                    spacing: 12, pinnedViews: style.pinnedViews, itemSize: .fixed(64),
                    headerSize: .fixed(style.headerHeight), footerSize: .fixed(style.footerHeight),
                    contentInsets: insets, environment: environment
                )
            case 2:
                section = UIKitLazyVGridLayout.makeSection(
                    columns: [UIKitGridItem(.adaptive(minimum: 85), spacing: 8)],
                    spacing: 8, pinnedViews: style.pinnedViews, itemSize: .fixed(52),
                    headerSize: .fixed(style.headerHeight), footerSize: .fixed(style.footerHeight),
                    contentInsets: insets, environment: environment
                )
            case 3:
                section = UIKitLazyVGridLayout.makeSection(
                    columns: [UIKitGridItem(.fixed(60), spacing: 12),
                              UIKitGridItem(.flexible(minimum: 70, maximum: 100), spacing: 12),
                              UIKitGridItem(.adaptive(minimum: 55), spacing: 12)],
                    alignment: .trailing, spacing: 10, pinnedViews: style.pinnedViews, itemSize: .fixed(60),
                    headerSize: .fixed(style.headerHeight), footerSize: .fixed(style.footerHeight),
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
                section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.interGroupSpacing = 12
                section.contentInsets = insets
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .absolute(style.headerHeight)),
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top
                )
                let footer = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .absolute(style.footerHeight)),
                    elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom
                )
                header.pinToVisibleBounds = style.pinnedViews.contains(.sectionHeaders)
                footer.pinToVisibleBounds = style.pinnedViews.contains(.sectionFooters)
                header.zIndex = 2
                footer.zIndex = 2
                section.boundarySupplementaryItems = [header, footer]
            }
            // 背景是 decoration，由 layout 注册；header/footer 是 supplementary，由数据源提供。
            let background = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.elementKind)
            background.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
            background.zIndex = -1
            section.decorationItems = [background]
            return section
        }, configuration: configuration)
        layout.register(SectionBackgroundView.self, forDecorationViewOfKind: SectionBackgroundView.elementKind)
        return layout
    }
}

/// 每个分区分别声明辅助视图尺寸、吸附选项与背景色，布局和数据源共用这些示例参数。
struct SectionDemoStyle {
    let title: String
    let itemCount: Int
    let headerHeight: CGFloat
    let footerHeight: CGFloat
    let pinnedViews: UIKitPinnedScrollableViews
    let color: UIColor

    static let all: [SectionDemoStyle] = [
        .init(title: "fixed · 3 列 × 72", itemCount: 9, headerHeight: 36, footerHeight: 28,
              pinnedViews: [], color: .systemBlue),
        .init(title: "flexible · 2 列均分", itemCount: 16, headerHeight: 44, footerHeight: 32,
              pinnedViews: [.sectionHeaders], color: .systemTeal),
        .init(title: "adaptive · minimum 85", itemCount: 24, headerHeight: 36, footerHeight: 36,
              pinnedViews: [.sectionFooters], color: .systemOrange),
        .init(title: "混排 · fixed + flexible + adaptive", itemCount: 32, headerHeight: 44, footerHeight: 32,
              pinnedViews: [.sectionHeaders, .sectionFooters], color: .systemPurple),
        .init(title: "UIKit 原生横向轮播", itemCount: 5, headerHeight: 36, footerHeight: 28,
              pinnedViews: [], color: .systemPink)
    ]
}

/// 背景由 UICollectionViewCompositionalLayout 创建，不经过数据源的 supplementary 回调。
final class SectionBackgroundView: UICollectionReusableView {
    static let elementKind = "demo.section.background"

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 14
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        backgroundColor = SectionDemoStyle.all[layoutAttributes.indexPath.section].color.withAlphaComponent(0.10)
    }
}
