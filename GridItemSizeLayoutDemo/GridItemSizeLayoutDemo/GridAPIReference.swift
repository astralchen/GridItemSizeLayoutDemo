import SwiftUI

struct GridAPIReference: View {
    let configuration: GridConfiguration
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("LazyVGrid / LazyHGrid 参数") {
                    mapping("columns / rows", "UIKitGridItem 与 GridItem 一样使用 fixed、flexible、adaptive。VGrid 的 columns 决定列宽，HGrid 的 rows 决定行高。")
                    mapping("alignment", "VGrid：leading / center / trailing。HGrid：top / center / bottom。控制整组轨道在容器中的对齐，不改变 cell 内文本对齐。")
                    mapping("spacing", "滚动方向相邻行或列的间距 → section.interGroupSpacing。UIKitGridItem.spacing 是交叉方向的轨道间距。")
                    mapping("pinnedViews", "sectionHeaders / sectionFooters → supplementary item 的 pinToVisibleBounds。本页演示分组标题的吸附开关。")
                    mapping("content", "SwiftUI 的 ForEach + Section，对应 UIKit 数据源的 section、item、cell 与 supplementary view。布局包不接管数据源。")
                }
                Section("当前 SwiftUI 写法") { code(configuration.swiftUICode) }
                Section("对应 UIKit API · 本地 SPM") { code("import UIKitGridLayouts\n\n" + configuration.uiKitCode) }
                Section("观察方法与范围") {
                    Text("切换 260 / 340 / 自适应尺寸：fixed 保持尺寸；flexible 保持轨道数；adaptive 改变轨道数。两个框架使用相同输入，分别独立计算布局。")
                    Text("VGrid 比较列宽，HGrid 比较行高。两边独立滚动；规则改变时回到起点。开启上限后观察空白与对齐。")
                    Text("混合模式依次放置 fixed(70)、flexible(80…140)、adaptive(minimum: 60)，轨道间距 12。上限开关把两种非固定规则的 maximum 都设为 112；adaptive 展开后可能超过 3 条轨道。")
                    Text("UIKit 使用确定的一轮分配；没有复刻 SwiftUI 的全部提议尺寸与多轮测量。极窄容器和触及上限后的留白可能出现差异，两边显示各自实际结果。")
                    Text("UIKit 的 spacing: nil 明确定义为 8 pt。SwiftUI 的 nil 由系统决定，不承诺相等。本例显式传相同间距。")
                    Text("UIKit 两个方向统一使用 itemSize：fixed、estimated、uniform（iOS 17+ 同组统一）、aspectRatio（宽 ÷ 高）。本对比页使用 .fixed(56)，主轴尺寸页面可切换尺寸策略。headerSize / footerSize 默认 nil；启用后由数据源提供辅助视图。")
                }
            }
            .navigationTitle("参数对应关系")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func mapping(_ name: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name).font(.system(.subheadline, design: .monospaced).bold())
            Text(description).font(.footnote).foregroundStyle(.secondary)
        }.padding(.vertical, 3)
    }

    private func code(_ source: String) -> some View {
        Text(source).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
    }
}
