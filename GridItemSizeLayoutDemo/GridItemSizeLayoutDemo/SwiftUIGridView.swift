import SwiftUI

struct SwiftUIGridView: View {
    let configuration: GridConfiguration

    var body: some View {
        ScrollView(configuration.axis == .vertical ? .vertical : .horizontal) {
            // 原生 SwiftUI 自行布局，不读取 UIKit 包的计算结果。
            if configuration.axis == .vertical {
                LazyVGrid(
                    columns: configuration.columns,
                    alignment: configuration.alignment.swiftUI,
                    spacing: configuration.rowSpacing,
                    pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : []
                ) { sections }
                .padding(.bottom, configuration.rowSpacing)
            } else {
                LazyHGrid(
                    rows: configuration.columns,
                    alignment: configuration.swiftUIVerticalAlignment,
                    spacing: configuration.rowSpacing,
                    pinnedViews: configuration.pinHeaders ? [.sectionHeaders] : []
                ) { sections }
                .padding(.trailing, configuration.rowSpacing)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .accessibilityIdentifier("swiftui.grid")
        .id(configuration)
    }

    private var sections: some View {
        ForEach(0..<GridConfiguration.sectionCount, id: \.self) { section in
            Section {
                ForEach(0..<GridConfiguration.itemsPerSection, id: \.self) { item in
                    SwiftUIGridCell(
                        index: section * GridConfiguration.itemsPerSection + item,
                        axis: configuration.axis
                    )
                }
            } header: {
                header(section: section)
            }
        }
    }

    private func header(section: Int) -> some View {
        Text(configuration.axis == .vertical ? "SECTION \(section + 1) · 18 ITEMS" : "S\(section + 1)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 8)
            .frame(
                width: configuration.axis == .horizontal ? GridConfiguration.headerHeight : nil,
                height: configuration.axis == .vertical ? GridConfiguration.headerHeight : nil
            )
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .accessibilityIdentifier("swiftui.header.\(section)")
    }
}

private struct SwiftUIGridCell: View {
    let index: Int
    let axis: GridAxis

    var body: some View {
        GeometryReader { geometry in
            let extent = axis == .vertical ? geometry.size.width : geometry.size.height
            VStack(spacing: 2) {
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 16, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color(uiColor: GridPalette.uiColor(for: index)))
                Text(String(format: "%.1f", extent))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color(uiColor: GridPalette.uiColor(for: index)).opacity(0.14),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("项目 \(index + 1)")
            .accessibilityValue(String(format: "%.1f", extent))
            .accessibilityIdentifier("swiftui.cell.\(index)")
        }
        .frame(
            width: axis == .horizontal ? GridConfiguration.rowHeight : nil,
            height: axis == .vertical ? GridConfiguration.rowHeight : nil
        )
    }
}
