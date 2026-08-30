//
//  DetailsView.swift
//  Space
//
//  Created by Serhiy Mytrovtsiy on 06/07/2025
//  Using Swift 6.0
//  Running on macOS 15.5
//
//  Copyright © 2025 Serhiy Mytrovtsiy. All rights reserved.
//

import SwiftUI
import AppKit

// MARK: - Models

enum ChartDisplayType: String, CaseIterable, Identifiable {
    case bubbles = "Bubbles"
    case bars = "Bars"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .bubbles: return "circle.grid.hex.fill"
        case .bars: return "chart.bar.xaxis"
        }
    }
}

struct ChartItem: Identifiable, Equatable {
    let id = UUID()
    let entity: Entity?
    let name: String
    let path: String
    let size: Int64
    let itemsCount: Int
    let isDirectory: Bool
    let isOther: Bool
    let colorIndex: Int
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: self.size, countStyle: .file)
    }
    
    static func == (lhs: ChartItem, rhs: ChartItem) -> Bool {
        lhs.id == rhs.id || (lhs.isOther && rhs.isOther) || (!lhs.path.isEmpty && lhs.path == rhs.path)
    }
}

// MARK: - Intelligent Icon Resolver (Library = Books, .gemini = Gemini Star, iCloud = Cloud, Dev Tools & Apple Systems)

struct ItemIconResolver {
    struct IconInfo {
        let systemName: String
        let color: Color
    }
    
    static func icon(for item: ChartItem) -> IconInfo {
        if item.isOther {
            return IconInfo(systemName: "ellipsis.circle.fill", color: .secondary)
        }
        return icon(name: item.name, path: item.path, isDirectory: item.isDirectory)
    }
    
