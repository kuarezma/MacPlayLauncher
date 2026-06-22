import SwiftUI

// swiftlint:disable file_length

struct CossacksBattlePreviewView: View {
    var body: some View {
        GeometryReader { geometry in
            let miniMapWidth = min(160, max(112, geometry.size.width * 0.34))

            ZStack(alignment: .bottomTrailing) {
                CossacksMapSceneView()

                VStack {
                    CossacksResourceBarView(compact: geometry.size.width < 460)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    Spacer()
                }

                CossacksMiniMapView()
                    .frame(width: miniMapWidth, height: miniMapWidth * 0.76)
                    .padding(10)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.22), lineWidth: 1)
        )
        .accessibilityLabel("Cossacks tarzı oyun içi önizleme")
    }
}

struct CossacksResourceBarView: View {
    let compact: Bool

    private let resources = [
        ResourceBarItem(icon: "tree.fill", value: "5000", color: Color(red: 0.71, green: 0.52, blue: 0.29)),
        ResourceBarItem(icon: "leaf.fill", value: "5000", color: Color(red: 0.86, green: 0.74, blue: 0.36)),
        ResourceBarItem(icon: "mountain.2.fill", value: "5000", color: Color(red: 0.62, green: 0.62, blue: 0.58)),
        ResourceBarItem(
            icon: "circle.hexagongrid.fill",
            value: "5000",
            color: Color(red: 0.95, green: 0.71, blue: 0.20)
        ),
        ResourceBarItem(icon: "flame.fill", value: "5000", color: Color(red: 0.80, green: 0.34, blue: 0.23)),
        ResourceBarItem(icon: "circle.fill", value: "5000", color: Color(red: 0.23, green: 0.22, blue: 0.21))
    ]

    var body: some View {
        HStack(spacing: compact ? 5 : 9) {
            ForEach(resources) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.icon)
                        .font(.system(size: compact ? 9 : 11, weight: .semibold))
                        .foregroundStyle(item.color)
                        .frame(width: compact ? 13 : 16)

                    Text(item.value)
                        .font(.system(size: compact ? 10 : 12, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(red: 0.93, green: 0.86, blue: 0.72))
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, compact ? 5 : 7)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.38), in: Capsule())
            }
        }
        .padding(5)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.27, green: 0.16, blue: 0.10).opacity(0.88),
                    Color(red: 0.12, green: 0.08, blue: 0.05).opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: Capsule()
        )
        .overlay(Capsule().stroke(Color(red: 0.63, green: 0.48, blue: 0.30).opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 5, y: 3)
        .accessibilityLabel("Kaynak çubuğu")
    }
}

struct CossacksMiniMapView: View {
    private let redPoints = [
        MapPoint(id: 1, xRatio: 0.16, yRatio: 0.18, size: 3),
        MapPoint(id: 2, xRatio: 0.21, yRatio: 0.22, size: 2),
        MapPoint(id: 3, xRatio: 0.30, yRatio: 0.76, size: 2),
        MapPoint(id: 4, xRatio: 0.35, yRatio: 0.28, size: 3),
        MapPoint(id: 5, xRatio: 0.72, yRatio: 0.16, size: 2),
        MapPoint(id: 6, xRatio: 0.78, yRatio: 0.22, size: 2)
    ]

    private let greenPoints = [
        MapPoint(id: 11, xRatio: 0.18, yRatio: 0.72, size: 3),
        MapPoint(id: 12, xRatio: 0.22, yRatio: 0.82, size: 2),
        MapPoint(id: 13, xRatio: 0.28, yRatio: 0.86, size: 2),
        MapPoint(id: 14, xRatio: 0.52, yRatio: 0.68, size: 2),
        MapPoint(id: 15, xRatio: 0.61, yRatio: 0.54, size: 2),
        MapPoint(id: 16, xRatio: 0.43, yRatio: 0.80, size: 2)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.11, green: 0.16, blue: 0.08)

                ForEach(0..<18, id: \.self) { index in
                    Circle()
                        .fill(Color.black.opacity(0.22))
                        .frame(width: CGFloat(2 + (index % 4)), height: CGFloat(2 + (index % 4)))
                        .position(
                            x: geometry.size.width * CGFloat((index * 23 % 91) + 4) / 100,
                            y: geometry.size.height * CGFloat((index * 37 % 88) + 6) / 100
                        )
                }

