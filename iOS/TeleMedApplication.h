//
//  TeleMedApplication.h
//
//  Created by Brandon Trebitowski on 9/19/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This is a subclass of UIApplication with sendEvent: overridden in order to catch all touch events.
 */

@interface TeleMedApplication : UIApplication {
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
