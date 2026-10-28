import SwiftUI
import UIKit

struct UIKitGridView: UIViewControllerRepresentable {
    let configuration: GridConfiguration

    func makeUIViewController(context: Context) -> GridCollectionViewController {
        GridCollectionViewController(configuration: configuration)
    }

    func updateUIViewController(_ controller: GridCollectionViewController, context: Context) {
        controller.update(configuration: configuration)
    }
}

final class GridCollectionViewController: UICollectionViewController {
    private var configuration: GridConfiguration

    init(configuration: GridConfiguration) {
        self.configuration = configuration
        super.init(collectionViewLayout: CompositionalGridLayout.make(configuration: configuration))
    }

    required init?(coder: NSCoder) { fatalError("Use init(configuration:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .secondarySystemGroupedBackground
        // Demo 的容器已在 SwiftUI 安全区域内，关闭额外的滚动 inset 调整。
        // 通用布局包不设置此属性；全屏 UIKit 页面通常由宿主选择 .automatic。
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.accessibilityIdentifier = "uikit.grid"
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(
            GridHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "header"
        )
    }

    func update(configuration: GridConfiguration) {
        guard self.configuration != configuration else { return }
        self.configuration = configuration
        collectionView.setCollectionViewLayout(
            CompositionalGridLayout.make(configuration: configuration),
            animated: false
        )
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        GridConfiguration.sectionCount
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        GridConfiguration.itemsPerSection
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GridCell
        cell.configure(index: indexPath.section * GridConfiguration.itemsPerSection + indexPath.item, axis: configuration.axis)
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "header",
            for: indexPath
        ) as! GridHeader
        header.configure(section: indexPath.section, axis: configuration.axis)
        return header
    }
}

private final class GridCell: UICollectionViewCell {
    private let numberLabel = UILabel()
    private let widthLabel = UILabel()
    private var axis = GridAxis.vertical

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 10
        numberLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        widthLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        widthLabel.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [numberLabel, widthLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    func configure(index: Int, axis: GridAxis) {
        self.axis = axis
        numberLabel.text = String(format: "%02d", index + 1)
        contentView.backgroundColor = GridPalette.uiColor(for: index).withAlphaComponent(0.14)
        numberLabel.textColor = GridPalette.uiColor(for: index)
        accessibilityIdentifier = "uikit.cell.\(index)"
        accessibilityLabel = "项目 \(index + 1)"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        widthLabel.text = String(format: "%.1f", axis == .vertical ? bounds.width : bounds.height)
        accessibilityValue = widthLabel.text
    }
}

private final class GridHeader: UICollectionReusableView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemGroupedBackground
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    func configure(section: Int, axis: GridAxis, customTitle: String? = nil) {
        let title = customTitle ?? (axis == .horizontal ? "S\(section + 1)" : "SECTION \(section + 1) · 18 ITEMS")
        label.text = title
        accessibilityLabel = title
        accessibilityIdentifier = "uikit.header.\(section)"
    }
}

/// 展示 sectionProvider 按分区索引选择不同布局，与原有 SwiftUI 对比页分别运行。
struct SectionLayoutsDemo: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("每个分区独立设置尺寸、间距和对齐；底部为 UIKit 原生横向轮播。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                SectionLayoutsView()
            }
            .navigationTitle("独立分区布局")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("完成") { dismiss() } }
        }
    }
}

private struct SectionLayoutsView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SectionLayoutsController { SectionLayoutsController() }
    func updateUIViewController(_ controller: SectionLayoutsController, context: Context) {}
}

private final class SectionLayoutsController: UICollectionViewController {
    private let titles = ["1 · fixed：3 列 × 72", "2 · flexible：2 列均分", "3 · adaptive：minimum 85",
                          "4 · 混排：fixed + flexible + adaptive", "5 · UIKit 原生横向轮播"]
    private let counts = [6, 4, 8, 8, 5]

    init() { super.init(collectionViewLayout: CompositionalGridLayout.makeSections()) }
    required init?(coder: NSCoder) { fatalError("Use init()") }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.accessibilityIdentifier = "uikit.sections"
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(GridHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "header")
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int { titles.count }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        counts[section]
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GridCell
        cell.configure(index: counts.prefix(indexPath.section).reduce(0, +) + indexPath.item, axis: .vertical)
        cell.accessibilityIdentifier = "sections.cell.\(indexPath.section).\(indexPath.item)"
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header",
                                                                     for: indexPath) as! GridHeader
        header.configure(section: indexPath.section, axis: .vertical, customTitle: titles[indexPath.section])
        return header
    }
}