                ForEach(redPoints) { point in
                    minimapDot(point: point, color: .red, in: geometry.size)
                }

                ForEach(greenPoints) { point in
                    minimapDot(point: point, color: .green, in: geometry.size)
                }

                Path { path in
                    let mapWidth = geometry.size.width
                    let mapHeight = geometry.size.height
                    path.move(to: CGPoint(x: mapWidth * 0.16, y: mapHeight * 0.22))
                    path.addLine(to: CGPoint(x: mapWidth * 0.36, y: mapHeight * 0.18))
                    path.addLine(to: CGPoint(x: mapWidth * 0.42, y: mapHeight * 0.48))
                    path.addLine(to: CGPoint(x: mapWidth * 0.22, y: mapHeight * 0.54))
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.54), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(red: 0.15, green: 0.93, blue: 0.72), lineWidth: 2)
        )
        .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 4))
        .padding(4)
        .shadow(color: .black.opacity(0.45), radius: 7, y: 4)
        .accessibilityLabel("Minimap önizlemesi")
    }

    private func minimapDot(point: MapPoint, color: Color, in size: CGSize) -> some View {
        Circle()
            .fill(color.opacity(0.9))
            .frame(width: CGFloat(point.size), height: CGFloat(point.size))
            .position(x: size.width * point.xRatio, y: size.height * point.yRatio)
    }
}

private struct CossacksMapSceneView: View {
    private let forests = [
        MapPoint(id: 1, xRatio: 0.11, yRatio: 0.20, size: 1.0),
        MapPoint(id: 2, xRatio: 0.79, yRatio: 0.26, size: 1.15),
        MapPoint(id: 3, xRatio: 0.25, yRatio: 0.82, size: 0.95),
        MapPoint(id: 4, xRatio: 0.91, yRatio: 0.72, size: 1.05)
    ]

    private let rockPatches = [
        MapPoint(id: 11, xRatio: 0.18, yRatio: 0.34, size: 1.0),
        MapPoint(id: 12, xRatio: 0.55, yRatio: 0.24, size: 0.88),
        MapPoint(id: 13, xRatio: 0.62, yRatio: 0.83, size: 0.74)
    ]

    private let redTroops = CossacksMapSceneView.makeTroops(
        startID: 100,
        rows: 4,
        columns: 11,
        origin: CGPoint(x: 0.18, y: 0.58),
        spacing: CGPoint(x: 0.023, y: 0.035)
    )
    private let greenTroops = CossacksMapSceneView.makeTroops(
        startID: 200,
        rows: 4,
        columns: 8,
        origin: CGPoint(x: 0.67, y: 0.62),
        spacing: CGPoint(x: 0.026, y: 0.037)
    )

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.32, green: 0.43, blue: 0.18),
                        Color(red: 0.42, green: 0.52, blue: 0.24),
                        Color(red: 0.24, green: 0.36, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<20, id: \.self) { index in
                    Ellipse()
                        .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.08 : 0.04))
                        .frame(width: CGFloat(34 + (index * 11 % 38)), height: CGFloat(9 + (index * 7 % 16)))
                        .rotationEffect(.degrees(Double(index * 19 % 60) - 30))
                        .position(
                            x: geometry.size.width * CGFloat((index * 17 % 94) + 3) / 100,
                            y: geometry.size.height * CGFloat((index * 29 % 88) + 6) / 100
                        )
                }

                CossacksFieldView()
                    .frame(width: geometry.size.width * 0.34, height: geometry.size.height * 0.26)
                    .rotationEffect(.degrees(-13))
                    .position(x: geometry.size.width * 0.39, y: geometry.size.height * 0.36)

                ForEach(rockPatches) { patch in
                    CossacksRockPatchView(scale: patch.size)
                        .position(x: geometry.size.width * patch.xRatio, y: geometry.size.height * patch.yRatio)
                }

                ForEach(forests) { forest in
                    CossacksForestClusterView(scale: forest.size)
                        .position(x: geometry.size.width * forest.xRatio, y: geometry.size.height * forest.yRatio)
                }

                CossacksCastleView(accent: .red)
                    .frame(width: geometry.size.width * 0.22, height: geometry.size.height * 0.30)
                    .position(x: geometry.size.width * 0.35, y: geometry.size.height * 0.65)

                CossacksCivicBuildingView()
                    .frame(width: geometry.size.width * 0.19, height: geometry.size.height * 0.26)
                    .position(x: geometry.size.width * 0.56, y: geometry.size.height * 0.46)

                CossacksMillView()
                    .frame(width: geometry.size.width * 0.12, height: geometry.size.height * 0.18)
                    .position(x: geometry.size.width * 0.34, y: geometry.size.height * 0.34)

                CossacksMineView(depleted: false)
                    .frame(width: geometry.size.width * 0.16, height: geometry.size.height * 0.20)
                    .position(x: geometry.size.width * 0.72, y: geometry.size.height * 0.30)

                CossacksMineView(depleted: true)
                    .frame(width: geometry.size.width * 0.13, height: geometry.size.height * 0.15)
                    .position(x: geometry.size.width * 0.78, y: geometry.size.height * 0.72)

                ForEach(redTroops) { troop in
                    CossacksTroopDot(color: .red)
                        .position(x: geometry.size.width * troop.xRatio, y: geometry.size.height * troop.yRatio)
                }

                ForEach(greenTroops) { troop in
                    CossacksTroopDot(color: .green)
                        .position(x: geometry.size.width * troop.xRatio, y: geometry.size.height * troop.yRatio)
                }
            }
        }
    }

    private static func makeTroops(
        startID: Int,
        rows: Int,
        columns: Int,
        origin: CGPoint,
        spacing: CGPoint
    ) -> [MapPoint] {
        var points: [MapPoint] = []
        for row in 0..<rows {
            for column in 0..<columns {
                points.append(
                    MapPoint(
                        id: startID + row * columns + column,
                        xRatio: origin.x + CGFloat(column) * spacing.x + CGFloat(row) * 0.008,
                        yRatio: origin.y + CGFloat(row) * spacing.y,
                        size: 1
                    )
                )
            }
        }
        return points
    }
}

