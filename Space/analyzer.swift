//
//  analyzer.swift
//  Space
//
//  Created by Serhiy Mytrovtsiy on 24/06/2025
//  Using Swift 6.0
//  Running on macOS 15.5
//
//  Copyright © 2025 Serhiy Mytrovtsiy. All rights reserved.
//

import SwiftUI
import os

struct Entity: Identifiable, Comparable {
    let id = UUID()
    let name: String
    let path: String
    let type: EntityType
    var size: Int64
    var items: Int
    var children: [Entity]
    var level: Int = 0
    
    var isDirectory: Bool { self.type == .folder }
    var formattedSize: String { ByteCountFormatter.string(fromByteCount: self.size, countStyle: .file) }
    
    init(name: String, path: String, size: Int64 = 0, items: Int = 1, isDirectory: Bool = false, children: [Entity] = []) {
        self.name = name
        self.path = path
        self.size = size
        self.items = items
        self.children = children
        self.type = isDirectory ? .folder : .file
    }
    
    static func < (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.size < rhs.size
    }
}

enum EntityType: String, Comparable {
    case folder, file
    
    private var sortOrder: Int {
        switch self {
        case .folder:
            return 0
        case .file:
            return 1
        }
    }
    
    static func ==(lhs: EntityType, rhs: EntityType) -> Bool {
        return lhs.sortOrder == rhs.sortOrder
    }
    
    static func <(lhs: EntityType, rhs: EntityType) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}

class Analyzer: ObservableObject {
    @Published var status: Status = .unknown
    @Published var errorMessage: String?
    
    @Published var analyzedEntities: [Entity] = []
    @Published var stats: Stats?
    
    @AppStorage("scanHiddenFiles") private var scanHiddenFiles: Bool = true
    
    private let cancelled = OSAllocatedUnfairLock(initialState: false)
    
