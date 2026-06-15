import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
protocol FileSelectionServicing: Sendable {
    func selectGameFolder() -> URL?
    func selectExecutableFile() -> URL?
}

@MainActor
struct FileSelectionService: FileSelectionServicing {
    func selectGameFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = String(localized: "addGame.folderPicker.title")
        panel.prompt = String(localized: "addGame.folderPicker.prompt")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    func selectExecutableFile() -> URL? {
        let panel = NSOpenPanel()
        panel.title = String(localized: "addGame.exePicker.title")
        panel.prompt = String(localized: "addGame.exePicker.prompt")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.allowedContentTypes = [UTType(filenameExtension: "exe") ?? .data]
        return panel.runModal() == .OK ? panel.url : nil
    }
}
