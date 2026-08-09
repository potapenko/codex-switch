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
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let appState = AppState()
    private let popoverLayout = PopoverLayoutState(
        visibleScreenHeight: NSScreen.main?.visibleFrame.height ?? 800
    )
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var outsideClickMonitor: Any?
    private var workspaceActivationObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NSHostingController(
            rootView: MenuBarView(appState: appState, popoverLayout: popoverLayout)
        )
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
        appState.setPopoverPresented(false)
        removeOutsideClickMonitor()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
        } else {
            let visibleScreenHeight = sender.window?.screen?.visibleFrame.height
                ?? NSScreen.main?.visibleFrame.height
                ?? 800
            popoverLayout.update(visibleScreenHeight: visibleScreenHeight)
            appState.setPopoverPresented(true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            if !popover.isShown {
                appState.setPopoverPresented(false)
                return
            }
            installOutsideClickMonitor()
            Task {
                await appState.refreshAll()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        removeOutsideClickMonitor()
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
