//
//  ToolbarView.swift
//  Space
//
//  Created by Serhiy Mytrovtsiy on 25/06/2025
//  Using Swift 6.0
//  Running on macOS 15.5
//
//  Copyright © 2025 Serhiy Mytrovtsiy. All rights reserved.
//  

import SwiftUI
import AppKit

// MARK: - Comprehensive Dynamic Cache Cleaner Model & Engine

struct CacheCategory: Identifiable {
    let id: String
    let name: String
    let defaultDescription: String
    let details: String
    let icon: String
    let gradient: [Color]
    let pathPatterns: [String]
    var resolvedPaths: [String] = []
    var detectedItems: [String] = []
    var size: Int64 = 0
    var isSelected: Bool = true
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var displayDescription: String {
        if !detectedItems.isEmpty {
            let limit = 4
            let prefixItems = detectedItems.prefix(limit)
            let joined = prefixItems.joined(separator: ", ")
            let remaining = detectedItems.count - prefixItems.count
            if remaining > 0 {
                return "\(joined) +\(remaining) more"
            }
            return joined
        }
        return defaultDescription
    }
}

class CacheCleaner: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var categories: [CacheCategory] = []
    @Published var totalFoundSize: Int64 = 0
    @Published var cleanCompleted: Bool = false
    @Published var cleanedBytes: Int64 = 0
    
    var totalSelectedSize: Int64 {
        categories.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    var formattedTotalFoundSize: String {
        ByteCountFormatter.string(fromByteCount: totalFoundSize, countStyle: .file)
    }
    
    var formattedCleanedBytes: String {
        ByteCountFormatter.string(fromByteCount: cleanedBytes, countStyle: .file)
    }
    
    init() {
        self.categories = Self.defaultCategories
        self.scanCaches()
    }
    
    static let defaultCategories: [CacheCategory] = [
        // 1. JetBrains IDE Ecosystem
        CacheCategory(
            id: "jetbrains_caches",
            name: "JetBrains & IDE Caches",
            defaultDescription: "IntelliJ IDEA, WebStorm, PyCharm, PhpStorm, Rider, CLion, GoLand, Android Studio",
            details: "Compiler caches, project indices, local history and IDE temp data",
            icon: "sparkles.square.fill.on.square.fill",
            gradient: [Color(red: 0.98, green: 0.20, blue: 0.45), Color(red: 0.85, green: 0.10, blue: 0.30)],
            pathPatterns: [
                "~/Library/Caches/JetBrains",
                "~/Library/Caches/JetBrains/*",
                "~/Library/Caches/IntelliJIdea*",
                "~/Library/Caches/PyCharm*",
                "~/Library/Caches/WebStorm*",
                "~/Library/Caches/PhpStorm*",
                "~/Library/Caches/RustRover*",
                "~/Library/Caches/CLion*",
                "~/Library/Caches/Rider*",
                "~/Library/Caches/GoLand*",
                "~/Library/Caches/DataGrip*",
                "~/Library/Caches/AndroidStudio*",
                "~/Library/Caches/Google/AndroidStudio*",
                "~/Library/Application Support/JetBrains/Toolbox/cache",
                "~/Library/Application Support/JetBrains/Toolbox/download",
                "~/Library/Application Support/JetBrains/*/log",
                "~/Library/Logs/JetBrains",
                "~/Library/Logs/JetBrains/*"
            ]
        ),
        
        // 2. Xcode & Apple Developer
        CacheCategory(
            id: "xcode_caches",
            name: "Xcode & Apple Developer",
            defaultDescription: "DerivedData, ModuleCache, iOS Simulator caches and build archives",
            details: "Intermediate build outputs, symbol caches and iOS simulator cache",
            icon: "hammer.fill",
            gradient: [Color(red: 0.14, green: 0.58, blue: 0.98), Color(red: 0.08, green: 0.36, blue: 0.88)],
            pathPatterns: [
                "~/Library/Developer/Xcode/DerivedData",
                "~/Library/Developer/Xcode/UserData/ModuleCache*",
                "~/Library/Developer/Xcode/iOS DeviceSupport",
                "~/Library/Developer/CoreSimulator/Caches",
                "~/Library/Caches/com.apple.dt.Xcode",
                "~/Library/Caches/org.swift.swiftpm"
            ]
        ),
        
        // 3. Java, Android, Gradle & Maven Build Tools
        CacheCategory(
            id: "gradle_java_caches",
            name: "Java, Gradle & Android SDK",
            defaultDescription: "Gradle daemon, jar/aar dependencies and build artifact caches",
            details: "Gradle cache (.gradle/caches), Gradle daemon logs, Maven repo (.m2) and Android build cache",
            icon: "cup.and.saucer.fill",
            gradient: [Color(red: 0.95, green: 0.55, blue: 0.15), Color(red: 0.85, green: 0.40, blue: 0.08)],
            pathPatterns: [
                "~/.gradle/caches",
                "~/.gradle/daemon",
                "~/.gradle/.tmp",
                "~/.m2/repository",
                "~/.android/cache",
                "~/.android/build-cache"
            ]
        ),
        
        // 4. Node, Cargo, Go & Python Package Managers
        CacheCategory(
            id: "package_manager_caches",
            name: "Node, Rust, Go & Python Caches",
            defaultDescription: "npm cache, Yarn, pnpm, Cargo crates, pip and Go module build cache",
            details: "Package manager download caches and compiled bytecode",
            icon: "shippingbox.fill",
            gradient: [Color(red: 0.12, green: 0.80, blue: 0.74), Color(red: 0.04, green: 0.58, blue: 0.58)],
            pathPatterns: [
                "~/.npm/_cacache",
                "~/.npm/_logs",
                "~/.npm/_npx",
                "~/Library/Caches/Yarn",
                "~/Library/Caches/pnpm",
                "~/Library/Caches/bun",
                "~/.bun/install/cache",
                "~/.cargo/registry/cache",
                "~/.cargo/git/db",
                "~/Library/Caches/go-build",
                "~/go/pkg/mod/cache",
                "~/.cache/pip",
                "~/Library/Caches/pip",
                "~/.cache/pypoetry",
                "~/.cache/huggingface",
                "~/.cache"
            ]
        ),
        
        // 5. Web Browsers & Developer Tools
        CacheCategory(
            id: "browser_caches",
            name: "Web Browser Caches",
            defaultDescription: "Google Chrome, Safari, Arc, Brave, Firefox, Microsoft Edge",
            details: "Cached web assets, Service Workers, developer inspection data & GPU cache",
            icon: "globe",
            gradient: [Color(red: 0.20, green: 0.82, blue: 0.48), Color(red: 0.10, green: 0.62, blue: 0.32)],
            pathPatterns: [
                "~/Library/Caches/Google/Chrome",
                "~/Library/Application Support/Google/Chrome/Default/Application Cache",
                "~/Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage",
                "~/Library/Application Support/Google/Chrome/Default/GPUCache",
                "~/Library/Application Support/Google/Chrome/Default/Code Cache",
                "~/Library/Caches/com.apple.Safari",
                "~/Library/Caches/com.apple.Safari.SafeBrowsing",
                "~/Library/Containers/com.apple.Safari/Data/Library/Caches",
                "~/Library/Caches/Arc",
                "~/Library/Caches/company.thebrowser.Browser",
                "~/Library/Caches/BraveSoftware/Brave-Browser",
                "~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Service Worker/CacheStorage",
                "~/Library/Application Support/BraveSoftware/Brave-Browser/Default/GPUCache",
                "~/Library/Caches/Microsoft Edge",
                "~/Library/Application Support/Microsoft Edge/Default/Service Worker/CacheStorage",
                "~/Library/Caches/Firefox",
                "~/Library/Caches/Mozilla/Firefox",
                "~/Library/Caches/com.operasoftware.Opera"
            ]
        ),
        
        // 6. Desktop Applications & User Software
        CacheCategory(
            id: "user_app_caches",
            name: "Desktop Application Caches",
            defaultDescription: "Installed macOS software and client application caches",
            details: "Temporary media, offline session caches & application runtime data",
            icon: "app.badge.fill",
            gradient: [Color(red: 0.65, green: 0.28, blue: 0.98), Color(red: 0.44, green: 0.12, blue: 0.82)],
            pathPatterns: [
                "~/Library/Caches/*",
                "~/Library/Containers/*/Data/Library/Caches"
            ]
        ),
        
        // 7. System Diagnostics & macOS Logs
        CacheCategory(
            id: "system_logs",
            name: "System Logs & Diagnostic Reports",
            defaultDescription: "macOS crash logs, diagnostic traces & saved window states",
            details: "Log files, diagnostic traces, and previous application launch session cache",
            icon: "doc.text.magnifyingglass",
            gradient: [Color(red: 0.58, green: 0.62, blue: 0.70), Color(red: 0.42, green: 0.46, blue: 0.54)],
            pathPatterns: [
                "~/Library/Logs",
                "~/Library/Logs/DiagnosticReports",
                "~/Library/Saved Application State"
            ]
        )
    ]
    
    public func scanCaches() {
        self.isScanning = true
        self.cleanCompleted = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            var updatedCats = self.categories
            var total: Int64 = 0
            
            for i in 0..<updatedCats.count {
                var catPaths: [String] = []
                for pattern in updatedCats[i].pathPatterns {
                    let resolved = Self.resolvePaths(pattern)
                    catPaths.append(contentsOf: resolved)
                }
                
                catPaths = Array(Set(catPaths))
                updatedCats[i].resolvedPaths = catPaths
                
                // Calculate dynamic detected items
                var foundNames: [String] = []
                var catSize: Int64 = 0
                
                for path in catPaths {
                    let size = Self.calculateFolderSize(at: path)
                    if size > 0 {
                        catSize += size
                        let lastComponent = (path as NSString).lastPathComponent
                        let cleanName = Self.humanReadableName(for: lastComponent, fullPath: path)
                        if !cleanName.isEmpty && !foundNames.contains(cleanName) {
                            foundNames.append(cleanName)
                        }
                    }
                }
                
                updatedCats[i].detectedItems = foundNames
                updatedCats[i].size = catSize
                total += catSize
            }
            
            DispatchQueue.main.async {
                self.categories = updatedCats
                self.totalFoundSize = total
                self.isScanning = false
            }
        }
    }
    
    public func cleanSelectedCaches(completion: @escaping (Int64) -> Void) {
        self.isCleaning = true
        self.cleanCompleted = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            var totalCleaned: Int64 = 0
            
            for cat in self.categories where cat.isSelected {
                for path in cat.resolvedPaths {
                    let cleaned = Self.cleanFolderContents(at: path)
                    totalCleaned += cleaned
                }
            }
            
            DispatchQueue.main.async {
                self.cleanedBytes = totalCleaned
                self.isCleaning = false
                self.cleanCompleted = true
                self.scanCaches()
                completion(totalCleaned)
            }
        }
    }
    
    private static func humanReadableName(for lastComponent: String, fullPath: String) -> String {
        let lower = lastComponent.lowercased()
        
        // Developer IDEs & JetBrains
        if lower.contains("intellij") { return "IntelliJ IDEA" }
        if lower.contains("webstorm") { return "WebStorm" }
        if lower.contains("pycharm") { return "PyCharm" }
        if lower.contains("phpstorm") { return "PhpStorm" }
        if lower.contains("rustrover") { return "RustRover" }
        if lower.contains("clion") { return "CLion" }
        if lower.contains("rider") { return "Rider" }
        if lower.contains("goland") { return "GoLand" }
        if lower.contains("datagrip") { return "DataGrip" }
        if lower.contains("androidstudio") { return "Android Studio" }
        if lower.contains("deriveddata") { return "DerivedData" }
        if lower.contains("modulecache") { return "ModuleCache" }
        if lower.contains("coresimulator") { return "iOS Simulator" }
        if lower.contains("swiftpm") { return "SwiftPM" }
        if lower == ".gradle" || (lower == "caches" && fullPath.contains(".gradle")) { return "Gradle Cache" }
        if lower == "daemon" && fullPath.contains(".gradle") { return "Gradle Daemon" }
        if lower == ".m2" || (lower == "repository" && fullPath.contains(".m2")) { return "Maven Repo" }
        if lower == "_cacache" || lower == ".npm" { return "npm Cache" }
        if lower == "yarn" { return "Yarn" }
        if lower == "pnpm" { return "pnpm" }
        if lower == "bun" { return "Bun" }
        if lower == "cargo" || (lower == "registry" && fullPath.contains(".cargo")) { return "Cargo Crates" }
        if lower == "go-build" { return "Go Cache" }
        if lower == "pip" { return "Pip Cache" }
        if lower == "chrome" || lower.contains("chrome") { return "Chrome" }
        if lower == "arc" || lower.contains("thebrowser") { return "Arc" }
        if lower == "safari" || lower.contains("safari") { return "Safari" }
        if lower == "firefox" || lower.contains("mozilla") { return "Firefox" }
        if lower.contains("brave") { return "Brave" }
        if lower.contains("edge") { return "Edge" }
        if lower.contains("docker") { return "Docker" }
        if lower.contains("figma") { return "Figma" }
        if lower.contains("slack") { return "Slack" }
        if lower.contains("spotify") { return "Spotify" }
        if lower.contains("discord") { return "Discord" }
        if lower.contains("adobe") { return "Adobe" }
        
        // Bundle identifier extraction (e.g. com.company.AppName -> AppName)
        if lastComponent.contains(".") {
            let parts = lastComponent.split(separator: ".")
            if let lastPart = parts.last, lastPart.count > 2 && !lastPart.hasPrefix("plist") {
                return String(lastPart)
            }
        }
        
        // Default clean string
        if lastComponent.count > 2 && !lastComponent.hasPrefix(".") {
            return lastComponent.capitalized
        }
        return ""
    }
    
    private static func resolvePaths(_ pattern: String) -> [String] {
        let expanded = (pattern as NSString).expandingTildeInPath
        if !expanded.contains("*") {
            return FileManager.default.fileExists(atPath: expanded) ? [expanded] : []
        }
        
        var results: [String] = []
        var gt = glob_t()
        if glob(expanded.cString(using: .utf8), 0, nil, &gt) == 0 {
            for i in 0..<Int(gt.gl_matchc) {
                if let cStr = gt.gl_pathv[i] {
                    let path = String(cString: cStr)
                    results.append(path)
                }
            }
        }
        globfree(&gt)
        return results
    }
    
    private static func calculateFolderSize(at path: String) -> Int64 {
        guard FileManager.default.fileExists(atPath: path) else { return 0 }
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            var statBuf = stat()
            if lstat(path, &statBuf) == 0 {
                return Int64(statBuf.st_blocks) * 512
            }
            return 0
        }
        
        var total: Int64 = 0
        let url = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            if let vals = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]) {
                if vals.isRegularFile == true {
                    let size = vals.totalFileAllocatedSize ?? vals.fileAllocatedSize ?? 0
                    total += Int64(size)
                }
            }
        }
        return total
    }
    
    private static func cleanFolderContents(at path: String) -> Int64 {
        let beforeSize = calculateFolderSize(at: path)
        guard beforeSize > 0, FileManager.default.fileExists(atPath: path) else { return 0 }
        
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            try? fm.removeItem(atPath: path)
            return beforeSize
        }
        
        guard let items = try? fm.contentsOfDirectory(atPath: path) else { return 0 }
        
        for item in items {
            if item == ".DS_Store" || item == "." || item == ".." { continue }
            let fullPath = (path as NSString).appendingPathComponent(item)
            try? fm.removeItem(atPath: fullPath)
        }
        
        let afterSize = calculateFolderSize(at: path)
        return max(0, beforeSize - afterSize)
    }
}

