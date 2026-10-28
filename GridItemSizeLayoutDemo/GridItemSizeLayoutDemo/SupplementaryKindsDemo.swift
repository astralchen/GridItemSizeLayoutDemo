import SwiftUI
import UIKitGridLayouts

/// 用实际收到的 kind 标记辅助视图，验证布局、注册和数据源的契约。
struct SupplementaryKindsDemo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var axis: GridAxis
    @State private var factory = false

    init(initialAxis: GridAxis) { _axis = State(initialValue: initialAxis) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Picker("方向", selection: $axis) {
                    Text("纵向").tag(GridAxis.vertical)
                    Text("横向").tag(GridAxis.horizontal)
                }.pickerStyle(.segmented)
                Toggle("使用 makeSection", isOn: $factory)
                    .accessibilityIdentifier("kinds.factory")
                Text("header / footer · 显式配置")
                    .font(.headline)
                Text("自定义名称同时用于布局、注册和数据源。下方色块显示数据源实际收到的 kind。")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("""
                \(axis == .vertical ? "UIKitLazyVGridLayout" : "UIKitLazyHGridLayout")\(factory ? ".makeSection" : "")(
                  \(axis == .vertical ? "columns" : "rows"): [UIKitGridItem(.fixed(64))],
                  itemSize: .fixed(48),
                  header: .init(elementKind: "demo.header",
                                size: .fixed(72)),
                  footer: .init(elementKind: "demo.footer",
                                size: .fixed(72))\(factory ? ",\n  environment: environment" : "")
                )
                """)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                KindsCollection(horizontal: axis == .horizontal, factory: factory)
                Text("header / footer 默认 nil。kind 必须显式指定。库 API：iOS 15+。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("自定义辅助视图 Kind")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("完成") { dismiss() } }
        }
    }
}

private struct KindsCollection: UIViewControllerRepresentable {
    let horizontal: Bool
    let factory: Bool
    func makeUIViewController(context: Context) -> KindsDemoController {
        KindsDemoController(horizontal: horizontal, factory: factory)
    }
    func updateUIViewController(_ controller: KindsDemoController, context: Context) {
        controller.update(horizontal: horizontal, factory: factory)
    }
}

final class KindsDemoController: UICollectionViewController {
    static let headerKind = "demo.header"
    static let footerKind = "demo.footer"
    private var horizontal: Bool
    private var factory: Bool

    init(horizontal: Bool, factory: Bool) {
        self.horizontal = horizontal
        self.factory = factory
        super.init(collectionViewLayout: Self.layout(horizontal: horizontal, factory: factory))
    }
    required init?(coder: NSCoder) { fatalError() }

    private static func layout(horizontal: Bool, factory: Bool) -> UICollectionViewLayout {
        let tracks = [UIKitGridItem(.fixed(64))]
        if factory {
            let config = UICollectionViewCompositionalLayoutConfiguration()
            config.scrollDirection = horizontal ? .horizontal : .vertical
            return UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
                if horizontal {
                    return UIKitLazyHGridLayout.makeSection(
                        rows: tracks, itemSize: .fixed(48), header: .init(elementKind: headerKind, size: .fixed(72)),
                        footer: .init(elementKind: footerKind, size: .fixed(72)), environment: environment)
                }
                return UIKitLazyVGridLayout.makeSection(
                    columns: tracks, itemSize: .fixed(48), header: .init(elementKind: headerKind, size: .fixed(72)),
                    footer: .init(elementKind: footerKind, size: .fixed(72)), environment: environment)
            }, configuration: config)
        }
        if horizontal {
            return UIKitLazyHGridLayout(rows: tracks, itemSize: .fixed(48),
                header: .init(elementKind: headerKind, size: .fixed(72)),
                footer: .init(elementKind: footerKind, size: .fixed(72)))
        }
        return UIKitLazyVGridLayout(columns: tracks, itemSize: .fixed(48),
            header: .init(elementKind: headerKind, size: .fixed(72)),
                footer: .init(elementKind: footerKind, size: .fixed(72)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.accessibilityIdentifier = "kinds.collection"
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        for kind in [Self.headerKind, Self.footerKind] {
            collectionView.register(KindLabelView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: "boundary")
        }
    }

    func update(horizontal: Bool, factory: Bool) {
        guard self.horizontal != horizontal || self.factory != factory else { return }
        self.horizontal = horizontal
        self.factory = factory
        collectionView.setCollectionViewLayout(Self.layout(horizontal: horizontal, factory: factory), animated: false)
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 3 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        var content = UIListContentConfiguration.cell()
        content.text = "\(indexPath.item + 1)"
        cell.contentConfiguration = content
        cell.backgroundColor = .tertiarySystemBackground
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "boundary", for: indexPath) as! KindLabelView
        view.label.text = kind
        view.accessibilityIdentifier = kind
        view.accessibilityLabel = kind
        view.backgroundColor = (kind == Self.headerKind ? UIColor.systemTeal : .systemOrange).withAlphaComponent(0.25)
        return view
    }
}

private final class KindLabelView: UICollectionReusableView {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        label.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
