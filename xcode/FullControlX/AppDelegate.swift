//
//  AppDelegate.swift
//  FullControlX
//
//  Created by Francesco Burelli on 04/01/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var elixirProcess: Process?
    
    var host: String = "localhost"
    var port: Int32 = 4000
    
    @objc func open(_ sender: Any) {
        if let url = URL(string: "http://\(host):\(port)/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func createStatusBarItem() -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "FullControlX"
        statusItem.button?.title = "FCX"
        
        let statusItemMenu = NSMenu(title: "FullControlX")
        statusItem.menu = statusItemMenu
        
        let openMenuItem = NSMenuItem(title: "FullControlX settings", action:#selector(AppDelegate.open), keyEquivalent: "")
        openMenuItem.target = self
        statusItemMenu.addItem(openMenuItem)
        
        statusItemMenu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit", action:#selector(NSApplication.terminate), keyEquivalent: "")
        quitMenuItem.target = NSApplication.shared
        statusItemMenu.addItem(quitMenuItem)
        
        return statusItem
    }
    
    func runElixir(host: String, port: Int32) throws -> Process {
        guard let driverURL = Bundle.main.url(forResource: "fcxd", withExtension: "") else {
            throw NSError(domain: "Resource not found", code: 1)
        }
        guard let exeURL = Bundle.main.url(forResource: "fullcontrol_x", withExtension: "", subdirectory: "fullcontrol_x/bin") else {
            throw NSError(domain: "Resource not found", code: 2)
        }
        print("[INFO] driverURL \(driverURL), exeURL \(exeURL)")
        
        guard let supportDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
            throw NSError(domain: "Support Directory not found", code: 3)
        }
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw NSError(domain: "bundleIdentifier not found", code: 3)
        }
        let appDirectory = "\(supportDirectory)/\(bundleId)"
        
        print("[INFO] appDir \(appDirectory)")
        
        let databasePath = "\(appDirectory)/sqlite.db"
        print("[INFO] databasePath \(databasePath)")
        
        let filesPath = "\(appDirectory)/files"
        if let url = URL(string: "file://\(filesPath)") {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        print("[INFO] filesPath \(filesPath)")
        
        let process = Process()
        process.environment = [
            "FCXD_PATH" : driverURL.path,
            "DATABASE_PATH" :
                databasePath,
            "FILES_PATH" :
                filesPath,
            "SECRET_KEY_BASE" : "tR+7w7T35Y9/NxvAKXGYrhD5dyBy/JwTATSWC/tMIesW/UphSNbDTF1bBtZ9kAyx",
            "PORT" : "\(port)",
            "PHX_HOST" : host,
            "PHX_SERVER" : "true"
        ]
        process.arguments = ["start"]
        process.launchPath = exeURL.path
        process.launch()
        
        return process
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        statusItem = createStatusBarItem()
        do {
            elixirProcess = try runElixir(host: host, port: port)
        } catch {
            print("[ERROR] \(error)")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if let statusItem = statusItem {
            statusItem.statusBar?.removeStatusItem(statusItem)
        }
        if let process = elixirProcess {
            process.terminate()
            process.waitUntilExit()
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
}