    static func icon(name: String, path: String, isDirectory: Bool, isOther: Bool = false) -> IconInfo {
        if isOther {
            return IconInfo(systemName: "ellipsis.circle.fill", color: .secondary)
        }
        
        let lowerName = name.lowercased()
        let ext = (name as NSString).pathExtension.lowercased()
        
        // 1. App bundles
        if ext == "app" || path.hasSuffix(".app") {
            return IconInfo(systemName: "app.fill", color: .indigo)
        }
        
        // 2. Specific Folders & Developer Directories
        if isDirectory {
            // AI & Google Gemini
            if lowerName == ".gemini" || lowerName == "gemini" || lowerName.contains("gemini") {
                return IconInfo(systemName: "sparkles", color: Color(red: 0.65, green: 0.28, blue: 0.98))
            }
            if lowerName.contains("claude") || lowerName.contains("openai") || lowerName.contains("chatgpt") || lowerName.contains("ollama") {
                return IconInfo(systemName: "atom", color: .orange)
            }
            
            // Library & Frameworks (Books icon as requested!)
            if lowerName == "library" || lowerName == "libraries" || lowerName == "lib" {
                return IconInfo(systemName: "books.vertical.fill", color: Color(red: 0.95, green: 0.55, blue: 0.15))
            }
            if lowerName == "frameworks" || lowerName == "plugins" {
                return IconInfo(systemName: "puzzlepiece.extension.fill", color: .teal)
            }
            
            // iCloud & Cloud Storage (iCloud cloud shape as requested!)
            if lowerName.contains("icloud") || lowerName == "mobile documents" || lowerName.contains("cloud") {
                return IconInfo(systemName: "icloud.fill", color: Color(red: 0.15, green: 0.65, blue: 1.0))
            }
            if lowerName.contains("dropbox") || lowerName.contains("onedrive") || lowerName.contains("google drive") {
                return IconInfo(systemName: "cloud.fill", color: .blue)
            }
            
            // Git & Version Control
            if lowerName == ".git" || lowerName == "git" || lowerName.contains(".github") || lowerName.contains(".gitlab") {
                return IconInfo(systemName: "arrow.triangle.branch", color: Color(red: 0.95, green: 0.35, blue: 0.2))
            }
            
            // Package Managers & Dependencies
            if lowerName == "node_modules" || lowerName == ".npm" || lowerName == ".yarn" || lowerName == ".pnpm" || lowerName == "vendor" {
                return IconInfo(systemName: "shippingbox.fill", color: Color(red: 0.85, green: 0.25, blue: 0.25))
            }
            if lowerName == "pods" || lowerName == ".cocoapods" || lowerName == "spm" || lowerName == ".swiftpm" {
                return IconInfo(systemName: "shippingbox.circle.fill", color: .orange)
            }
            
            // Developer IDEs & Tools
            if lowerName.contains("xcode") || lowerName == "deriveddata" || lowerName.hasSuffix(".xcodeproj") || lowerName.hasSuffix(".xcworkspace") {
                return IconInfo(systemName: "hammer.fill", color: Color(red: 0.15, green: 0.55, blue: 0.98))
            }
            if lowerName == ".vscode" || lowerName == ".cursor" || lowerName == ".idea" {
                return IconInfo(systemName: "curlybraces.square.fill", color: Color(red: 0.2, green: 0.6, blue: 0.95))
            }
            if lowerName == ".docker" || lowerName == "docker" || lowerName == "containers" {
                return IconInfo(systemName: "shippingbox.fill", color: .cyan)
            }
            if lowerName == ".cargo" || lowerName == ".rustup" || lowerName == "rust" {
                return IconInfo(systemName: "gearshape.2.fill", color: Color(red: 0.9, green: 0.45, blue: 0.15))
            }
            if lowerName == ".ssh" {
                return IconInfo(systemName: "key.fill", color: Color(red: 0.95, green: 0.75, blue: 0.1))
            }
            if lowerName == ".aws" || lowerName == ".gcp" || lowerName == ".azure" {
                return IconInfo(systemName: "server.rack", color: .orange)
            }
            if lowerName == ".venv" || lowerName == "venv" || lowerName == "env" || lowerName == ".conda" || lowerName == "anaconda3" || lowerName == "miniconda3" {
                return IconInfo(systemName: "terminal.fill", color: Color(red: 0.2, green: 0.75, blue: 0.4))
            }
            if lowerName == ".config" || lowerName == "config" || lowerName == "settings" {
                return IconInfo(systemName: "slider.horizontal.3", color: .gray)
            }
            if lowerName == "build" || lowerName == "dist" || lowerName == "target" || lowerName == "bin" || lowerName == "out" {
                return IconInfo(systemName: "wrench.and.screwdriver.fill", color: .gray)
            }
            
            // macOS Standard User Folders
            if lowerName == "applications" || lowerName == "apps" {
                return IconInfo(systemName: "square.grid.2x2.fill", color: Color(red: 0.15, green: 0.55, blue: 0.98))
            }
            if lowerName == "documents" || lowerName == "docs" {
                return IconInfo(systemName: "doc.text.fill", color: Color(red: 0.2, green: 0.6, blue: 0.95))
            }
            if lowerName == "downloads" {
                return IconInfo(systemName: "arrow.down.circle.fill", color: Color(red: 0.2, green: 0.78, blue: 0.45))
            }
            if lowerName == "desktop" {
                return IconInfo(systemName: "display", color: Color(red: 0.18, green: 0.76, blue: 0.94))
            }
            if lowerName == "pictures" || lowerName == "photos" || lowerName == "images" || lowerName == "img" {
                return IconInfo(systemName: "photo.on.rectangle.angled", color: Color(red: 0.95, green: 0.26, blue: 0.64))
            }
            if lowerName == "music" || lowerName == "audio" || lowerName == "songs" {
                return IconInfo(systemName: "music.note.list", color: Color(red: 0.95, green: 0.25, blue: 0.35))
            }
            if lowerName == "movies" || lowerName == "videos" || lowerName == "video" {
                return IconInfo(systemName: "film.fill", color: Color(red: 0.65, green: 0.28, blue: 0.98))
            }
            if lowerName == "developer" || lowerName == "projects" || lowerName == "development" || lowerName == "code" || lowerName == "src" || lowerName == "source" {
                return IconInfo(systemName: "hammer.circle.fill", color: Color(red: 0.15, green: 0.55, blue: 0.98))
            }
            if lowerName == "caches" {
                return IconInfo(systemName: "sparkles", color: Color(red: 0.65, green: 0.28, blue: 0.98))
            }
            if lowerName == "logs" {
                return IconInfo(systemName: "doc.text.magnifyingglass", color: Color(red: 1.0, green: 0.72, blue: 0.18))
            }
            if lowerName == "public" || lowerName == "shared" {
                return IconInfo(systemName: "person.2.fill", color: .teal)
            }
            if lowerName == ".trash" || lowerName == "trash" {
                return IconInfo(systemName: "trash.fill", color: .red)
            }
            
            // Default folder
            return IconInfo(systemName: "folder.fill", color: Color(red: 0.2, green: 0.58, blue: 0.98))
        }
        
        // 3. Specific File Types
        switch ext {
        case "swift":
            return IconInfo(systemName: "swift", color: Color(red: 0.95, green: 0.42, blue: 0.18))
        case "py", "pyw", "ipynb":
            return IconInfo(systemName: "chevron.left.forwardslash.chevron.right", color: Color(red: 0.95, green: 0.75, blue: 0.2))
        case "js", "ts", "jsx", "tsx", "vue", "svelte", "php", "rb", "go", "rs", "java", "c", "cpp", "h", "hpp", "m", "mm", "kt", "scala", "dart":
            return IconInfo(systemName: "curlybraces", color: Color(red: 0.95, green: 0.75, blue: 0.15))
        case "html", "htm", "css", "scss", "sass", "less":
            return IconInfo(systemName: "chevron.left.forwardslash.chevron.right", color: Color(red: 0.95, green: 0.45, blue: 0.2))
        case "json", "yaml", "yml", "xml", "toml", "plist", "env", "conf", "config", "ini":
            return IconInfo(systemName: "list.bullet.rectangle.fill", color: .teal)
        case "sh", "bash", "zsh", "fish", "command":
            return IconInfo(systemName: "terminal.fill", color: Color(red: 0.2, green: 0.78, blue: 0.45))
        case "md", "markdown", "txt", "rtf", "log":
            return IconInfo(systemName: "doc.text.fill", color: .gray)
        case "pdf":
            return IconInfo(systemName: "doc.richtext.fill", color: Color(red: 0.9, green: 0.2, blue: 0.2))
        case "zip", "tar", "gz", "tgz", "bz2", "xz", "7z", "rar", "dmg", "pkg", "iso":
            return IconInfo(systemName: "archivebox.fill", color: Color(red: 0.65, green: 0.28, blue: 0.98))
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "heic", "ico", "bmp", "tiff", "psd", "ai":
            return IconInfo(systemName: "photo.fill", color: Color(red: 0.95, green: 0.26, blue: 0.64))
        case "mp4", "mov", "mkv", "avi", "webm", "m4v", "wmv", "flv":
            return IconInfo(systemName: "film.fill", color: Color(red: 0.65, green: 0.28, blue: 0.98))
        case "mp3", "wav", "aac", "flac", "m4a", "ogg", "aiff":
            return IconInfo(systemName: "music.note", color: Color(red: 0.95, green: 0.25, blue: 0.35))
        case "xls", "xlsx", "csv", "numbers":
            return IconInfo(systemName: "tablecells.fill", color: Color(red: 0.2, green: 0.75, blue: 0.4))
        case "doc", "docx", "pages":
            return IconInfo(systemName: "doc.fill", color: Color(red: 0.15, green: 0.55, blue: 0.98))
        case "ppt", "pptx", "keynote":
            return IconInfo(systemName: "chart.bar.doc.horizontal.fill", color: Color(red: 0.95, green: 0.45, blue: 0.15))
        case "sql", "sqlite", "db", "sqlite3":
            return IconInfo(systemName: "cylinder.split.1x2.fill", color: .cyan)
        case "lock", "key", "cert", "pem", "crt", "p12":
            return IconInfo(systemName: "lock.shield.fill", color: Color(red: 0.95, green: 0.75, blue: 0.15))
        case "font", "ttf", "otf", "woff", "woff2":
            return IconInfo(systemName: "textformat", color: .indigo)
        default:
            return IconInfo(systemName: "doc.fill", color: .gray)
        }
    }
}

