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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        statusItem = createStatusBarItem()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if let statusItem = statusItem {
            statusItem.statusBar?.removeStatusItem(statusItem)
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
}

