//
//  NotificationController.swift
//  MyTeleMedWatch Extension
//
//  Created by Nicholas Bosak on 1/15/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

import WatchKit
import Foundation


class NotificationController: WKUserNotificationInterfaceController {
	
	@IBOutlet weak var notificationAlertLabel: WKInterfaceLabel!
	@IBOutlet weak var notificationImage: WKInterfaceImage!
	
	override init()
	{
		// Initialize variables here.
		super.init()
	}
	
	override func willActivate()
	{
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
	}
	
	override func didDeactivate()
	{
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
	
	override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void))
	{
		// Local are notifications that are scheduled by the application itself, and don't involve any comm with Push
		if localNotification.alertTitle == "Urgent"
		{
			notificationAlertLabel.setText("Urgent")
			notificationImage.setImageNamed("event1_image")
		}
		
		if localNotification.alertTitle == "Stat"
		{
			notificationAlertLabel.setText("Stat")
			notificationImage.setImageNamed("event2_image")
		}
		
		completionHandler(.Custom)
	}
	
	
	
	override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void))
	{
		
		// Remote handle Push from Apple
		completionHandler(.Custom)
	}
	
}