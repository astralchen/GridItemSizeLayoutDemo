import SwiftUI
import UIKitGridLayouts

struct ContentView: View {
    @State private var configuration = GridConfiguration()
    @State private var previewWidth = PreviewWidth.available
    @State private var showingAPI = false
    @State private var showingSections = false
    @State private var showingSizing = false

    init() {
        #if DEBUG
        // 让文档截图能够重复进入同一配置；仍由两套真实视图分别执行布局。
        let arguments = ProcessInfo.processInfo.arguments
        func argument(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        var initial = GridConfiguration()
        if let mode = argument(after: "--grid-mode") {
            initial.sizing = mode == "mixed" ? .mixed : GridSizing(rawValue: mode) ?? .fixed
        }
        if argument(after: "--grid-axis") == "horizontal" {
            initial.axis = .horizontal
        }
        _configuration = State(initialValue: initial)
        _showingAPI = State(initialValue: arguments.contains("--grid-api"))
        _showingSections = State(initialValue: arguments.contains("--grid-sections"))
        _showingSizing = State(initialValue: arguments.contains("--grid-sizing"))
        #endif
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let sideBySide = configuration.axis == .horizontal || geometry.size.width >= 760
                VStack(spacing: 10) {
                    controls

                    Text(configuration.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let panels = sideBySide
                        ? AnyLayout(HStackLayout(spacing: 16))
                        : AnyLayout(VStackLayout(spacing: 12))
                    panels {
                        comparisonPanel(title: "SwiftUI") {
                            SwiftUIGridView(configuration: configuration)
                        }
                        comparisonPanel(title: "UIKit") {
                            UIKitGridView(configuration: configuration)
                        }
                    }

                    Text(configuration.axis == .vertical
                         ? "纵向滚动 · 列间距 12 pt · 单元格显示实测列宽"
                         : "横向滚动 · 行间距 12 pt · 单元格显示实测行高")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Grid 布局对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("多分区") { showingSections = true }
                            .accessibilityIdentifier("show.sections")
                        Button("主轴尺寸") { showingSizing = true }
                            .accessibilityIdentifier("show.sizing")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("参数 / 代码") { showingAPI = true }
                        .accessibilityIdentifier("show.api")
                }
            }
            .sheet(isPresented: $showingSections) {
                SectionLayoutsDemo(initialAxis: configuration.axis)
            }
            .sheet(isPresented: $showingSizing) {
                MainAxisSizingDemo()
            }
            .sheet(isPresented: $showingAPI) {
                GridAPIReference(configuration: configuration)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("滚动方向", selection: $configuration.axis) {
                    ForEach(GridAxis.allCases) { axis in Text(axis.rawValue).tag(axis) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 170)
                Text(configuration.axis == .vertical ? "columns · 列宽" : "rows · 行高")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            Picker("尺寸规则", selection: $configuration.sizing) {
                ForEach(GridSizing.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(configuration.axis == .vertical ? "宽度" : "高度")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("容器尺寸", selection: $previewWidth) {
                    ForEach(PreviewWidth.allCases) { width in Text(width.rawValue).tag(width) }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Text("对齐").font(.caption).foregroundStyle(.secondary)
                Picker("网格对齐", selection: $configuration.alignment) {
                    ForEach(GridAlignment.allCases) { alignment in
                        Text(alignmentLabel(alignment)).tag(alignment)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 16) {
                Toggle("标题吸顶", isOn: $configuration.pinHeaders)
                    .accessibilityIdentifier("pin.headers")
                Toggle("上限 112", isOn: $configuration.limitMaximum)
                    .accessibilityIdentifier("limit.maximum")
                    .disabled(configuration.sizing == .fixed)
            }
            .font(.caption)
            .controlSize(.mini)

            HStack {
                Text("\(configuration.axis == .vertical ? "行" : "列")间距 \(Int(configuration.spacing))")
                    .font(.caption.monospacedDigit())
                Slider(value: $configuration.spacing, in: 0...24, step: 4)
                    .accessibilityLabel("主轴间距")
                    .accessibilityIdentifier("line.spacing")
            }
        }
    }

    private func alignmentLabel(_ alignment: GridAlignment) -> String {
        if configuration.axis == .vertical { return alignment.rawValue }
        switch alignment {
        case .leading: return "top"
        case .center: return "center"
        case .trailing: return "bottom"
        }
    }

    private func comparisonPanel<Content: View>(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            GeometryReader { geometry in
                let vertical = configuration.axis == .vertical
                let extent = previewWidth.resolve(available: vertical ? geometry.size.width : geometry.size.height)
                content()
                    .frame(
                        width: vertical ? extent : geometry.size.width,
                        height: vertical ? geometry.size.height : extent
                    )
                    .clipped()
                    .overlay(Rectangle().strokeBorder(Color.secondary.opacity(0.2)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
