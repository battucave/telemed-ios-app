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
	@IBAction func showAlertPressed() {
        let cancel = WKAlertAction(title: "Cancel", style:WKAlertActionStyle.cancel, handler: { () -> Void in })
        let action = WKAlertAction(title: "Action", style:WKAlertActionStyle.default, handler: { () -> Void in })
        
        self.presentAlert(withTitle: "Alert", message: "Please check your phone for notification", preferredStyle: WKAlertControllerStyle.sideBySideButtonsAlert, actions: [cancel, action])
	}
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		// Configure interface objects here.
	}
	
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
	}
	
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
}