    private static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter
    }()
    
    enum Status {
        case unknown, running, completed, cancelled, error
    }
    
    struct Stats {
        var start = Date()
        var duration: TimeInterval = 0
        
        var size: Int64 = 0
        var folders: Int = 0
        var files: Int = 0
        var entities: Int = 0
        
        var formattedSize: String {
            Analyzer.sizeFormatter.string(fromByteCount: size)
        }
        
        var formattedDuration: String {
            let duration = Int(self.duration)
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60
            let seconds = duration % 60
            if hours > 0 {
                return String(format: "%dh %dm %ds", hours, minutes, seconds)
            } else if minutes > 0 {
                return String(format: "%dm %ds", minutes, seconds)
            } else {
                return String(format: "%ds", seconds)
            }
        }
    }
    
    private class Node {
        let name: String
        let path: String
        var size: Int64 = 0
        var items: Int = 0
        let isDirectory: Bool
        var children: [Node] = []
        weak var parent: Node?
        
        init(name: String, path: String, isDirectory: Bool) {
            self.name = name
            self.path = path
            self.isDirectory = isDirectory
        }
        
        func toEntity() -> Entity {
            let sortedChildren = children.sorted { $0.size > $1.size }.map { $0.toEntity() }
            let totalItems = isDirectory ? sortedChildren.reduce(0) { $0 + $1.items } : 1
            return Entity(name: name, path: path, size: size, items: totalItems, isDirectory: isDirectory, children: sortedChildren)
        }
    }
    
    init() {
        #if DEBUG
        self.generateSampleData()
        #endif
    }
    
    public func start(_ path: String, pathCallback: ((String) -> Void)? = nil) {
        self.status = .running
        self.cancelled.withLock { $0 = false }
        self.analyzedEntities = []
        self.stats = Stats()
        let startTime = Date()
        let scanHidden = self.scanHiddenFiles
        
        let beginScan = { (resolvedPath: String) in
            DispatchQueue.global(qos: .userInitiated).async {
                let results = self.analyzeFolder(at: resolvedPath, startTime: startTime, scanHiddenFiles: scanHidden)
                DispatchQueue.main.async {
                    self.analyzedEntities = results
                    if self.status != .cancelled {
                        self.status = .completed
                    }
                }
            }
        }
        
        if FileManager.default.isReadableFile(atPath: path) {
            beginScan(path)
        } else {
            Self.requestFolderAccess { selectedURL in
                guard let selectedURL = selectedURL else { return }
                pathCallback?(selectedURL.path)
                beginScan(selectedURL.path)
            }
        }
    }
    
    public func stop() {
        self.cancelled.withLock { $0 = true }
        self.status = .cancelled
    }
    
    static func requestFolderAccess(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Please select a folder to analyze"
        openPanel.prompt = "Analyze"
        
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.url)
            } else {
                completion(nil)
            }
        }
    }
    
    private func analyzeFolder(at path: String, startTime: Date, scanHiddenFiles: Bool) -> [Entity] {
        var rootStat = stat()
        guard lstat(path, &rootStat) == 0, (rootStat.st_mode & S_IFMT) == S_IFDIR else {
            return []
        }

        let rootName = (path as NSString).lastPathComponent
        let rootNode = Node(name: rootName, path: path, isDirectory: true)
        let rootLock = NSLock()

        DispatchQueue.main.async {
            self.analyzedEntities = [rootNode.toEntity()]
        }

        let topChildren = self.listDirectory(path, scanHidden: scanHiddenFiles)

        let statsLock = OSAllocatedUnfairLock(initialState: Stats())
        statsLock.withLock { $0.start = startTime }

        let lastUpdateTime = OSAllocatedUnfairLock(initialState: CFAbsoluteTimeGetCurrent())

        DispatchQueue.concurrentPerform(iterations: topChildren.count) { index in
            if self.cancelled.withLock({ $0 }) { return }

            let entry = topChildren[index]
            let childNode = Node(name: entry.name, path: entry.path, isDirectory: entry.isDir)

            if entry.isDir {
                self.scanDirectoryRecursive(node: childNode, scanHidden: scanHiddenFiles)
            } else {
                childNode.size = entry.size
            }

            let childFiles: Int
            let childFolders: Int
            let childSize: Int64
            if entry.isDir {
                (childFiles, childFolders, childSize) = self.countStats(childNode)
            } else {
                childFiles = 1
                childFolders = 0
                childSize = entry.size
            }

            rootLock.lock()
            childNode.parent = rootNode
            rootNode.children.append(childNode)
            rootNode.size += childNode.size
            rootNode.items += (entry.isDir ? childNode.items : 1)
            rootLock.unlock()

            statsLock.withLock {
                $0.files += childFiles
                $0.folders += childFolders + (entry.isDir ? 1 : 0)
                $0.size += childSize
                $0.entities += childFiles + childFolders + (entry.isDir ? 1 : 0)
                $0.duration = Date().timeIntervalSince(startTime)
            }

            let now = CFAbsoluteTimeGetCurrent()
            let shouldUpdate = lastUpdateTime.withLock { last -> Bool in
                if now - last > 0.5 {
                    last = now
                    return true
                }
                return false
            }

            if shouldUpdate {
                let currentStats = statsLock.withLock { $0 }
                rootLock.lock()
                let currentRoot = rootNode.toEntity()
                rootLock.unlock()
                DispatchQueue.main.async {
                    self.stats = currentStats
                    self.analyzedEntities = [currentRoot]
                }
            }
        }

        let finalStats = statsLock.withLock { stats -> Stats in
            var s = stats
            s.duration = Date().timeIntervalSince(startTime)
            return s
        }
        DispatchQueue.main.async {
            self.stats = finalStats
        }

        rootLock.lock()
        let result = rootNode.toEntity()
        rootLock.unlock()
        return [result]
    }

    private struct DirEntry {
        let name: String
        let path: String
        let isDir: Bool
        let size: Int64
    }

    private static let excludedPaths: Set<String> = [
        "/System/Volumes/Data",
        "/System/Volumes/Preboot",
        "/System/Volumes/VM",
        "/System/Volumes/Update",
        "/System/Volumes/xarts",
        "/System/Volumes/iSCPreboot",
        "/System/Volumes/Hardware",
        "/System/Volumes/Recovery"
    ]

    private func listDirectory(_ path: String, scanHidden: Bool) -> [DirEntry] {
        guard let dir = opendir(path) else { return [] }
        defer { closedir(dir) }

        var entries: [DirEntry] = []
        while let entry = readdir(dir) {
            let name = withUnsafePointer(to: entry.pointee.d_name) { ptr in
                String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }
            if name == "." || name == ".." || name == ".DS_Store" { continue }
            if !scanHidden && name.hasPrefix(".") { continue }

            let fullPath = path.hasSuffix("/") ? path + name : path + "/" + name
            if Self.excludedPaths.contains(fullPath) { continue }
            var fileStat = stat()
            guard lstat(fullPath, &fileStat) == 0 else { continue }

            let isDir = (fileStat.st_mode & S_IFMT) == S_IFDIR
            // Use allocated block count rather than logical size: accounts for sparse files
            // (Docker.raw, VM images) and APFS compression, matching what the disk actually holds.
            let size = isDir ? Int64(0) : Int64(fileStat.st_blocks) * 512

            if !isDir && size == 0 { continue }

            entries.append(DirEntry(name: name, path: fullPath, isDir: isDir, size: size))
        }
        return entries
    }

    private func scanDirectoryRecursive(node: Node, scanHidden: Bool) {
        if self.cancelled.withLock({ $0 }) { return }

        let entries = listDirectory(node.path, scanHidden: scanHidden)
        for entry in entries {
            let child = Node(name: entry.name, path: entry.path, isDirectory: entry.isDir)
            child.size = entry.size
            child.parent = node
            node.children.append(child)

            if entry.isDir {
                scanDirectoryRecursive(node: child, scanHidden: scanHidden)
                node.size += child.size
                node.items += child.items
            } else {
                node.size += entry.size
                node.items += 1
            }
        }
    }

    private func countStats(_ node: Node) -> (files: Int, folders: Int, size: Int64) {
        var files = 0
        var folders = 0
        var size: Int64 = 0

        for child in node.children {
            if child.isDirectory {
                folders += 1
                let (f, d, s) = countStats(child)
                files += f
                folders += d
                size += s
            } else {
                files += 1
                size += child.size
            }
        }
        return (files, folders, size)
    }
    
    private func generateSampleData() {
        self.status = .running
        
        let root = Entity(
            name: "Documents",
            path: "/Users/exelban/Documents",
            isDirectory: true,
            children: [
                // Projects folder with code files
                Entity(
                    name: "Projects",
                    path: "/Users/exelban/Documents/Projects",
                    isDirectory: true,
                    children: [
                        Entity(
                            name: "Space",
                            path: "/Users/exelban/Documents/Projects/Space",
                            isDirectory: true,
                            children: [
                                Entity(name: "main.swift", path: "/Users/exelban/Documents/Projects/Space/main.swift", size: 4_582),
                                Entity(name: "analyzer.swift", path: "/Users/exelban/Documents/Projects/Space/analyzer.swift", size: 18_721),
                                Entity(name: "ContentView.swift", path: "/Users/exelban/Documents/Projects/Space/ContentView.swift", size: 12_356),
                                Entity(name: "Space.xcodeproj", path: "/Users/exelban/Documents/Projects/Space/Space.xcodeproj", size: 345_672)
                            ]
                        ),
                        Entity(name: "README.md", path: "/Users/exelban/Documents/Projects/README.md", size: 2_341)
                    ]
                ),
                // Media folder with large files
                Entity(
                    name: "Media",
                    path: "/Users/exelban/Documents/Media",
                    isDirectory: true,
                    children: [
                        Entity(
                            name: "Photos",
                            path: "/Users/exelban/Documents/Media/Photos",
                            isDirectory: true,
                            children: [
                                Entity(name: "vacation.jpg", path: "/Users/exelban/Documents/Media/Photos/vacation.jpg", size: 3_582_412),
                                Entity(name: "family.jpg", path: "/Users/exelban/Documents/Media/Photos/family.jpg", size: 2_841_523),
                                Entity(name: "screenshot.png", path: "/Users/exelban/Documents/Media/Photos/screenshot.png", size: 842_156)
                            ]
                        ),
                        Entity(
                            name: "Videos",
                            path: "/Users/exelban/Documents/Media/Videos",
                            isDirectory: true,
                            children: [
                                Entity(name: "presentation.mp4", path: "/Users/exelban/Documents/Media/Videos/presentation.mp4", size: 254_857_621),
                                Entity(name: "tutorial.mov", path: "/Users/exelban/Documents/Media/Videos/tutorial.mov", size: 189_458_236)
                            ]
                        )
                    ]
                ),
                // Documents with various file types
                Entity(name: "report.pdf", path: "/Users/exelban/Documents/report.pdf", size: 1_254_896),
                Entity(name: "budget.xlsx", path: "/Users/exelban/Documents/budget.xlsx", size: 458_235),
                Entity(name: "notes.txt", path: "/Users/exelban/Documents/notes.txt", size: 12_458),
                Entity(name: "archive.zip", path: "/Users/exelban/Documents/archive.zip", size: 28_547_852)
            ]
        )
        
        var updatedRoot = root
        self.updateDirectorySizes(entity: &updatedRoot)
        self.analyzedEntities = [updatedRoot]
        
        var stats = Stats()
        stats.duration = 1.5
        stats.entities = 20
        stats.folders = 6
        stats.files = 14
        stats.size = self.calculateTotalSize(entity: updatedRoot)
        self.stats = stats
        
        self.status = .completed
    }

    private func updateDirectorySizes(entity: inout Entity) {
        if entity.isDirectory {
            var totalSize: Int64 = 0
            var totalItems: Int = 0
            for i in 0..<entity.children.count {
                var child = entity.children[i]
                updateDirectorySizes(entity: &child)
                entity.children[i] = child
                totalSize += child.size
                totalItems += child.items
            }
            entity.size = totalSize
            entity.items = totalItems
        }
    }

    private func calculateTotalSize(entity: Entity) -> Int64 {
        if !entity.isDirectory {
            return entity.size
        }

        var totalSize: Int64 = 0
        for child in entity.children {
            totalSize += calculateTotalSize(entity: child)
        }
        return totalSize
    }
}
