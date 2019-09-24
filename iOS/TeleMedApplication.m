//
//  TeleMedApplication.m
//
//  Created by Brandon Trebitowski on 9/19/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "TeleMedApplication.h"

@implementation TeleMedApplication

- (void)sendEvent:(UIEvent *)event
{
	[super sendEvent:event];
	
	// Fire up the timer upon first event
	if (! _idleTimer)
	{
		[self resetIdleTimer];
	}
	
	// Check to see if there was a touch event
	NSSet *allTouches = [event allTouches];
	
    if ([allTouches count] > 0)
	{
		UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
		
		if (phase == UITouchPhaseBegan)
		{
			[self resetIdleTimer];
		}
	}
}

// Override timeoutPeriodMins setter to automatically reset timer with new period
- (void)setTimeoutPeriodMins:(NSInteger)timeoutPeriodMins
{
	_timeoutPeriodMins = timeoutPeriodMins;
	
	[self resetIdleTimer];
}

- (void)resetIdleTimer
{
    if (_idleTimer)
	{
		[_idleTimer invalidate];
	}
	
	// Default timeout period to 10 minutes
	if (self.timeoutPeriodMins < 1)
	{
		_timeoutPeriodMins = DEFAULT_TIMEOUT_PERIOD_MINUTES;
	}
	
	// On app launch and/or login, the timeout period will be overwritten with the timeout period set in MyProfileModel/UserProfileModel
	
	_idleTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutPeriodMins * 60 target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}

- (void)idleTimerExceeded
{
	// Post a notification so anyone who subscribes to it can be notified when the application times out
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_APPLICATION_DID_TIMEOUT object:nil];
}

@end
