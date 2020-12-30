//
//  RestrictedTextView.swift
//  TeleMed
//
//  Created by Shane Goodwin on 12/30/20.
//  Copyright © 2020 SolutionBuilt. All rights reserved.
//
//  Used by MessageDetailViewController for the message field
//

import Foundation

class RestrictedTextView: UITextView {
	
	open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		/* if action == #selector(UIResponderStandardEditActions.cut(_:)) ||
			action == #selector(UIResponderStandardEditActions.copy(_:)) {
			return false
		} */
		
		return false
	}
}
