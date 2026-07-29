import AppKit
import SwiftUI

@main
enum CodexSwitchApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSWindowDelegate {
    private let appState = AppState()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var cliSettingsWindow: NSWindow?
    private var outsideClickMonitor: Any?
    private var workspaceActivationObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NSHostingController(rootView: MenuBarView(
            appState: appState,
            openCLISettings: { [weak self] in self?.showCLISettings() }
        ))
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        popover.behavior = .transient
        popover.delegate = self
        workspaceActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  application.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                return
            }
            Task { @MainActor in
                self?.closePopover()
            }
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let statusIcon = NSImage(named: "StatusIcon")
        statusIcon?.isTemplate = true
        statusIcon?.size = NSSize(width: 20, height: 20)
        statusItem.button?.image = statusIcon
        statusItem.button?.setAccessibilityLabel("CodexSwitch")
        statusItem.button?.toolTip = "Codex account status"
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp])
        self.statusItem = statusItem

    }

    func applicationDidResignActive(_ notification: Notification) {
        closePopover()
    }

    func applicationWillTerminate(_ notification: Notification) {
        removeOutsideClickMonitor()
        if let workspaceActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceActivationObserver)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        removeOutsideClickMonitor()
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === cliSettingsWindow else { return }
        cliSettingsWindow = nil
        appState.dismissCLISettingsRequest()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
        } else {
            Task {
                await appState.refreshAll()
            }
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            installOutsideClickMonitor()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        removeOutsideClickMonitor()
    }

    private func showCLISettings() {
        if let cliSettingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            cliSettingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        closePopover()
        let controller = NSHostingController(rootView: CodexCLISettingsDialog(
            appState: appState,
            close: { [weak self] in self?.cliSettingsWindow?.close() }
        ))
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 300),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "Codex CLI"
        window.contentViewController = controller
        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
        window.delegate = self
        window.center()
        cliSettingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        guard let outsideClickMonitor else { return }
        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }
}