// MARK: - CleanMyMac Style Palette

struct CleanMyMacPalette {
    static let itemGradients: [[Color]] = [
        // 1. Radiant Purple
        [Color(red: 0.65, green: 0.28, blue: 0.98), Color(red: 0.44, green: 0.12, blue: 0.82)],
        // 2. Deep Sky Blue
        [Color(red: 0.14, green: 0.58, blue: 0.98), Color(red: 0.08, green: 0.36, blue: 0.88)],
        // 3. Turquoise Teal
        [Color(red: 0.12, green: 0.80, blue: 0.74), Color(red: 0.04, green: 0.58, blue: 0.58)],
        // 4. Emerald Green
        [Color(red: 0.20, green: 0.82, blue: 0.48), Color(red: 0.10, green: 0.62, blue: 0.32)],
        // 5. Sunset Coral
        [Color(red: 1.00, green: 0.42, blue: 0.30), Color(red: 0.88, green: 0.24, blue: 0.20)],
        // 6. Vibrant Magenta
        [Color(red: 0.96, green: 0.26, blue: 0.64), Color(red: 0.78, green: 0.12, blue: 0.50)],
        // 7. Warm Amber
        [Color(red: 1.00, green: 0.72, blue: 0.18), Color(red: 0.92, green: 0.54, blue: 0.06)],
        // 8. Royal Indigo
        [Color(red: 0.42, green: 0.38, blue: 0.96), Color(red: 0.28, green: 0.22, blue: 0.84)],
        // 9. Electric Cyan
        [Color(red: 0.18, green: 0.76, blue: 0.94), Color(red: 0.10, green: 0.52, blue: 0.82)],
        // 10. Other items (Slate Gray / Silver)
        [Color(red: 0.58, green: 0.62, blue: 0.70), Color(red: 0.42, green: 0.46, blue: 0.54)]
    ]
    
