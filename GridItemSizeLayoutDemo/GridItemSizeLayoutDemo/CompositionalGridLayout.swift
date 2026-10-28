import UIKit
import UIKitGridLayouts

/// 示例调用处只描述规则；计算细节由两种布局类型封装。
enum CompositionalGridLayout {
    static func make(configuration: GridConfiguration) -> UICollectionViewCompositionalLayout {
        if configuration.axis == .vertical {
            return UIKitLazyVGridLayout(
                columns: configuration.uiKitTracks,
                alignment: configuration.alignment,
                spacing: configuration.spacing,
                pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : [],
                itemSize: .fixed(GridConfiguration.itemExtent),
                header: .init(elementKind: UICollectionView.elementKindSectionHeader, size: .fixed(GridConfiguration.headerExtent))
            )
        } else {
            return UIKitLazyHGridLayout(
                rows: configuration.uiKitTracks,
                alignment: configuration.verticalAlignment,
                spacing: configuration.spacing,
                pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : [],
                itemSize: .fixed(GridConfiguration.itemExtent),
                header: .init(elementKind: UICollectionView.elementKindSectionHeader, size: .fixed(GridConfiguration.headerExtent))
            )
        }
    }
}

extension CompositionalGridLayout {
    /// 每个分区独立选择规则，最后一个分区沿宿主的正交方向滚动。
    static func makeSections(axis: GridAxis = .vertical) -> UICollectionViewCompositionalLayout {
        let vertical = axis == .vertical
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = vertical ? .vertical : .horizontal
        configuration.interSectionSpacing = 16
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            let style = SectionDemoStyle.styles(for: axis)[index]
            let section: NSCollectionLayoutSection
            let insets = vertical
                ? NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16)
                : NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 12)
            if index < 4 {
                let tracks: [UIKitGridItem]
                let spacing: CGFloat
                let itemExtent: CGFloat
                switch index {
                case 0:
                    tracks = Array(repeating: UIKitGridItem(.fixed(72), spacing: 10), count: 3)
                    spacing = 8; itemExtent = 48
                case 1:
                    tracks = Array(repeating: UIKitGridItem(.flexible(), spacing: 16), count: 2)
                    spacing = 12; itemExtent = 64
                case 2:
                    tracks = [UIKitGridItem(.adaptive(minimum: 85), spacing: 8)]
                    spacing = 8; itemExtent = 52
                default:
                    tracks = [UIKitGridItem(.fixed(60), spacing: 12),
                              UIKitGridItem(.flexible(minimum: 70, maximum: 100), spacing: 12),
                              UIKitGridItem(.adaptive(minimum: 55), spacing: 12)]
                    spacing = 10; itemExtent = 60
                }
                if vertical {
                    section = UIKitLazyVGridLayout.makeSection(
                        columns: tracks, alignment: index == 0 ? .leading : index == 3 ? .trailing : .center,
                        spacing: spacing, pinnedViews: style.pinnedViews, itemSize: .fixed(itemExtent),
                        header: .init(elementKind: UICollectionView.elementKindSectionHeader, size: .fixed(style.headerExtent)), footer: .init(elementKind: UICollectionView.elementKindSectionFooter, size: .fixed(style.footerExtent)),
                        contentInsets: insets, environment: environment
                    )
                } else {
                    section = UIKitLazyHGridLayout.makeSection(
                        rows: tracks, alignment: index == 0 ? .top : index == 3 ? .bottom : .center,
                        spacing: spacing, pinnedViews: style.pinnedViews, itemSize: .fixed(itemExtent),
                        header: .init(elementKind: UICollectionView.elementKindSectionHeader, size: .fixed(style.headerExtent)), footer: .init(elementKind: UICollectionView.elementKindSectionFooter, size: .fixed(style.footerExtent)),
                        contentInsets: insets, environment: environment
                    )
                }
            } else {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)
                ))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: vertical ? .fractionalWidth(0.8) : .absolute(90),
                        heightDimension: vertical ? .absolute(90) : .fractionalHeight(0.8)
                    ), subitems: [item]
                )
                section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.interGroupSpacing = 12
                section.contentInsets = insets
                func boundary(_ header: Bool) -> NSCollectionLayoutBoundarySupplementaryItem {
                    let extent = header ? style.headerExtent : style.footerExtent
                    let boundary = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: vertical ? .fractionalWidth(1) : .absolute(extent),
                            heightDimension: vertical ? .absolute(extent) : .fractionalHeight(1)
                        ),
                        elementKind: header ? UICollectionView.elementKindSectionHeader : UICollectionView.elementKindSectionFooter,
                        alignment: vertical ? (header ? .top : .bottom) : (header ? .leading : .trailing)
                    )
                    boundary.pinToVisibleBounds = style.pinnedViews.contains(header ? .sectionHeaders : .sectionFooters)
                    boundary.zIndex = 2
                    return boundary
                }
                section.boundarySupplementaryItems = [boundary(true), boundary(false)]
            }
            let background = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.elementKind)
            background.contentInsets = vertical
                ? NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
                : NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
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
    let headerExtent: CGFloat
    let footerExtent: CGFloat
    let pinnedViews: UIKitPinnedScrollableViews
    let color: UIColor

    static let all: [SectionDemoStyle] = [
        .init(title: "fixed · 3 列 × 72", itemCount: 9, headerExtent: 36, footerExtent: 28,
              pinnedViews: [], color: .systemBlue),
        .init(title: "flexible · 2 列均分", itemCount: 16, headerExtent: 44, footerExtent: 32,
              pinnedViews: [.sectionHeaders], color: .systemTeal),
        .init(title: "adaptive · minimum 85", itemCount: 24, headerExtent: 36, footerExtent: 36,
              pinnedViews: [.sectionFooters], color: .systemOrange),
        .init(title: "混排 · fixed + flexible + adaptive", itemCount: 32, headerExtent: 44, footerExtent: 32,
              pinnedViews: [.sectionHeaders, .sectionFooters], color: .systemPurple),
        .init(title: "UIKit 原生横向轮播", itemCount: 5, headerExtent: 36, footerExtent: 28,
              pinnedViews: [], color: .systemPink)
    ]

    /// 按滚动方向提供样式；extent 表示主轴长度，纵向为高度，横向为宽度。
    static func styles(for axis: GridAxis) -> [SectionDemoStyle] {
        guard axis == .horizontal else { return all }
        let titles = ["fixed · 3 行 × 72", "flexible · 2 行均分", "adaptive · minimum 85",
                      "混排 · fixed + flexible + adaptive", "UIKit 原生纵向轮播"]
        let counts = [12, 20, 36, 40, 5]
        let headers: [CGFloat] = [72, 64, 56, 80, 64]
        let footers: [CGFloat] = [52, 60, 64, 56, 52]
        return all.enumerated().map { index, style in
            SectionDemoStyle(title: titles[index], itemCount: counts[index],
                             headerExtent: headers[index], footerExtent: footers[index],
                             pinnedViews: style.pinnedViews, color: style.color)
        }
    }

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
