//
//  HistoryTabViewController.swift
//  NotificationTestBench
//
//  Created by Evan O'Connor on 02/09/2022.
//

import AppKit


// MARK: - HistoryTabViewController
class HistoryTabViewController: NSViewController {
	
	// MARK: Fields
	
	override var nibName: NSNib.Name? {
		return "HistoryTabView"
	}
	@IBOutlet private var tableView: NSTableView!
    @IBOutlet private var removeButton: NSButton!
    @IBOutlet private var helpButton: NSButton!
    @IBOutlet private var helpPopover: NSPopover!
	
	
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
        NotificationCenter.default.addObserver(forName: NSNotification.deliveredNotificationsChanged,
											   object: NotificationManager.shared,
											   queue: nil,
											   using: self.deliveredNotificationHandler(_:))
		
		tableView.delegate = self
        tableView.dataSource = self
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    
    
    // MARK: Actions
    
    @IBAction private func removeButtonClicked(_ sender: NSButton) {
        log("removeButton clicked")
        
        guard tableView.selectedRow >= 0 else { return }
        
        guard let rowView = tableView.rowView(atRow: tableView.selectedRow, makeIfNecessary: false) else { return }
        guard let cellView = rowView.view(atColumn: 0) as? NSTableCellView else { return }
        guard let notificationId = cellView.objectValue as? String else { return }
        
        NotificationManager.shared.removeNotification(withIdentifier: notificationId)
        
        tableView.reloadData()
    }
    
    @IBAction private func onHelpButtonClicked(_ sender: NSButton) {
        log()
        
        showHelpPopover()
    }
    
	
	// MARK: Private Methods
	
	private func deliveredNotificationHandler(_ notification: Notification) {
		DispatchQueue.main.async(execute: { [weak self]() in
			log("Reloading HistoryTab tableView")
			self?.tableView.reloadData()
		})
	}

    private func enableRemoveButtonIfRowIsSelected() {
        removeButton.isEnabled = (tableView.selectedRow >= 0)
    }
    
    private func showHelpPopover() {
        guard let helpPopoverViewController = helpPopover.contentViewController as? HelpPopoverViewController else { return }
        
        helpPopoverViewController.setHelpMessage(to:
            "The history tab contains a table with a row containing the details of each notification that has been delivered " +
            "by the application so far. You can select a row in the table and click the remove button to delete that notification. " +
            "Doing so will also remove the notification from the notification center."
        )
        
        helpPopover.show(relativeTo: helpButton.bounds, of: helpButton, preferredEdge: .minX)
    }
    
}


// MARK: - NSTableViewDataSource Extension
extension HistoryTabViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return NotificationManager.shared.deliveredNotifications.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let notification = NotificationManager.shared.deliveredNotifications[ NotificationManager.shared.deliveredNotifications.count - 1 - row ]
        
        switch tableColumn?.title {
            case "ID":
                return notification.identifier
            case "Title":
                return notification.content.title
            case "Subtitle":
                return notification.content.subtitle
            case "Badge":
                return notification.content.badge
            case "Sound":
                return notification.content.sound
            case "Attachment":
                return notification.content.attachments.first
            case .none:
                return nil
            case .some(_):
                return nil
        }
    }
    
}


// MARK: - NSTableViewDelegate Extension
extension HistoryTabViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let notification = NotificationManager.shared.deliveredNotifications[ NotificationManager.shared.deliveredNotifications.count - 1 - row ]
        
        var cellView: NSTableCellView?
        switch tableColumn?.title {
            case "ID":
                cellView = tableView.makeView(withIdentifier: .idCell, owner: nil) as? NSTableCellView
                cellView?.setNotificationId(notificationId: notification.identifier)
            case "Title":
                cellView = tableView.makeView(withIdentifier: .titleCell, owner: nil) as? NSTableCellView
                cellView?.setTitle(title: notification.content.title)
            case "Subtitle":
                cellView = tableView.makeView(withIdentifier: .subtitleCell, owner: nil) as? NSTableCellView
                cellView?.setSubtitle(subtitle: notification.content.subtitle)
            case "Badge":
                cellView = tableView.makeView(withIdentifier: .badgeCell, owner: nil) as? NSTableCellView
                cellView?.setBadge(badge: notification.content.badge)
            case "Sound":
                cellView = tableView.makeView(withIdentifier: .soundCell, owner: nil) as? NSTableCellView
                cellView?.setSound(sound: notification.content.sound)
            case "Attachment":
                cellView = tableView.makeView(withIdentifier: .attachmentCell, owner: nil) as? NSTableCellView
                cellView?.setAttachment(attachment: notification.content.attachments.first)
        case "Category":
            cellView = tableView.makeView(withIdentifier: .attachmentCell, owner: nil) as? NSTableCellView
            cellView?.setCategory(category: notification.content.categoryIdentifier)
            case .none:
                break
            case .some(_):
                break
        }
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        enableRemoveButtonIfRowIsSelected()
    }
    
}
