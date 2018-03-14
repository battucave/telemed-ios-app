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
#define DEFAULT_APP_TIMEOUT_PERIOD_MINS 10
#define ACCESS_TOKEN_EXPIRATION_TIME 28.0
#define NSURLREQUEST_TIMEOUT_INTERVAL 12.0
#define NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL 60.0 // All requests that submit data to server need longer timeout


/**
 * NOTIFICATIONS
 */
#define NOTIFICATION_TONES_SUBCATEGORIES @"Staff Favorites", @"MyTeleMed", @"iOS7", @"Classic"
#define NOTIFICATION_TONES_IOS7 @"Aurora", @"Bamboo", @"Chord", @"Circles", @"Complete", @"Hello", @"Input", @"Keys", @"Note", @"Popcorn", @"Pulse", @"Synth"
#define NOTIFICATION_TONES_CLASSIC_IOS @"Alarm", @"Anticipate", @"Bell", @"Bloom", @"Calypso", @"Chime", @"Choo Choo", @"Descent", @"Electronic", @"Fanfare", @"Glass", @"Horn", @"Ladder", @"Minuet", @"News Flash", @"Noir", @"Sherwood Forest", @"Spell", @"Suspense", @"Telegraph", @"Tiptoes", @"Tri-tone", @"Typewriters", @"Update"
#define NOTIFICATION_TONES_MYTELEMED @"Alert", @"Chirp", @"Low", @"Notice", @"Quantum", @"Sonar"
#define NOTIFICATION_TONES_STAFF_FAVORITES @"Ascending", @"Digital Alarm 1", @"Digital Alarm 2", @"Irritating", @"Nuclear", @"Sci-Fi", @"Sonic Reverb", @"Warning"

#define NOTIFICATION_INTERVALS @"1 minute", @"5 minutes", @"10 minutes", @"15 minutes", @"20 minutes"
