//
//  config.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 10/1/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

/**
 ENVIRONMENT (have to use integers for preprocessor to compare)
 */
#define DEVELOPMENT 0
#define PRODUCTION 1

#define ENVIRONMENT PRODUCTION

/**
 WEB SERVICES
 Also used by LoginSSOViewController to clear cookies
 */
#if ENVIRONMENT == PRODUCTION
	#define BASE_DOMAIN @"www.mytelemed.com"
#else
	#define BASE_DOMAIN @"test.mytelemed.com"
#endif

#define API_BASE_URL @"https://" BASE_DOMAIN @"/MyTmdWebApi/api/"
#define AUTHENTICATION_BASE_URL @"https://" BASE_DOMAIN @"/Auth/"
#define AUTHENTICATION_CALLBACK_PAGE @"Authentication/Success"

#define ACCESS_TOKEN_EXPIRATION_TIME 28.0
#define NSURLREQUEST_TIMEOUT_INTERVAL 12.0
#define NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL 60.0 // All requests that submit data to server need longer timeout


/**
 CONTACT TELEMED RECIPIENT
 */
#define CONTACT_RECIPIENTS @"Billing", @"Calendar", @"Technical Support", @"Customer Service", @"App Feedback", @"Miscellanous"


/**
 NOTIFICATIONS
 */
#define NOTIFICATION_TONES_SUBCATEGORIES @"Staff Favorites", @"MyTeleMed", @"iOS7", @"Classic"
#define NOTIFICATION_TONES_IOS7 @"Aurora", @"Bamboo", @"Chord", @"Circles", @"Complete", @"Hello", @"Input", @"Keys", @"Note", @"Popcorn", @"Pulse", @"Synth"
#define NOTIFICATION_TONES_CLASSIC_IOS @"Alarm", @"Anticipate", @"Bell", @"Bloom", @"Calypso", @"Chime", @"Choo Choo", @"Descent", @"Electronic", @"Fanfare", @"Glass", @"Horn", @"Ladder", @"Minuet", @"News Flash", @"Noir", @"Sherwood Forest", @"Spell", @"Suspense", @"Telegraph", @"Tiptoes", @"Tri-tone", @"Typewriters", @"Update"
#define NOTIFICATION_TONES_MYTELEMED @"Alert", @"Chirp", @"Low", @"Notice", @"Quantum", @"Sonar"
#define NOTIFICATION_TONES_STAFF_FAVORITES @"Ascending", @"Digital Alarm 1", @"Digital Alarm 2", @"Irritating", @"Nuclear", @"Sci-Fi", @"Sonic Reverb", @"Warning"

#define NOTIFICATION_INTERVALS @"1 minute", @"5 minutes", @"10 minutes", @"15 minutes", @"20 minutes"
