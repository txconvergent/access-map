//
//  ViewController+RetractKeyboardOnTap.swift
//  Access
//
//  Created by Larry Win on 4/14/19.
//  Copyright © 2019 access-maps. All rights reserved.
//

import Foundation
import UIKit

// A small extension that dismisses the keyboard on tapping the map subview when using the search bar
extension ViewController {
	
	func addGestureToDismissKeyboardOnTap () {
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:)))
		mapView.addGestureRecognizer(tap)
	}
	
	@objc func dismissKeyboard (sender: UITapGestureRecognizer) {
		addressSearchBar.resignFirstResponder()
	}
}
