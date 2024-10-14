import Cocoa
import FlutterMacOS
import Sparkle

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    // Add the Sparkle updater controller
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    // Keep a strong reference to the settings window controller
    var settingsWindowController: NSWindowController?

    // Add a window property
    var window: NSWindow?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Add "Check for Updates..." menu item
        let mainMenu = NSApplication.shared.mainMenu
        let appMenu = mainMenu?.items.first?.submenu

        // Separator for clarity in the menu
        appMenu?.addItem(NSMenuItem.separator())

        // Add the "Check for Updates..." menu item
        let updateMenuItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateMenuItem.target = self
        appMenu?.addItem(updateMenuItem)

        // Enable the "Settings" menu item and link to settings functionality
        if let settingsItem = appMenu?.item(withTitle: "Preferences…") {
            settingsItem.action = #selector(showSettings)
            settingsItem.target = self
            settingsItem.isEnabled = true
        }
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Call the existing Flutter setup
        super.applicationDidFinishLaunching(notification)

        // Optionally, you can set Sparkle to check for updates in the background
        updaterController.updater.checkForUpdatesInBackground()
    }

    override func applicationDidBecomeActive(_ notification: Notification) {
        // Set the window property
        if let window = NSApplication.shared.windows.first {
            self.window = window
        }
    }

    // Action to trigger Sparkle's update check
    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    // Action to show the app's settings window
    @objc func showSettings() {
        // Ensure you have a reference to the FlutterViewController
        guard let flutterViewController = window?.contentViewController as? FlutterViewController else {
            print("FlutterViewController not found")
            return
        }

        // Access the FlutterEngine's binaryMessenger directly
        let binaryMessenger = flutterViewController.engine.binaryMessenger

        // Call the Dart function through the method channel
        let channel = FlutterMethodChannel(name: "com.example.app/settings", binaryMessenger: binaryMessenger)

        // Invoke the method with arguments if needed
        channel.invokeMethod("openSettings", arguments: nil) // Replace nil with any arguments if necessary
    }

    // Ensures the app quits after the last window is closed
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
