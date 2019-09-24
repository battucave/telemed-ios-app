//
//  CallModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "CallModel.h"
#import "AppDelegate.h"
#import "ErrorAlertController.h"
#import "RegisteredDeviceModel.h"

@interface CallModel ()

@property (nonatomic) BOOL pendingComplete;

@end

@implementation CallModel

- (void)callTeleMed
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	// Reset observer for TeleMed to return phone call
	[appDelegate stopTeleMedCallObserver];
	
	// Return error if no phone number is set (this should only be applicable to debug builds if they bypass phone number registration)
	if (! registeredDeviceModel.PhoneNumber)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Call TeleMed Error", NSLocalizedFailureReasonErrorKey, @"There was a problem requesting a Return Call.", NSLocalizedDescriptionKey, nil]];
	
		// Show error
		[self showError:error];
	
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
		{
			[self.delegate callError:error];
		}
		
		return;
	}
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSDictionary *parameters = @{
		@"recordCall"	: @"false",
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if (self.delegate && [self.delegate respondsToSelector:@selector(callSuccess)])
			{
				[self.delegate callSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Call TeleMed Error", NSLocalizedFailureReasonErrorKey, @"There was a problem requesting a Return Call.", NSLocalizedDescriptionKey, nil]];
			
			// Stop observing for TeleMed to return phone call
			[appDelegate stopTeleMedCallObserver];
			
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self callTeleMed];
			}
			cancelCallback:^
			{
				// Handle error via delegate
				if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
				{
					[self.delegate callError:error];
				}
			}];
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Stop observing for TeleMed to return phone call
		[appDelegate stopTeleMedCallObserver];
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem requesting a Return Call." andTitle:@"Call TeleMed Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withRetryCallback:^
		{
			// Include callback to retry the request
			[self callTeleMed];
		}
		cancelCallback:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
			{
				[self.delegate callError:error];
			}
		}];
	}];
}

- (void)callSenderForMessage:(NSNumber *)messageID recordCall:(NSString *)recordCall
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	// Stop observing for TeleMed to return phone call (reset the listener)
	[appDelegate stopTeleMedCallObserver];
	
	// Return error if no phone number is set (this should only be applicable to debug builds if they bypass phone number registration)
	if (! registeredDeviceModel.PhoneNumber)
	{
		NSLog(@"Skip Call Sender when on Simulator or Debugging because Phone Number is not available.");
		
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Return Call Error", NSLocalizedFailureReasonErrorKey, @"A valid Phone Number is not available on this device.", NSLocalizedDescriptionKey, nil]];
		
		// Show error
		[self showError:error];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
		{
			[self.delegate callError:error];
		}
		
		return;
	}
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSDictionary *parameters = @{
		@"mdid"			: messageID,
		@"recordCall"	: recordCall,
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if (self.delegate && [self.delegate respondsToSelector:@selector(callSuccess)])
			{
				[self.delegate callSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Return Call Error", NSLocalizedFailureReasonErrorKey, @"There was a problem requesting a Return Call.", NSLocalizedDescriptionKey, nil]];
			
			// Stop observing for TeleMed to return phone call
			[appDelegate stopTeleMedCallObserver];
			
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self callSenderForMessage:messageID recordCall:recordCall];
			}
			cancelCallback:^
			{
				// Handle error via delegate
				if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
				{
					[self.delegate callError:error];
				}
			}];
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Stop observing for TeleMed to return phone call
		[appDelegate stopTeleMedCallObserver];
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem requesting a Return Call." andTitle:@"Return Call Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withRetryCallback:^
		{
			// Include callback to retry the request
			[self callSenderForMessage:messageID recordCall:recordCall];
		}
		cancelCallback:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
			{
				[self.delegate callError:error];
			}
		}];
	}];
}

// Network request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove network activity observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	if (! self.pendingComplete)
	{
		// Notify delegate that TeleMed call request has been sent to server
		if (self.delegate && [self.delegate respondsToSelector:@selector(callPending)])
		{
			[self.delegate callPending];
		}
		
		// Start observing for TeleMed to return phone call
		[self startTeleMedCallObserver];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

// Start observing for TeleMed to return phone call
- (void)startTeleMedCallObserver
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

	// Set telemed call timeout block on AppDelegate
	[appDelegate startTeleMedCallObserver:dispatch_block_create(0, ^
	{
		ErrorAlertController *returnCallTimeoutAlertController = [ErrorAlertController alertControllerWithTitle:@"Return Call Timed Out" message:@"There may have been a problem calling you. Please verify that our phone number isn't being blocked on your device:\n\n1) Open the Settings App\n2) Tap Phone\n3) Tap Call Blocking & Identification\n4) Search for and unblock +1 (404) 736-1880 if present" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(callError:)])
			{
				[self.delegate callError:nil];
			}
		}];

		[returnCallTimeoutAlertController addAction:okAction];

		// PreferredAction only supported in 9.0+
		if ([returnCallTimeoutAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[returnCallTimeoutAlertController setPreferredAction:okAction];
		}

		// Show alert
		[returnCallTimeoutAlertController presentAlertController:YES completion:nil];
	}) timeoutPeriod:NSURLREQUEST_EXTENDED_TIMEOUT_INTERVAL];
}

@end