    static func gradient(for index: Int, isOther: Bool = false) -> [Color] {
        if isOther {
            return itemGradients.last!
        }
        return itemGradients[index % (itemGradients.count - 1)]
    }
}

// MARK: - Details View

struct DetailsView: View {
    @EnvironmentObject private var analyzer: Analyzer
    @State private var selectedItem: ChartItem? = nil
    @State private var chartItems: [ChartItem] = []
    @State private var displayType: ChartDisplayType = .bubbles
    @State private var navigationStack: [Entity] = []
    
    private var currentEntity: Entity? {
        if let currentPath = navigationStack.last?.path,
           let root = analyzer.analyzedEntities.first,
           let found = root.find(byPath: currentPath) {
            return found
        }
        return navigationStack.last ?? analyzer.analyzedEntities.first
    }
    
    private var totalSize: Int64 {
        if let current = currentEntity, current.size > 0 {
            return current.size
        }
        return chartItems.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Header: Title & View Mode Selector
            HStack {
                Text("Space Overview")
                    .font(.headline)
                Spacer()
                Picker("", selection: $displayType) {
                    ForEach(ChartDisplayType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(.horizontal, 4)
            
            // Breadcrumb / Navigation Bar
            if !navigationStack.isEmpty {
                HStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            _ = self.navigationStack.popLast()
                            self.selectedItem = nil
                            self.updateChartItems()
                        }
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Go up to parent folder")
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.navigationStack.removeAll()
                            self.selectedItem = nil
                            self.updateChartItems()
                        }
                    }) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Return to root folder")
                    
                    if let cur = currentEntity {
                        let iconInfo = ItemIconResolver.icon(name: cur.name, path: cur.path, isDirectory: true)
                        Image(systemName: iconInfo.systemName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(iconInfo.color)
                        
                        Text(cur.name)
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            
            // Visualization Area
            if chartItems.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "circle.grid.hex")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(navigationStack.isEmpty ? "No files to display" : "Folder is empty")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 270)
            } else {
                Group {
                    switch displayType {
                    case .bubbles:
                        BubbleChartView(
                            items: self.chartItems,
                            totalSize: self.totalSize,
                            selectedItem: self.$selectedItem,
                            onEnterFolder: { item in
                                self.enterFolder(item)
                            }
                        )
                        .frame(height: 270)
                    case .bars:
                        BarChartView(
                            items: self.chartItems,
                            totalSize: self.totalSize,
                            selectedItem: self.$selectedItem,
                            onEnterFolder: { item in
                                self.enterFolder(item)
                            }
                        )
                        .frame(height: 270)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                )
            }
            
            Divider()
            
            // Details Card: Selected Item or Current Folder
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    if let selected = self.selectedItem {
                        SelectedItemCard(
                            item: selected,
                            totalSize: self.totalSize,
                            onDeselect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.selectedItem = nil
                                }
                            },
                            onEnterFolder: {
                                self.enterFolder(selected)
                            }
                        )
                    } else {
                        FolderStatsCard(
                            entity: self.currentEntity,
                            stats: self.navigationStack.isEmpty ? self.analyzer.stats : nil,
                            topCount: self.chartItems.count
                        )
                    }
                }
            }
        }
        .padding(12)
        .onChange(of: self.analyzer.analyzedEntities) { _, _ in
            self.updateChartItems()
        }
        .onChange(of: self.analyzer.status) { _, newStatus in
            if newStatus == .running {
                self.selectedItem = nil
                self.chartItems = []
                self.navigationStack = []
            }
        }
        .onAppear {
            self.updateChartItems()
        }
    }
    
    private func enterFolder(_ item: ChartItem) {
        guard !item.isOther, item.isDirectory, let entity = item.entity else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            self.navigationStack.append(entity)
            self.selectedItem = nil
            self.updateChartItems()
        }
    }
    
    private func updateChartItems() {
        guard let current = currentEntity else {
            self.chartItems = []
            self.selectedItem = nil
            return
        }
        
        let allChildren = current.children.sorted { $0.size > $1.size }
        guard !allChildren.isEmpty else {
            self.chartItems = []
            self.selectedItem = nil
            return
        }
        
        var items: [ChartItem] = []
        let limit = 9
        
        if allChildren.count <= limit {
            for (index, child) in allChildren.enumerated() {
                items.append(ChartItem(
                    entity: child,
                    name: child.name,
                    path: child.path,
                    size: child.size,
                    itemsCount: child.items,
                    isDirectory: child.isDirectory,
                    isOther: false,
                    colorIndex: index
                ))
            }
        } else {
            let top9 = allChildren.prefix(limit)
            for (index, child) in top9.enumerated() {
                items.append(ChartItem(
                    entity: child,
                    name: child.name,
                    path: child.path,
                    size: child.size,
                    itemsCount: child.items,
                    isDirectory: child.isDirectory,
                    isOther: false,
                    colorIndex: index
                ))
            }
            
            let others = allChildren.dropFirst(limit)
            let othersSize = others.reduce(Int64(0)) { $0 + $1.size }
            let othersCount = others.reduce(0) { $0 + $1.items }
            
            if othersSize > 0 || !others.isEmpty {
                items.append(ChartItem(
                    entity: nil,
                    name: "Other items (\(others.count))",
                    path: "",
                    size: othersSize,
                    itemsCount: othersCount,
                    isDirectory: true,
                    isOther: true,
                    colorIndex: 9
                ))
            }
        }
        
        self.chartItems = items
        
        if let selected = self.selectedItem {
            if !items.contains(where: { $0.path == selected.path && !$0.path.isEmpty }) &&
               !(selected.isOther && items.contains(where: { $0.isOther })) {
                self.selectedItem = nil
            }
        }
    }
}

