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
    
    @objc func open(_ sender: Any) {
        if let url = URL(string: "https://github.com/cescobaz/FullControlX") {
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
    
    func runElixir() throws -> Process {
        guard let driverURL = Bundle.main.url(forResource: "fcxd", withExtension: "") else {
            throw NSError(domain: "Resource not found", code: 1)
        }
        guard let exeURL = Bundle.main.url(forResource: "fullcontrol_x", withExtension: "", subdirectory: "fullcontrol_x/bin") else {
            throw NSError(domain: "Resource not found", code: 2)
        }
        print("[INFO] driverURL \(driverURL), exeURL \(exeURL)")
        
        let databasePath = "\(NSHomeDirectory())/sqlite.db"
        print("[INFO] databasePath \(databasePath)")
        
        let process = Process()
        process.environment = [
            "FCXD_PATH" : driverURL.path,
            "DATABASE_PATH" :
                databasePath,
            "SECRET_KEY_BASE" : "tR+7w7T35Y9/NxvAKXGYrhD5dyBy/JwTATSWC/tMIesW/UphSNbDTF1bBtZ9kAyx",
            "PORT" : "4000",
            "PHX_HOST" : "localhost",
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
            elixirProcess = try runElixir()
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
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
}

