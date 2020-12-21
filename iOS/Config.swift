//
//  Config.swift
//  TeleMed
//
//  Created by Shane Goodwin on 10/21/20.
//  Copyright © 2020 SolutionBuilt. All rights reserved.
//

import Foundation

public enum Config {
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        
        return dict
    }()
    
    // API Settings
    static let apiBaseUrl: String = {
        guard let value = infoDictionary["API_BASE_URL"] as? String else {
            fatalError("API_BASE_URL is not set")
        }
        
        return value
    }()
    
    static let authenticationAudience: String = {
        guard let value = infoDictionary["AUTHENTICATION_AUDIENCE"] as? String else {
            fatalError("AUTHENTICATION_AUDIENCE is not set")
        }
        
        return value
    }()
    
    static let authenticationBaseUrl: String = {
        guard let value = infoDictionary["AUTHENTICATION_BASE_URL"] as? String else {
            fatalError("AUTHENTICATION_BASE_URL is not set")
        }
        
        return value
    }()
    
    static let authenticationCallbackPage: String = {
        guard let value = infoDictionary["AUTHENTICATION_CALLBACK_PAGE"] as? String else {
            fatalError("AUTHENTICATION_CALLBACK_PAGE is not set")
        }
        
        return value
    }()
    
    static let xmlns: String = {
        guard let value = infoDictionary["XMLNS"] as? String else {
            fatalError("XMLNS is not set")
        }
        
        return value
    }()
    
    // Timeout/Expiration
    static let accessTokenExpirationTime: Double = {
        guard let value = infoDictionary["ACCESS_TOKEN_EXPIRATION_TIME"] as? String,
            let doubleValue = Double(value) else {
            fatalError("ACCESS_TOKEN_EXPIRATION_TIME is not set or invalid")
        }
        
        return doubleValue
    }()
    
    static let defaultTimeoutPeriod: Int = {
        guard let value = infoDictionary["DEFAULT_TIMEOUT_PERIOD"] as? String,
            let intValue = Int(value) else {
            fatalError("DEFAULT_TIMEOUT_PERIOD is not set or invalid")
        }
        
        return intValue
    }()
    
    static let urlRequestExtendedTimeoutPeriod: Double = {
        guard let value = infoDictionary["URLREQUEST_EXTENDED_TIMEOUT_PERIOD"] as? String,
            let doubleValue = Double(value) else {
            fatalError("URLREQUEST_EXTENDED_TIMEOUT_PERIOD is not set or invalid")
        }
        
        return doubleValue
    }()
    
    static let urlRequestTimeoutPeriod: Double = {
        guard let value = infoDictionary["URLREQUEST_TIMEOUT_PERIOD"] as? String,
            let doubleValue = Double(value) else {
            fatalError("URLREQUEST_TIMEOUT_PERIOD is not set or invalid")
        }
        
        return doubleValue
    }()
    
    // Saved Settings
    static let reasonApplicationDidLogout: String = {
        guard let value = infoDictionary["REASON_APPLICATION_DID_LOGOUT"] as? String else {
            fatalError("REASON_APPLICATION_DID_LOGOUT is not set")
        }
        
        return value
    }()
}
