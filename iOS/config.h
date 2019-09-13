//
//  config.h
//  TeleMed
//
//  Created by SolutionBuilt on 10/1/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

/**
 * BASE_URL
 * Set in project's Build Settings' Preprocessor Macros
 */


/**
 * API URL'S
 */
#define API_BASE_URL BASE_URL @"/" API_PREFIX @"/api/"
#define AUTHENTICATION_BASE_URL BASE_URL @"/Auth/"
#define AUTHENTICATION_CALLBACK_PAGE @"Authentication/Success"


/**
 * TIMEOUT/EXPIRATION PERIODS
 */
#define ACCESS_TOKEN_EXPIRATION_TIME 28.0
#define DEFAULT_TIMEOUT_PERIOD_MINUTES 10
#define NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL 60.0 // All requests that submit data to server need longer timeout
#define NSURLREQUEST_TIMEOUT_INTERVAL 12.0


/**
 * NOTIFICATION CENTER
 */
#define NOTIFICATION_APPLICATION_DID_CONNECT_CALL @"ApplicationDidConnectCallNotification"
#define NOTIFICATION_APPLICATION_DID_DISCONNECT_CALL @"ApplicationDidDisconnectCallNotification"
#define NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS @"ApplicationDidFailToRegisterForRemoteNotificationsNotification"
#define NOTIFICATION_APPLICATION_DID_RECEIVE_REMOTE_NOTIFICATION @"ApplicationDidReceiveRemoteNotification"
#define NOTIFICATION_APPLICATION_DID_REGISTER_FOR_REMOTE_NOTIFICATIONS @"ApplicationDidRegisterForRemoteNotificationsNotification"
#define NOTIFICATION_APPLICATION_DID_TIMEOUT @"ApplicationDidTimeoutNotification"


/**
 * NOTIFICATION SETTINGS
 */
#define NOTIFICATION_TONES_SUBCATEGORIES @"Staff Favorites", @"MyTeleMed", @"Standard", @"Classic"
#define NOTIFICATION_TONES_CLASSIC_IOS @"Alarm", @"Anticipate", @"Bell", @"Bloom", @"Calypso", @"Chime", @"Choo Choo", @"Descent", @"Electronic", @"Fanfare", @"Glass", @"Horn", @"Ladder", @"Minuet", @"News Flash", @"Noir", @"Sherwood Forest", @"Spell", @"Suspense", @"Telegraph", @"Tiptoes", @"Tri-tone", @"Typewriters", @"Update"
#define NOTIFICATION_TONES_MYTELEMED @"Alert", @"Chirp", @"Low", @"Notice", @"Quantum", @"Sonar"
#define NOTIFICATION_TONES_STAFF_FAVORITES @"Ascending", @"Digital Alarm 1", @"Digital Alarm 2", @"Irritating", @"Nuclear", @"Sci-Fi", @"Sonic Reverb", @"Warning"
#define NOTIFICATION_TONES_STANDARD @"Aurora", @"Bamboo", @"Chord", @"Circles", @"Complete", @"Hello", @"Input", @"Keys", @"Note", @"Popcorn", @"Pulse", @"Synth"

#define NOTIFICATION_INTERVALS @"1 minute", @"5 minutes", @"10 minutes", @"15 minutes", @"20 minutes"


/**
 * SAVED SETTINGS
 */
#define CDMA_VOICE_DATA_DISABLED @"CDMAVoiceDataDisabled"
#define CDMA_VOICE_DATA_HIDDEN @"CDMAVoiceDataHidden"
#define DATE_APPLICATION_DID_ENTER_BACKGROUND @"dateApplicationDidEnterBackground"
#define DISABLE_TIMEOUT @"disableTimeout"
#define SHOW_SPRINT_VOICE_DATA_WARNING @"showSprintVoiceDataWarning"
#define SHOW_VERIZON_VOICE_DATA_WARNING @"showVerizonVoiceDataWarning"
#define SSO_PROVIDER @"SSOProvider"
#define SSO_PROVIDER_EMAIL_ADDRESS @"SSOProviderEmailAddress"
#define SWIPE_MESSAGE_DISABLED @"swipeMessageDisabled"
#define UDDI_DEVICE @"UDDIDevice"
#define USER_PROFILE_PHONE_NUMBER @"UserProfilePhoneNumber"