// MARK: - Bubble Chart View (With Rich Assets & Double-Click Navigation)

struct BubbleNode: Identifiable {
    let id: UUID
    let item: ChartItem
    var center: CGPoint
    var radius: CGFloat
    var gradient: [Color]
}

struct BubbleChartView: View {
    let items: [ChartItem]
    let totalSize: Int64
    @Binding var selectedItem: ChartItem?
    var onEnterFolder: ((ChartItem) -> Void)? = nil
    
    @State private var hoveredId: UUID? = nil
    
    var body: some View {
        GeometryReader { geo in
            let nodes = computeBubbleLayout(for: items, in: geo.size)
            
            ZStack {
                // Background tap to deselect
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedItem = nil
                        }
                    }
                
                ForEach(nodes) { node in
                    let isSelected = selectedItem?.id == node.item.id ||
                        (selectedItem?.isOther == true && node.item.isOther)
                    let isHovered = hoveredId == node.item.id
                    let percent = totalSize > 0 ? (Double(node.item.size) / Double(totalSize) * 100) : 0
                    
                    BubbleItemView(
                        node: node,
                        isSelected: isSelected,
                        isHovered: isHovered,
                        percentage: percent
                    )
                    .position(node.center)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredId = hovering ? node.item.id : nil
                        }
                    }
                    .onTapGesture(count: 2) {
                        if !node.item.isOther && node.item.isDirectory {
                            onEnterFolder?(node.item)
                        }
                    }
                    .onTapGesture(count: 1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if isSelected {
                                selectedItem = nil
                            } else {
                                selectedItem = node.item
                            }
                        }
                    }
                    .help("\(node.item.name)\n\(node.item.formattedSize) (\(String(format: "%.1f", percent))%)\(node.item.isDirectory && !node.item.isOther ? "\n(Double-click to open folder)" : "")")
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func computeBubbleLayout(for items: [ChartItem], in size: CGSize) -> [BubbleNode] {
        guard !items.isEmpty, size.width > 0, size.height > 0 else { return [] }
        
        let count = items.count
        let maxSize = max(1, items.map { $0.size }.max() ?? 1)
        
        var radii: [CGFloat] = []
        for item in items {
            let ratio = sqrt(max(Double(item.size), 1.0) / Double(maxSize))
            let weight = 0.35 + 0.65 * ratio
            let baseR = min(size.width, size.height) * 0.18 * CGFloat(weight)
            radii.append(max(baseR, 17))
        }
        
        var positions: [CGPoint] = []
        for i in 0..<count {
            if i == 0 {
                positions.append(CGPoint(x: 0, y: 0))
            } else {
                let angle = Double(i) * 2.399963
                let dist = Double(radii[0] + radii[i] + 16.0) * (0.85 + Double(i) * 0.1)
                positions.append(CGPoint(x: cos(angle) * dist, y: sin(angle) * dist))
            }
        }
        
        let iterations = 80
        let spacingGap: CGFloat = 14.0
        
        for _ in 0..<iterations {
            for i in 0..<count {
                for j in (i + 1)..<count {
                    var dx = positions[j].x - positions[i].x
                    var dy = positions[j].y - positions[i].y
                    var dist = sqrt(dx * dx + dy * dy)
                    let targetDist = radii[i] + radii[j] + spacingGap
                    
                    if dist < 0.001 {
                        dx = CGFloat.random(in: -1...1)
                        dy = CGFloat.random(in: -1...1)
                        dist = 0.001
                    }
                    
                    if dist < targetDist {
                        let overlap = (targetDist - dist) * 0.5
                        let nx = dx / dist
                        let ny = dy / dist
                        positions[i].x -= nx * overlap
                        positions[i].y -= ny * overlap
                        positions[j].x += nx * overlap
                        positions[j].y += ny * overlap
                    }
                }
            }
            
            for i in 0..<count {
                positions[i].x *= 0.93
                positions[i].y *= 0.93
            }
        }
        
        var minX = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var minY = CGFloat.infinity
        var maxY = -CGFloat.infinity
        
        for i in 0..<count {
            minX = min(minX, positions[i].x - radii[i])
            maxX = max(maxX, positions[i].x + radii[i])
            minY = min(minY, positions[i].y - radii[i])
            maxY = max(maxY, positions[i].y + radii[i])
        }
        
        let bboxW = max(maxX - minX, 10)
        let bboxH = max(maxY - minY, 10)
        let padding: CGFloat = 16
        let scale = min((size.width - padding * 2) / bboxW, (size.height - padding * 2) / bboxH, 1.1)
        let clusterCenterX = (minX + maxX) / 2
        let clusterCenterY = (minY + maxY) / 2
        
        var result: [BubbleNode] = []
        for i in 0..<count {
            let posX = size.width / 2 + (positions[i].x - clusterCenterX) * scale
            let posY = size.height / 2 + (positions[i].y - clusterCenterY) * scale
            let finalR = radii[i] * scale
            
            result.append(BubbleNode(
                id: items[i].id,
                item: items[i],
                center: CGPoint(x: posX, y: posY),
                radius: max(finalR, 16),
                gradient: CleanMyMacPalette.gradient(for: items[i].colorIndex, isOther: items[i].isOther)
            ))
        }
        
        return result
    }
}