private struct CossacksFieldView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.77, green: 0.62, blue: 0.20))

            ForEach(0..<10, id: \.self) { index in
                Rectangle()
                    .fill(Color(red: 0.97, green: 0.82, blue: 0.30).opacity(0.55))
                    .frame(width: 2)
                    .offset(x: CGFloat(index - 5) * 13)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.20), radius: 5, y: 5)
    }
}

private struct CossacksCastleView: View {
    let accent: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.18))
                .frame(height: 12)
                .blur(radius: 5)
                .offset(y: 8)

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .frame(height: CGFloat(18 + (index % 2) * 10))
                            .overlay(Rectangle().fill(accent).frame(height: 3), alignment: .bottom)
                        Rectangle()
                            .fill(Color(red: 0.68, green: 0.68, blue: 0.62))
                            .frame(
                                width: CGFloat(index == 1 || index == 2 ? 28 : 22),
                                height: CGFloat(48 + (index % 2) * 12)
                            )
                            .overlay(alignment: .top) {
                                HStack(spacing: 3) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color(red: 0.86, green: 0.86, blue: 0.80))
                                            .frame(width: 4, height: 5)
                                    }
                                }
                            }
                    }
                }
            }
            .rotationEffect(.degrees(-4))
        }
    }
}

private struct CossacksCivicBuildingView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(height: 10)
                .blur(radius: 5)
                .offset(y: 8)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 0) {
                        Triangle()
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.16))
                            .frame(width: CGFloat(34 + index * 4), height: CGFloat(24 + index * 4))
                        Rectangle()
                            .fill(Color(red: 0.54, green: 0.54, blue: 0.50))
                            .frame(width: CGFloat(34 + index * 5), height: CGFloat(44 + index * 8))
                            .overlay(Rectangle().fill(Color.red.opacity(0.8)).frame(height: 3), alignment: .top)
                    }
                }
            }
            .rotationEffect(.degrees(3))
        }
    }
}

private struct CossacksMillView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.72, green: 0.70, blue: 0.64))
                .overlay(Circle().stroke(Color(red: 0.42, green: 0.34, blue: 0.25), lineWidth: 2))
                .frame(width: 42, height: 42)
                .offset(y: 16)

            Rectangle()
                .fill(Color(red: 0.73, green: 0.46, blue: 0.25))
                .frame(width: 48, height: 10)
                .rotationEffect(.degrees(-34))
                .offset(x: 8, y: -8)

            Rectangle()
                .fill(Color(red: 0.73, green: 0.46, blue: 0.25))
                .frame(width: 48, height: 10)
                .rotationEffect(.degrees(36))
                .offset(x: 8, y: -8)

            Rectangle()
                .fill(Color(red: 0.55, green: 0.34, blue: 0.20))
                .frame(width: 58, height: 26)
                .overlay(Rectangle().fill(Color.red.opacity(0.75)).frame(height: 3), alignment: .top)
                .offset(x: 25, y: 22)
        }
        .shadow(color: .black.opacity(0.26), radius: 4, y: 5)
    }
}

