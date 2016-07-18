//
//  InterfaceController.swift
//  MyTeleMedWatch Extension
//
//  Created by Nicholas Bosak on 1/15/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController
{
	@IBAction func
		showAlertPressed()
		{
			let cancel = WKAlertAction(title: "Cancel", style:WKAlertActionStyle.Cancel, handler: { () -> Void in })
			let action = WKAlertAction(title: "Action", style:WKAlertActionStyle.Default, handler: { () -> Void in })
			
			self.presentAlertControllerWithTitle("Alert", message: "Please check your phone for notification", preferredStyle: WKAlertControllerStyle.SideBySideButtonsAlert, actions: [cancel, action])
	}
	
	override func awakeWithContext(context: AnyObject?)
	{
		super.awakeWithContext(context)
		
		// Configure interface objects here.
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
}
