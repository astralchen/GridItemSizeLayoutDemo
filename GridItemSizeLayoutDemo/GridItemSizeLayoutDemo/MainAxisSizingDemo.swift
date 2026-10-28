import SwiftUI
import UIKitGridLayouts

/// 单独展示主轴策略，原有 SwiftUI / UIKit 轨道对比页仍保持相同的固定主轴尺寸。
struct MainAxisSizingDemo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var horizontal = false
    @State private var mode = MainAxisSizeMode.estimated
    @State private var expanded = false

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        _expanded = State(initialValue: args.contains("--grid-expanded"))
        if let index = args.firstIndex(of: "--grid-sizing-mode"), index + 1 < args.count,
           args[index + 1] == "uniform", #available(iOS 17.0, *) {
            _mode = State(initialValue: .uniform)
        }
        if let index = args.firstIndex(of: "--grid-axis"), index + 1 < args.count {
            _horizontal = State(initialValue: args[index + 1] == "horizontal")
        }
        #endif
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("滚动方向", selection: $horizontal) {
                    Text("纵向 · 高度").tag(false)
                    Text("横向 · 宽度").tag(true)
                }.pickerStyle(.segmented)
                Picker("主轴尺寸", selection: $mode) {
                    ForEach(MainAxisSizeMode.availableCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                Text("itemSize: \(mode.code)")
                    .font(.system(.subheadline, design: .monospaced))
                Text(mode.explanation)
                    .font(.footnote).foregroundStyle(.secondary)
                Toggle("增加内容", isOn: $expanded)
                    .accessibilityIdentifier("sizing.expand")
                MainAxisSizingView(horizontal: horizontal, mode: mode, expanded: expanded)
            }
            .padding(.horizontal)
            .navigationTitle("主轴尺寸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("完成") { dismiss() } }
        }
    }
}

enum MainAxisSizeMode: String, CaseIterable, Identifiable {
    case fixed = "固定", estimated = "自适应", uniform = "同组统一", ratio = "宽高比"
    static var availableCases: [Self] {
        if #available(iOS 17.0, *) { return allCases }
        return allCases.filter { $0 != .uniform }
    }
    var id: Self { self }
    var size: UIKitGridSize {
        switch self {
        case .fixed: .fixed(80)
        case .estimated: .estimated(80)
        case .uniform:
            if #available(iOS 17.0, *) { .uniform(estimated: 80) }
            else { preconditionFailure("Uniform sizing requires iOS 17.") }
        case .ratio: .aspectRatio(1.5)
        }
    }
    var code: String {
        switch self {
        case .fixed: ".fixed(80)"
        case .estimated: ".estimated(80)"
        case .uniform: ".uniform(estimated: 80)"
        case .ratio: ".aspectRatio(1.5)"
        }
    }
    var explanation: String {
        switch self {
        case .fixed: "每个 cell 的主轴尺寸固定为 80 pt。增加内容不会改变尺寸。"
        case .estimated: "纵向根据文字换行计算高度，横向根据单行文字计算宽度。同组 cell 可有不同尺寸，下一组从最长项之后开始。"
        case .uniform: "iOS 17+：先按内容测量，纵向同一行等高，横向同一列等宽。每组独立采用最大尺寸。"
        case .ratio: "宽 ÷ 高 = 1.5。纵向高度 = 列宽 ÷ 1.5；横向宽度 = 行高 × 1.5。"
        }
    }
}

private struct MainAxisSizingView: UIViewControllerRepresentable {
    let horizontal: Bool
    let mode: MainAxisSizeMode
    let expanded: Bool
    func makeUIViewController(context: Context) -> MainAxisSizingController {
        MainAxisSizingController(horizontal: horizontal, mode: mode, expanded: expanded)
    }
    func updateUIViewController(_ controller: MainAxisSizingController, context: Context) {
        controller.update(horizontal: horizontal, mode: mode, expanded: expanded)
    }
}

final class MainAxisSizingController: UICollectionViewController {
    private(set) var horizontal: Bool
    private(set) var mode: MainAxisSizeMode
    private(set) var expanded: Bool

    init(horizontal: Bool, mode: MainAxisSizeMode, expanded: Bool) {
        self.horizontal = horizontal
        self.mode = mode
        self.expanded = expanded
        super.init(collectionViewLayout: Self.layout(horizontal: horizontal, mode: mode))
    }
    required init?(coder: NSCoder) { fatalError("Use init(horizontal:mode:expanded:)") }

