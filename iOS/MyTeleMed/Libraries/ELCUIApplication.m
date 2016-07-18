//
//  ELCUIApplication.m
//
//  Created by Brandon Trebitowski on 9/19/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCUIApplication.h"

@implementation ELCUIApplication



- (void)sendEvent:(UIEvent *)event
{
	[super sendEvent:event];
	
	// Fire up the timer upon first event
	if( ! _idleTimer)
	{
		[self resetIdleTimer];
	}
	
	// Check to see if there was a touch event
	NSSet *allTouches = [event allTouches];
	
    if([allTouches count] > 0)
	{
		UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
		
		if(phase == UITouchPhaseBegan)
		{
			[self resetIdleTimer];
		}
	}
}

// Override timeoutPeriodMins setter to automatically reset timer with new period
- (void)setTimeoutPeriodMins:(int)timeoutPeriodMins
{
	_timeoutPeriodMins = timeoutPeriodMins;
	
	[self resetIdleTimer];
}

- (void)resetIdleTimer
{
    if(_idleTimer)
	{
		[_idleTimer invalidate];
	}
	
	// Default Timeout period to 10 minutes
	if(self.timeoutPeriodMins < 1)
	{
		_timeoutPeriodMins = kDefaultTimeoutPeriodMins;
	}
	
	// On app launch and/or login, the Timeout Period will be overwritten with the Timeout Period set in User Info Model
	
	_idleTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutPeriodMins * 60 target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}

- (void)idleTimerExceeded
{
	// Post a notification so anyone who subscribes to it can be notified when the application times out
	[[NSNotificationCenter defaultCenter] postNotificationName:kApplicationDidTimeoutNotification object:nil];
}

@end
