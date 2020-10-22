//
//  LoginViewController+MyTeleMed.swift
//  MyTeleMed
//
//  Created by Shane Goodwin on 10/21/20.
//  Copyright © 2020 SolutionBuilt. All rights reserved.
//

import Foundation

extension LoginViewController {

    // Obtain user data from server and initialize app
    func finalizeAuthentication() {
        print("Finalize MyTeleMed Authentication")
        
        let myProfileModel = MyProfileModel.sharedInstance()!
        
        myProfileModel.getWithCallback { (success: Bool, profile: ProfileProtocol?, error: Error?) in
            // Set is loading to false
            self.isLoading = false
            
            if success {
                let registeredDeviceModel = RegisteredDeviceModel.sharedInstance()!
                
                print("User ID: \(String(describing: myProfileModel.id))")
                print("Preferred Account ID: \(String(describing: (myProfileModel.myPreferredAccount as? AccountModel)?.id))")
                print("Device ID: \(String(describing: registeredDeviceModel.id))")
                print("Phone Number: \(String(describing: registeredDeviceModel.phoneNumber))")
                
                // Check if user has previously registered this device with TeleMed
                if registeredDeviceModel.isRegistered() {
                    // Phone Number was previously registered with TeleMed, but we should update the device token in case it changed
                    registeredDeviceModel.registerDevice { (success: Bool, registeredDeviceError: Error?) in
                        // If there is an error other than the device offline error, show an error and require user to enter their phone number again
                        if let registeredDeviceError = registeredDeviceError as NSError?,
                            registeredDeviceError.code != NSURLErrorNotConnectedToInternet,
                            registeredDeviceError.code != NSURLErrorTimedOut {
                            
                            // Show the error even if success returned true so that TeleMed can track issue down
                            let alert = UIAlertController(title: "Registration Error", message: "There was a problem registering your device on our network:\n\(registeredDeviceError.localizedDescription)", preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
                
                // Go to the next screen in the login process
                (UIApplication.shared.delegate as! AppDelegate).goToNextScreen()
                
                return
            }
            
            // Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
            let errorDescription = (error != nil ? ":<br>\(error!.localizedDescription)" : ".")
            
            self.showWebViewError(errorMessage: "There was a problem registering your device on our network\(errorDescription)")
        }
    }
}