struct BubbleItemView: View {
    let node: BubbleNode
    let isSelected: Bool
    let isHovered: Bool
    let percentage: Double
    
    private var diameter: CGFloat {
        node.radius * 2
    }
    
    private var iconInfo: ItemIconResolver.IconInfo {
        ItemIconResolver.icon(for: node.item)
    }
    
    var body: some View {
        ZStack {
            // Main Bubble Gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: node.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Specular Highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        center: .init(x: 0.32, y: 0.28),
                        startRadius: 0,
                        endRadius: node.radius * 0.85
                    )
                )
            
            // Ambient inner rim stroke
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.clear,
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // Content inside the Bubble
            VStack(spacing: 1.5) {
                if node.radius >= 38 {
                    Image(systemName: iconInfo.systemName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                    
                    Text(node.item.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: diameter * 0.76)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                    
                    Text(node.item.formattedSize)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                } else if node.radius >= 25 {
                    Image(systemName: iconInfo.systemName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                    
                    Text(node.item.formattedSize)
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                } else {
                    Image(systemName: iconInfo.systemName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(4)
        }
        .frame(width: diameter, height: diameter)
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: isSelected ? 3.5 : 0)
                .shadow(color: Color.white.opacity(0.9), radius: 5)
        )
        .shadow(
            color: isSelected
                ? (node.gradient.first?.opacity(0.65) ?? .black.opacity(0.3))
                : (isHovered ? node.gradient.first?.opacity(0.45) ?? .clear : .black.opacity(0.2)),
            radius: isSelected ? 8 : (isHovered ? 6 : 3),
            x: 0,
            y: isSelected ? 4 : (isHovered ? 3 : 2)
        )
        .scaleEffect(isSelected ? 1.08 : (isHovered ? 1.04 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Bar Chart View (With Rich Assets & Double-Click Navigation)

struct BarChartView: View {
    let items: [ChartItem]
    let totalSize: Int64
    @Binding var selectedItem: ChartItem?
    var onEnterFolder: ((ChartItem) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            // Segmented storage bar at top
            SegmentedStorageBar(
                items: items,
                totalSize: totalSize,
                selectedItem: $selectedItem,
                onEnterFolder: onEnterFolder
            )
            .frame(height: 18)
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // Ranked List
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 5) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let isSelected = selectedItem?.id == item.id ||
                            (selectedItem?.isOther == true && item.isOther)
                        let gradient = CleanMyMacPalette.gradient(for: item.colorIndex, isOther: item.isOther)
                        let percent = totalSize > 0 ? (Double(item.size) / Double(totalSize) * 100) : 0
                        
                        BarRowItem(
                            rank: index + 1,
                            item: item,
                            gradient: gradient,
                            percentage: percent,
                            isSelected: isSelected
                        )
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            if !item.isOther && item.isDirectory {
                                onEnterFolder?(item)
                            }
                        }
                        .onTapGesture(count: 1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    selectedItem = nil
                                } else {
                                    selectedItem = item
                                }
                            }
                        }
                        .help("\(item.name): \(item.formattedSize) (\(String(format: "%.1f", percent))%)\(item.isDirectory && !item.isOther ? "\n(Double-click to open folder)" : "")")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
    }
}

struct SegmentedStorageBar: View {
    let items: [ChartItem]
    let totalSize: Int64
    @Binding var selectedItem: ChartItem?
    var onEnterFolder: ((ChartItem) -> Void)? = nil
    
