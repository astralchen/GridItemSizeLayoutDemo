import SwiftUI
import UIKit
import UIKitGridLayouts

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
    @State private var axis: GridAxis

    init(initialAxis: GridAxis = .vertical) {
        _axis = State(initialValue: initialAxis)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("分区滚动方向", selection: $axis) {
                    Text("纵向 VGrid").tag(GridAxis.vertical)
                    Text("横向 HGrid").tag(GridAxis.horizontal)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .accessibilityIdentifier("sections.axis")
                Text(axis == .vertical
                     ? "独立页眉、页脚与背景；上下滚动观察吸顶、吸底。末尾可横向滑动。"
                     : "独立页眉、页脚宽度；左右滚动观察起始／结束边缘吸附。末尾可纵向滑动。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                SectionLayoutsView(axis: axis)
            }
            .navigationTitle("独立分区布局")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("完成") { dismiss() } }
        }
    }
}

private struct SectionLayoutsView: UIViewControllerRepresentable {
    let axis: GridAxis
    func makeUIViewController(context: Context) -> SectionLayoutsController { SectionLayoutsController(axis: axis) }
    func updateUIViewController(_ controller: SectionLayoutsController, context: Context) { controller.update(axis: axis) }
}

final class SectionLayoutsController: UICollectionViewController {
    private var axis: GridAxis
    private var styles: [SectionDemoStyle] { SectionDemoStyle.styles(for: axis) }

    init(axis: GridAxis = .vertical) {
        self.axis = axis
        super.init(collectionViewLayout: CompositionalGridLayout.makeSections(axis: axis))
    }

    func update(axis: GridAxis) {
        guard self.axis != axis else { return }
        self.axis = axis
        collectionView.setCollectionViewLayout(CompositionalGridLayout.makeSections(axis: axis), animated: false)
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }
    required init?(coder: NSCoder) { fatalError("Use init()") }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.accessibilityIdentifier = "uikit.sections"
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "cell")
        for kind in [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter] {
            collectionView.register(SectionBoundaryView.self, forSupplementaryViewOfKind: kind,
                                    withReuseIdentifier: "boundary")
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int { styles.count }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        styles[section].itemCount
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GridCell
        let offset = styles.prefix(indexPath.section).reduce(0) { $0 + $1.itemCount }
        cell.configure(index: offset + indexPath.item, axis: axis)
        cell.accessibilityIdentifier = "sections.cell.\(indexPath.section).\(indexPath.item)"
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: "boundary", for: indexPath
        ) as! SectionBoundaryView
        view.configure(section: indexPath.section, axis: axis, isHeader: kind == UICollectionView.elementKindSectionHeader)
        return view
    }
}

/// 同一复用类分别注册为 header 和 footer；每次配置都覆盖文本、颜色和无障碍标识。
private final class SectionBoundaryView: UICollectionReusableView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 8
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    func configure(section: Int, axis: GridAxis, isHeader: Bool) {
        let style = SectionDemoStyle.styles(for: axis)[section]
        let pinned = style.pinnedViews.contains(isHeader ? .sectionHeaders : .sectionFooters)
        let title: String
        if axis == .horizontal {
            let shortTitle = ["fixed\n3 行 × 72", "flexible\n2 行均分", "adaptive\n最小 85", "混排", "原生\n纵向轮播"][section]
            title = isHeader
                ? "\(section + 1)\n\(shortTitle)\n\n页眉\n\(Int(style.headerExtent)) pt\n\(pinned ? "起始吸附" : "不吸附")"
                : "\(style.itemCount) 项\n\n页脚\n\(Int(style.footerExtent)) pt\n\(pinned ? "结束吸附" : "不吸附")"
            label.numberOfLines = 0
            label.textAlignment = .center
        } else {
            title = isHeader
                ? "\(section + 1) · \(style.title) · \(pinned ? "页眉吸顶" : "普通页眉")"
                : "\(style.itemCount) 项 · \(Int(style.footerExtent)) pt 页脚 · \(pinned ? "吸底" : "不吸附")"
            label.numberOfLines = 2
            label.textAlignment = .natural
        }
        label.text = title
        label.textColor = style.color
        accessibilityLabel = title
        accessibilityIdentifier = "sections.\(isHeader ? "header" : "footer").\(section)"
    }
}