private struct CossacksMineView: View {
    let depleted: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(depleted ? 0.70 : 0.54))
                .frame(width: depleted ? 54 : 66, height: depleted ? 28 : 36)
                .offset(y: 14)

            ForEach(0..<9, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.48, green: 0.48, blue: 0.44))
                    .frame(width: CGFloat(8 + (index % 3) * 3), height: CGFloat(8 + (index % 3) * 3))
                    .position(
                        x: CGFloat(24 + (index * 17 % 50)),
                        y: CGFloat(18 + (index * 11 % 38))
                    )
            }

            if !depleted {
                Rectangle()
                    .fill(Color(red: 0.58, green: 0.35, blue: 0.20))
                    .frame(width: 48, height: 34)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -6, y: 16)

                Triangle()
                    .fill(Color(red: 0.74, green: 0.51, blue: 0.31))
                    .frame(width: 54, height: 26)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -2, y: -6)
            }

            Circle()
                .fill(depleted ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.95, green: 0.67, blue: 0.16))
                .frame(width: 17, height: 17)
                .overlay(Circle().stroke(Color.black.opacity(0.45), lineWidth: 2))
                .offset(x: 23, y: -28)
        }
        .shadow(color: .black.opacity(0.28), radius: 4, y: 4)
        .accessibilityLabel(depleted ? "Boş maden çukuru" : "Aktif maden")
    }
}

private struct CossacksForestClusterView: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: -5) {
                    Triangle()
                        .fill(
                            index.isMultiple(of: 2)
                                ? Color(red: 0.19, green: 0.37, blue: 0.17)
                                : Color(red: 0.31, green: 0.49, blue: 0.20)
                        )
                        .frame(width: 24 * scale, height: 36 * scale)
                    Rectangle()
                        .fill(Color(red: 0.30, green: 0.20, blue: 0.12))
                        .frame(width: 4 * scale, height: 13 * scale)
                }
                .offset(
                    x: CGFloat(index * 13 % 44) * scale - 18 * scale,
                    y: CGFloat(index * 17 % 34) * scale - 12 * scale
                )
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 4, x: 8, y: 8)
    }
}

private struct CossacksRockPatchView: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.55, green: 0.54, blue: 0.49))
                    .frame(
                        width: CGFloat(12 + (index % 3) * 4) * scale,
                        height: CGFloat(9 + (index % 3) * 4) * scale
                    )
                    .offset(
                        x: CGFloat(index * 11 % 44) * scale - 20 * scale,
                        y: CGFloat(index * 7 % 24) * scale - 10 * scale
                    )
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 3, y: 3)
    }
}

private struct CossacksTroopDot: View {
    let color: Color

    var body: some View {
        VStack(spacing: -1) {
            Circle()
                .fill(Color(red: 0.78, green: 0.76, blue: 0.68))
                .frame(width: 5, height: 5)
            Rectangle()
                .fill(color)
                .frame(width: 5, height: 8)
            Ellipse()
                .stroke(Color(red: 0.85, green: 0.38, blue: 0.14), lineWidth: 1)
                .frame(width: 12, height: 5)
        }
        .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
    }
}

private struct ResourceBarItem: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let color: Color
}

private struct MapPoint: Identifiable {
    let id: Int
    let xRatio: CGFloat
    let yRatio: CGFloat
    let size: CGFloat
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CossacksOptimizationStatusView: View {
    let items: [CossacksOptimizationStatusItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Oyun içi hazırlık")
                .font(.headline)

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: iconName(for: item.state))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(color(for: item.state))
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.callout.weight(.semibold))
                        Text(item.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func iconName(for state: CossacksOptimizationStatusItem.State) -> String {
        switch state {
        case .ready:
            return "checkmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        case .unavailable:
            return "minus.circle.fill"
        }
    }

    private func color(for state: CossacksOptimizationStatusItem.State) -> Color {
        switch state {
        case .ready:
            return .green
        case .needsAttention:
            return .orange
        case .unavailable:
            return .secondary
        }
    }
}
