//
//  MainViewController.swift
//  NotificationTestBench
//
//  Created by Evan O'Connor on 02/09/2022.
//

import AppKit
import UserNotifications


// MARK: - MainViewController
class MainViewController: NSViewController {
    
    // MARK: Fields
    override var nibName: NSNib.Name? {
        return "MainView"
    }
    @IBOutlet private var tabView: NSTabView!
    @IBOutlet weak private var placeholderTabViewItem: NSTabViewItem!
    @IBOutlet private var preferencesButton: NSButton!
    @IBOutlet private var requestAuthorizationButton: NSButton!
    @IBOutlet private var clearNotificationsButton: NSButton!
    @IBOutlet private var sendNotificationButton: NSButton!
    private var authorizationTabViewController: AuthorizationTabViewController!
    private var contentTabViewController: ContentTabViewController!
	private var historyTabViewController: HistoryTabViewController!
    private var authorizationCheckTimer: Timer?
	
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainView loaded")
        
        setupUi()
        
        NotificationCenter.default.addObserver(forName: NSNotification.deliveredNotificationsChanged,
                                               object: NotificationManager.shared,
                                               queue: nil,
                                               using: self.onDeliveredNotificationsChangedHandler(_:))
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        authorizationCheckTimer = Timer.scheduledTimer(timeInterval: 2,
                                                       target: self,
                                                       selector: #selector(self.authorizationCheckTimerCallback),
                                                       userInfo: nil,
                                                       repeats: true)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        authorizationCheckTimer?.invalidate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Actions
    
    @IBAction private func onPreferencesButtonClicked(_ sender: NSButton) {
        print("preferencesButton clicked")
        
        openSystemNotificationPreferences()
    }

    @IBAction private func onRequestAuthorizationButtonClicked(_ sender: NSButton) {
        print("requestAuthorizationButton clicked")
        
        let authorizationOptions = authorizationTabViewController.getAuthorizationOptions()
        NotificationManager.shared.requestAuthorization(for: authorizationOptions)
    }
    
    @IBAction func onClearNotificationsButtonClicked(_ sender: NSButton) {
        print("clearNotificationsButton clicked")
        
        NotificationManager.shared.removePendingAndDeliveredNotifications()
    }
    
    @IBAction func onSendNotificationsButtonClicked(_ sender: NSButton) {
        print("sendNotificationButton clicked")
        
        let notificationContent = contentTabViewController.getMessageContent()
        NotificationManager.shared.sendNotification(content: notificationContent)
    }
    
    
    // MARK: Private Methods
    
    private func setupUi() {
        // remove the placeholder tab view item
        tabView.removeTabViewItem(placeholderTabViewItem)
        
        setupAuthorizationTab()
        setupContentTab()
        setupHistoryTab()
        
        setButtonsEnabledIfAuthorizationRequested()
        setClearNotificationsButtonEnabled()
    }
    
    private func setupAuthorizationTab() {
        authorizationTabViewController = AuthorizationTabViewController()
        let authorizationTabViewItem = NSTabViewItem(viewController: authorizationTabViewController)
        authorizationTabViewItem.label = "Authorization"
        authorizationTabViewItem.identifier = "authorization"
        tabView.addTabViewItem(authorizationTabViewItem)
    }
    
    private func setupContentTab() {
        contentTabViewController = ContentTabViewController()
        let contentTabViewItem = NSTabViewItem(viewController: contentTabViewController)
        contentTabViewItem.label = "Content"
        contentTabViewItem.identifier = "content"
        tabView.addTabViewItem(contentTabViewItem)
        
        let _ = contentTabViewItem.view
    }
    
	private func setupHistoryTab() {
		historyTabViewController = HistoryTabViewController()
		let historyTabViewItem = NSTabViewItem(viewController: historyTabViewController)
		historyTabViewItem.label = "History"
		historyTabViewItem.identifier = "history"
		tabView.addTabViewItem(historyTabViewItem)
	}
    
    private func openSystemNotificationPreferences() {
        print("Opening Notifications pane in System preferences")
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Notifications.prefPane"))
    }
    
    private func setButtonsEnabledIfAuthorizationRequested() {
        NotificationManager.shared.hasAuthorizationBeenRequested(callback: { [weak self] authorizationHasBeenRequested in
            DispatchQueue.main.async(execute: { [weak self, authorizationHasBeenRequested] in
                self?.requestAuthorizationButton.isEnabled = !authorizationHasBeenRequested
                self?.sendNotificationButton.isEnabled = authorizationHasBeenRequested
            })
        })
    }
    
    private func setClearNotificationsButtonEnabled() {
        clearNotificationsButton.isEnabled = NotificationManager.shared.deliveredNotifications.count > 0
    }
    
    @objc private func authorizationCheckTimerCallback() {
        setButtonsEnabledIfAuthorizationRequested()
    }
    
    private func onDeliveredNotificationsChangedHandler(_ notification: Notification) {
        DispatchQueue.main.async(execute: { [weak self] in
            self?.setClearNotificationsButtonEnabled()
        })
    }
}