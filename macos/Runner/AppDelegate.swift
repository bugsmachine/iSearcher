import Cocoa
import FlutterMacOS
import Sparkle
import Foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    // Add the Sparkle updater controller
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    // Keep a strong reference to the settings window controller
    var settingsWindowController: NSWindowController?

    // Add a window property
    var window: NSWindow?
    
    var flaskProcess: Process?

    // Method channel for communication with Flutter
    var channel: FlutterMethodChannel?
    
    var channel2: FlutterMethodChannel?
    

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
        
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"
        print("Bundle Identifier: \(bundleIdentifier)")
        print("App Version: \(appVersion)")
        
        
        // handel the help menu
        let helpMenu = mainMenu?.items.last?.submenu
        // add the iSearcher Help menu item which click will lead to open the website page in browser
        let helpMenuItem = NSMenuItem(title: "iSearcher Help", action: #selector(openHelpPage), keyEquivalent: "")
        helpMenu?.addItem(helpMenuItem)
        // add a separator
        helpMenu?.addItem(NSMenuItem.separator())
        // add the Released Version menu item
        let versionMenuItem = NSMenuItem(title: "Release Notes", action: #selector(openHelpPage), keyEquivalent: "")
        helpMenu?.addItem(versionMenuItem)
        // add the github page link
        let githubMenuItem = NSMenuItem(title: "Github Page", action: #selector(openHelpPage), keyEquivalent: "")
        helpMenu?.addItem(githubMenuItem)
        helpMenu?.addItem(NSMenuItem.separator())
        let reportIssueMenuItem = NSMenuItem(title: "Report Issue", action: #selector(openHelpPage), keyEquivalent: "")
        helpMenu?.addItem(reportIssueMenuItem)
        

    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Call the existing Flutter setup
        super.applicationDidFinishLaunching(notification)
        
        print("applicationDidFinishLaunching called")
            
        
        // Optionally, you can set Sparkle to check for updates in the background
        updaterController.updater.checkForUpdatesInBackground()
        // print the current version
    }

    override func applicationDidBecomeActive(_ notification: Notification) {
        // Set the window property
        if let window = NSApplication.shared.windows.first {
            self.window = window
        }
    }

    @objc func openHelpPage() {

        // open the link in browser
        if let url = URL(string: "https://github.com/bugsmachine/iSearcher") {
            NSWorkspace.shared.open(url)
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