// MARK: - Toolbar View

struct ToolbarView: ToolbarContent {
    @ObservedObject public var analyzer: Analyzer
    @Binding public var width: CGFloat
    @State private var path: String = NSHomeDirectory()
    @State private var showStatusInfo: Bool = false
    @State private var showCacheCleaner: Bool = false
    @StateObject private var cacheCleaner = CacheCleaner()
    
    @State private var settingsWindow: NSWindow?
    
    // Balanced navbar width so buttons on the right never get truncated
    private var navbarWidth: CGFloat {
        let target = self.width - 500
        return max(260, min(target, 400))
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: {
                self.openSettingsWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17))
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 6)
            .help(Text("Open settings"))
        }
        
        ToolbarItem(placement: .principal) {
            HStack(spacing: 8) {
                Button(action: {
                    self.selectFolder()
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .padding(.leading, 6)
                
                TextField("Path to folder to analyze", text: $path)
                    .font(.system(size: 13))
                    .padding(.vertical, 6)
                    .focusEffectDisabled()
                    .textFieldStyle(PlainTextFieldStyle())
                    .background(Color.clear)
                    .onSubmit {
                        guard self.analyzer.status != .running else { return }
                        self.analyze(self.path)
                    }
                
                Button(action: {
                    showStatusInfo = true
                }) {
                    switch self.analyzer.status {
                    case .running:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 14, height: 14)
                            .scaleEffect(0.4)
                    case .completed:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    case .cancelled, .error:
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    default:
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showStatusInfo, arrowEdge: .bottom) {
                    StatusView(status: analyzer.status, duration: analyzer.stats?.formattedDuration ?? "N/A")
                }
                .padding(.trailing, 8)
            }
            .frame(width: self.navbarWidth)
        }
        
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 8) {
                // Quick Cache Cleaner Button with generous comfortable sizing
                Button(action: {
                    self.showCacheCleaner = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.purple)
                        Text("Clean Caches")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.purple.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Clean JetBrains, Xcode, browser, app & developer caches")
                .popover(isPresented: $showCacheCleaner, arrowEdge: .bottom) {
                    CacheCleanerView(cleaner: cacheCleaner) {
                        if self.path.contains("/Library") || self.path == NSHomeDirectory() {
                            self.analyze(self.path)
                        }
                    }
                }
                
                // Scan / Stop button
                Button(action: {
                    if self.analyzer.status != .running {
                        self.analyze(self.path)
                    } else {
                        self.analyzer.stop()
                    }
                }) {
                    Image(systemName: self.analyzer.status != .running ? "play.fill" : "stop.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 4)
                .help(Text("\(self.analyzer.status != .running ? "Run" : "Stop") the analysis"))
            }
        }
    }
    
    private func analyze(_ path: String) {
        self.analyzer.start(self.path) { newPath in
            DispatchQueue.main.async {
                self.path = newPath
            }
        }
    }
    
    private func selectFolder() {
        Analyzer.requestFolderAccess { selectedURL in
            guard let selectedURL = selectedURL else { return }
            DispatchQueue.main.async {
                self.path = selectedURL.path
            }
        }
    }
    
    private func openSettingsWindow() {
        if let window = self.settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        window.contentViewController = hostingController
        
        window.setFrameOrigin(NSPoint(
            x: (NSScreen.main!.frame.width - 400)/2,
            y: ((NSScreen.main!.frame.height - 320)/1.8)
        ))
        
        window.makeKeyAndOrderFront(nil)
        
        self.settingsWindow = window
    }
}

// MARK: - Cache Cleaner Modal / Popover View (CleanMyMac Style with Dynamic Detected Names)

struct CacheCleanerView: View {
    @ObservedObject var cleaner: CacheCleaner
    var onCleanFinished: (() -> Void)? = nil
    
    @State private var showConfirmAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.28, blue: 0.98), Color(red: 0.14, green: 0.58, blue: 0.98)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.purple.opacity(0.4), radius: 5, y: 2)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean Developer & System Caches")
                        .font(.headline)
                    Text("Reclaim disk space from build artifacts, IDE indexes & app caches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    cleaner.scanCaches()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Rescan")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(cleaner.isScanning || cleaner.isCleaning)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            Divider()
            
            // Total Size Hero Banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(cleaner.isScanning ? "Scanning system..." : (cleaner.cleanCompleted ? cleaner.formattedCleanedBytes : cleaner.formattedTotalFoundSize))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(cleaner.cleanCompleted ? .green : .primary)
                        
                        Text(cleaner.cleanCompleted ? "reclaimed" : "cache files found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(cleaner.isScanning ? "Scanning IDEs, build systems, browsers & caches..." : (cleaner.cleanCompleted ? "Caches successfully cleared!" : "\(cleaner.categories.filter { $0.isSelected }.count) of \(cleaner.categories.count) categories selected (\(cleaner.formattedTotalSelectedSize))"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !cleaner.isScanning && !cleaner.cleanCompleted {
                    Button(action: {
                        let allSelected = cleaner.categories.allSatisfy { $0.isSelected }
                        for i in 0..<cleaner.categories.count {
                            cleaner.categories[i].isSelected = !allSelected
                        }
                    }) {
                        Text(cleaner.categories.allSatisfy { $0.isSelected } ? "Deselect All" : "Select All")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            // Categories List with Dynamic Detected Descriptions
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach($cleaner.categories) { $category in
                        HStack(alignment: .center, spacing: 10) {
                            Toggle("", isOn: $category.isSelected)
                                .toggleStyle(.checkbox)
                                .labelsHidden()
                                .disabled(cleaner.isScanning || cleaner.isCleaning)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: category.gradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 34, height: 34)
                                    .shadow(color: category.gradient.first?.opacity(0.3) ?? .clear, radius: 3, y: 1)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(.system(size: 12, weight: .bold))
                                
                                Text(category.displayDescription)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Text(category.details)
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(category.formattedSize)
                                    .font(.system(size: 12, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(category.size > 0 ? .primary : .secondary)
                                
                                if category.size > 0 {
                                    Text("\(category.resolvedPaths.count) locations")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(9)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(category.isSelected ? category.gradient.first?.opacity(0.5) ?? Color.clear : Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 320)
            
            Divider()
            
            // Actions & Progress Bar
            HStack {
                if cleaner.isScanning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                    Text("Scanning cache paths...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if cleaner.isCleaning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                    Text("Cleaning selected caches...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if cleaner.cleanCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Cleaning complete! Reclaimed \(cleaner.formattedCleanedBytes)")
                        .font(.caption)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Scan Again") {
                        cleaner.scanCaches()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Spacer()
                    Button(action: {
                        self.showConfirmAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                            Text("Clean Selected (\(cleaner.formattedTotalSelectedSize))")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(cleaner.totalSelectedSize == 0)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .padding(16)
        .frame(width: 460, height: 560)
        .alert("Clean Selected Caches?", isPresented: $showConfirmAlert) {
            Button("Clean Now", role: .destructive) {
                cleaner.cleanSelectedCaches { _ in
                    onCleanFinished?()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove temporary cache files, indexes and logs for selected categories (\(cleaner.formattedTotalSelectedSize)). Applications and IDEs (like JetBrains and Xcode) will recreate clean indices automatically when needed.")
        }
    }
}

// MARK: - Status View

struct StatusView: View {
    let status: Analyzer.Status
    let duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch status {
            case .running:
                Text("Analysis in progress").font(.headline)
                Divider()
                Text("The folder is being scanned...").font(.footnote)
                Text("Duration: \(duration)").font(.footnote).foregroundColor(.secondary)
            case .completed:
                Text("Analysis completed").font(.headline)
                Divider()
                Text("Scan completed successfully").font(.footnote)
                Text("Duration: \(duration)").font(.footnote).foregroundColor(.secondary)
            case .cancelled:
                Text("Analysis cancelled").font(.headline)
                Divider()
                Text("The operation was stopped by user").font(.footnote)
            case .error:
                Text("Analysis error").font(.headline)
                Divider()
                Text("An error occurred during the scan").font(.footnote)
            default:
                Text("Ready").font(.headline)
                Divider()
                Text("Click the play button to start analysis").font(.footnote)
            }
        }
        .padding()
        .frame(width: 250)
    }
}