    var body: some View {
        GeometryReader { geo in
            let availableWidth = max(geo.size.width - CGFloat(items.count - 1) * 2, 10)
            HStack(spacing: 2) {
                ForEach(items) { item in
                    let isSelected = selectedItem?.id == item.id ||
                        (selectedItem?.isOther == true && item.isOther)
                    let fraction = totalSize > 0 ? (Double(item.size) / Double(totalSize)) : 0
                    let segmentWidth = max(CGFloat(fraction) * availableWidth, 5)
                    let gradient = CleanMyMacPalette.gradient(for: item.colorIndex, isOther: item.isOther)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: segmentWidth)
                        .opacity(selectedItem == nil || isSelected ? 1.0 : 0.45)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                        )
                        .onTapGesture(count: 2) {
                            if !item.isOther && item.isDirectory {
                                onEnterFolder?(item)
                            }
                        }
                        .onTapGesture(count: 1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    selectedItem = nil
                                } else {
                                    selectedItem = item
                                }
                            }
                        }
                        .help("\(item.name): \(item.formattedSize) (\(String(format: "%.1f", fraction * 100))%)")
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct BarRowItem: View {
    let rank: Int
    let item: ChartItem
    let gradient: [Color]
    let percentage: Double
    let isSelected: Bool
    
    @State private var isHovered: Bool = false
    
    private var iconInfo: ItemIconResolver.IconInfo {
        ItemIconResolver.icon(for: item)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Rank badge / Dot
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)
                
                if item.isOther {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Rich Specific Icon
            Image(systemName: iconInfo.systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconInfo.color)
                .frame(width: 16)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                // Mini proportional bar
                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 3)
                        Capsule()
                            .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(barGeo.size.width * CGFloat(percentage / 100), 2), height: 3)
                    }
                }
                .frame(height: 3)
            }
            
            Spacer()
            
            // Size & Percentage
            VStack(alignment: .trailing, spacing: 1) {
                Text(item.formattedSize)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.15)
                        : (isHovered ? Color.secondary.opacity(0.08) : Color.clear)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Selected Item Details Card (With Rich Icons, Trash & Enter Folder Buttons)