    private static func layout(horizontal: Bool, mode: MainAxisSizeMode) -> UICollectionViewLayout {
        if horizontal {
            return UIKitLazyHGridLayout(
                rows: [UIKitGridItem(.fixed(70)), UIKitGridItem(.fixed(90))], alignment: .top,
                spacing: 12, itemSize: mode.size, headerSize: .estimated(44), footerSize: .estimated(44)
            )
        }
        return UIKitLazyVGridLayout(
            columns: [UIKitGridItem(.flexible()), UIKitGridItem(.flexible())], alignment: .leading,
            spacing: 12, pinnedViews: [.sectionHeaders], itemSize: mode.size,
            headerSize: .estimated(44), footerSize: .estimated(44)
        )
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemBackground
        collectionView.accessibilityIdentifier = "sizing.collection"
        collectionView.register(SizingDemoCell.self, forCellWithReuseIdentifier: "cell")
        for kind in [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter] {
            collectionView.register(SizingDemoBoundary.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: "boundary")
        }
    }
    func update(horizontal: Bool, mode: MainAxisSizeMode, expanded: Bool) {
        guard self.horizontal != horizontal || self.mode != mode || self.expanded != expanded else { return }
        self.horizontal = horizontal
        self.mode = mode
        self.expanded = expanded
        // 内容与模式切换均重建布局，清除旧的 estimated 测量并复用数据源。
        collectionView.setCollectionViewLayout(Self.layout(horizontal: horizontal, mode: mode), animated: false)
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 16 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SizingDemoCell
        let samples = ["短文本", "内容自适应尺寸", "这段文字更长，会根据列宽换行并撑高单元格。", "同一组由最长的内容决定下一组的位置。"]
        let text = "\(indexPath.item + 1) · " + samples[indexPath.item % samples.count] + (expanded ? " 增加内容后重新测量实际尺寸。" : "")
        cell.configure(text: text, horizontal: horizontal, index: indexPath.item)
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "boundary", for: indexPath) as! SizingDemoBoundary
        let isHeader = kind == UICollectionView.elementKindSectionHeader
        // 横向页眉保持简短，为首列留出可见空间；仍由内容测量宽度。
        let text = horizontal ? (isHeader ? "页眉" : "页脚")
            : (isHeader ? "内容自适应页眉 · estimated(44)" : "内容自适应页脚 · 共 16 项")
        view.configure(text: text, horizontal: horizontal)
        return view
    }
}

/// 完整四边约束；固定交叉轴的 fitting 优先级，允许主轴由文字决定。
private final class SizingDemoText: UILabel {
    func install(in parent: UIView) {
        font = .preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true
        translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 12),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -12),
            topAnchor.constraint(equalTo: parent.topAnchor, constant: 12),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -12)
        ])
    }
    static func fit(_ attributes: UICollectionViewLayoutAttributes, in view: UIView,
                    horizontal: Bool) -> UICollectionViewLayoutAttributes {
        let result = attributes.copy() as! UICollectionViewLayoutAttributes
        let target = horizontal ? CGSize(width: 0, height: attributes.size.height) : CGSize(width: attributes.size.width, height: 0)
        let size = view.systemLayoutSizeFitting(target,
            withHorizontalFittingPriority: horizontal ? .fittingSizeLevel : .required,
            verticalFittingPriority: horizontal ? .required : .fittingSizeLevel)
        if horizontal { result.size.width = ceil(size.width) } else { result.size.height = ceil(size.height) }
        return result
    }
}

private final class SizingDemoCell: UICollectionViewCell {
    private let label = SizingDemoText()
    private var horizontal = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.install(in: contentView)
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        isAccessibilityElement = true
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(text: String, horizontal: Bool, index: Int) {
        self.horizontal = horizontal
        label.numberOfLines = horizontal ? 1 : 0
        label.text = text
        contentView.backgroundColor = (index.isMultiple(of: 2) ? UIColor.systemTeal : .systemBlue).withAlphaComponent(0.15)
        accessibilityLabel = text
        accessibilityIdentifier = "sizing.cell.\(index)"
    }
    override func preferredLayoutAttributesFitting(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        SizingDemoText.fit(attributes, in: contentView, horizontal: horizontal)
    }
}

private final class SizingDemoBoundary: UICollectionReusableView {
    private let label = SizingDemoText()
    private var horizontal = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.install(in: self)
        backgroundColor = .secondarySystemBackground
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(text: String, horizontal: Bool) {
        self.horizontal = horizontal
        label.numberOfLines = horizontal ? 1 : 0
        label.text = text
    }
    override func preferredLayoutAttributesFitting(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        SizingDemoText.fit(attributes, in: self, horizontal: horizontal)
    }
}
