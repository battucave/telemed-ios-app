//
//  NotificationController.swift
//  MyTeleMedWatch Extension
//
//  Created by Nicholas Bosak on 1/15/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

import WatchKit
import Foundation
import UserNotifications


class NotificationController: WKUserNotificationInterfaceController {
	
	@IBOutlet weak var notificationAlertLabel: WKInterfaceLabel!
	@IBOutlet weak var notificationImage: WKInterfaceImage!
	
	override init() {
		// Initialize variables here.
		super.init()
	}
	
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
	}
	
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
	
	override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
		if #available(watchOS 4, *), !notification.request.content.attachments.isEmpty {
            // Not really #available, but limited to watchOS 4
            // Default interface gives us attachment support on watchOS 4
            completionHandler(.default)
        }
        
		/*/ Local are notifications that are scheduled by the application itself, and don't involve any comm with Push
		if notification.alertTitle == "Urgent"
		{
			notificationAlertLabel.setText("Urgent")
			notificationImage.setImageNamed("event1_image")
		}
		
		if notification.alertTitle == "Stat"
		{
			notificationAlertLabel.setText("Stat")
			notificationImage.setImageNamed("event2_image")
		} */
		
		completionHandler(.default)
	}
}