struct SelectedItemCard: View {
    @EnvironmentObject private var analyzer: Analyzer
    let item: ChartItem
    let totalSize: Int64
    let onDeselect: () -> Void
    var onEnterFolder: (() -> Void)? = nil
    
    @State private var showDeleteConfirm: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    
    private var percentString: String {
        guard totalSize > 0 else { return "0%" }
        let pct = Double(item.size) / Double(totalSize) * 100
        return String(format: "%.1f%%", pct)
    }
    
    private var gradient: [Color] {
        CleanMyMacPalette.gradient(for: item.colorIndex, isOther: item.isOther)
    }
    
    private var iconInfo: ItemIconResolver.IconInfo {
        ItemIconResolver.icon(for: item)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with Gradient Icon & Close button
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: gradient.first?.opacity(0.4) ?? .clear, radius: 4, y: 2)
                    
                    Image(systemName: iconInfo.systemName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(2)
                        .truncationMode(.middle)
                    
                    Text("\(item.formattedSize)  •  \(percentString) of total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDeselect) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Deselect item")
            }
            
            Divider()
            
            // Metadata Fields
            VStack(spacing: 4) {
                LabelValueItem("Type", value: item.isOther ? "Grouped items" : (item.isDirectory ? "Folder" : "File"))
                LabelValueItem("Size", value: item.formattedSize)
                LabelValueItem("Items", value: "\(item.itemsCount)")
                
                if !item.path.isEmpty {
                    LabelValueItem("Path", value: item.path, valueSelection: true)
                }
            }
            
            // Action Buttons
            if !item.path.isEmpty {
                Divider()
                HStack(spacing: 6) {
                    // Enter Folder Button if directory
                    if item.isDirectory && !item.isOther {
                        Button(action: {
                            onEnterFolder?()
                        }) {
                            Label("Open", systemImage: "arrow.right.circle.fill")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .help("Inspect and edit contents of this folder")
                    }
                    
                    Button(action: {
                        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                    }) {
                        Label("Finder", systemImage: "folder")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Reveal in Finder")
                    
                    Spacer()
                    
                    Button(role: .destructive, action: {
                        self.showDeleteConfirm = true
                    }) {
                        Label("Move to Trash", systemImage: "trash.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Move to Trash directly without opening Finder")
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(gradient.first?.opacity(0.4) ?? Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .alert("Move to Trash?", isPresented: $showDeleteConfirm) {
            Button("Move to Trash", role: .destructive) {
                do {
                    try analyzer.deleteItem(at: item.path)
                    onDeselect()
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to move \"\(item.name)\" to the Trash?")
        }
        .alert("Error deleting item", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred while moving the item to the Trash.")
        }
    }
}

// MARK: - Folder Stats Card

struct FolderStatsCard: View {
    let entity: Entity?
    let stats: Analyzer.Stats?
    let topCount: Int
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Folder Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let duration = stats?.formattedDuration {
                    Text("Scanned in \(duration)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 2)
            
            if let entity = entity {
                LabelValueItem("Path", value: entity.path, valueSelection: true)
                LabelValueItem("Total size", value: entity.formattedSize)
                LabelValueItem("Total objects", value: "\(entity.items)")
                
                let foldersCount = entity.children.filter { $0.isDirectory }.count
                let filesCount = entity.children.filter { !$0.isDirectory }.count
                LabelValueItem("Folders", value: "\(foldersCount)")
                LabelValueItem("Files", value: "\(filesCount)")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Label Value Row

struct LabelValueItem: View {
    private let label: String
    private let value: String
    private let valueSelection: Bool
    
    init(_ label: String, value: String, valueSelection: Bool = false) {
        self.label = label
        self.value = value
        self.valueSelection = valueSelection
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(self.label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            if self.valueSelection {
                Text(self.value)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
            } else {
                Text(self.value)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }
}
