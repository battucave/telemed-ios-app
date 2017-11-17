//
//  ELCUIApplication.h
//
//  Created by Brandon Trebitowski on 9/19/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

// Default # of minutes before application times out (overwritten with value from User Info Model)
#define kDefaultTimeoutPeriodMins 10

// Notification that gets sent when the timeout occurs
#define kApplicationDidTimeoutNotification @"ApplicationDidTimeout"

/**
 * This is a subclass of UIApplication with the sendEvent: method 
 * overridden in order to catch all touch events.
 */

@interface ELCUIApplication : UIApplication {
	NSTimer *_idleTimer;
}

@property (nonatomic) int timeoutPeriodMins;

/**
 * Resets the idle timer to its initial state. This method gets called
 * every time there is a touch on the screen.  It should also be called
 * when the user correctly enters their pin to access the application.
 */
- (void)resetIdleTimer;

@end
