//
//  LoginViewController+Med2Med.swift
//  Med2Med
//
//  Created by Shane Goodwin on 10/22/20.
//  Copyright © 2020 SolutionBuilt. All rights reserved.
//

import Foundation

extension LoginViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TEMPORARY (remove code and enable button in storyboard in phase 2)
        self.buttonCreateAccount.title = ""
    }
    
    // Unwind segue from AccountRequestTableViewController
    @IBAction func unwindFromAccountRequest(segue: UIStoryboardSegue) {
        print("unwindFromAccountRequest")
    }
    
    // Obtain user data from server and initialize app
    func finalizeAuthentication() {
        print("Finalize Med2Med Authentication")
        
        let accountModel = AccountModel()
        let profile = UserProfileModel.sharedInstance()!
        
        // Set is loading to false
        self.isLoading = false
        
        profile.getWithCallback { (success: Bool, profile: ProfileProtocol?, profileError: Error?) in
            var error = profileError
            
            // Set is loading to false
            self.isLoading = false
            
            if success {
                accountModel.getAccountsWithCallback { (success: Bool, accounts: [Any]?, accountError: Error?) in
                    if success {
                        if let accounts = accounts as? [AccountModel] {
                            for account in accounts {
                                if account.isAuthorized() {
                                    profile?.isAuthorized = true
                                }
                                
                                print("Account Name: \(String(describing: account.name)); Status: \(String(describing: account.myAuthorizationStatus))")
                            }
                        }
                        
                        // Go to the next screen in the login process
                        (UIApplication.shared.delegate as! AppDelegate).goToNextScreen()
                        
                        return
                        
                    } else {
                        // Store the account error
                        error = accountError
                    }
                }
            }
            
            // Even if device offline, show this error message so that user can re-attempt to login (login screen will show offline message)
            let errorDescription = (error != nil ? ":<br>\(error!.localizedDescription)" : ".")
            
            self.showWebViewError(errorMessage: "There was a problem registering your device on our network\(errorDescription)")
        }
    }
    
    /*/ TEMPORARY (uncomment in phase 2)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAccountNew" {
            if let accountNewViewController = segue.destination as? AccountNewViewController {
                accountNewViewController.delegate = self
            }
        }
    } */
}
