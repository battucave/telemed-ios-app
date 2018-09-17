//
//  CallModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "CallModel.h"
#import "RegisteredDeviceModel.h"

@interface CallModel ()

@property (nonatomic) BOOL pendingComplete;

@end

@implementation CallModel

- (void)callTeleMed
{
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	// Return error if no phone number is set (this should only be applicable to debug builds since they bypass phone number registration)
	if (! registeredDeviceModel.PhoneNumber)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Call TeleMed Error", NSLocalizedFailureReasonErrorKey, @"There was a problem requesting a Return Call.", NSLocalizedDescriptionKey, nil]];
	
		// Show error
		[self showError:error];
	
		// Handle error via delegate
		/* if ([self.delegate respondsToSelector:@selector(callTeleMedError:)])
		{
			[self.delegate callTeleMedError:error];
		}*/
		
		return;
	}
	
	// Show activity indicator
	[self showActivityIndicator];
	
	NSDictionary *parameters = @{
		@"recordCall"	: @"false",
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	// This web service method only returns after the phone call has been answered so increase timeout interval
	[self.operationManager.requestSerializer setTimeoutInterval:120.0];
	
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"CallModel Success: %@", operation.response);
		
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if ([self.delegate respondsToSelector:@selector(callTeleMedSuccess)])
			{
				[self.delegate callTeleMedSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Call TeleMed Error", NSLocalizedFailureReasonErrorKey, @"There was a problem requesting a Return Call.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self callTeleMed];
			}];
			
			// Handle error via delegate
			/* if ([self.delegate respondsToSelector:@selector(callTeleMedError:)])
			{
				[self.delegate callTeleMedError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem requesting a Return Call." andTitle:@"Call TeleMed Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			/* if ([self.delegate respondsToSelector:@selector(callTeleMedError:)])
			{
				[self.delegate callTeleMedError:error];
			} */
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self callTeleMed];
			}];
		}];
	}];
	
	// Restore timeout interval to default
	[self.operationManager.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
}

- (void)callSenderForMessage:(NSNumber *)messageID recordCall:(NSString *)recordCall
{
	// Show activity indicator
	[self showActivityIndicator];
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
		
	NSDictionary *parameters = @{
		@"mdid"			: messageID,
		@"recordCall"	: recordCall,
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	NSLog(@"CallSenderForMessage");
	NSLog(@"%@", parameters);
	
	// The web service method only returns a result after the phone call has been answered so increase timeout interval
	[self.operationManager.requestSerializer setTimeoutInterval:120.0];
	
	// This web service method only returns after the phone call has been answered
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"CallModel Success: %@", operation.response);
		
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Handle success via delegate (not currently used)
			if ([self.delegate respondsToSelector:@selector(callSenderSuccess)])
			{
				[self.delegate callSenderSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Return Call Error", NSLocalizedFailureReasonErrorKey, @"There was a problem requesting a Return Call.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self callSenderForMessage:messageID recordCall:recordCall];
			}];
			
			// Handle error via delegate
			/* if ([self.delegate respondsToSelector:@selector(callSenderError:)])
			{
				[self.delegate callSenderError:error];
			} */
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem requesting a Return Call." andTitle:@"Return Call Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			/* if ([self.delegate respondsToSelector:@selector(callSenderError:)])
			{
				[self.delegate callSenderError:error];
			} */
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self callSenderForMessage:messageID recordCall:recordCall];
			}];
		}];
	}];
	
	// Reset timeout interval to default
	[self.operationManager.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
}

// Network request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove network activity observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Close activity indicator with callback
	[self hideActivityIndicator:^
	{
		if (! self.pendingComplete)
		{
			// Notify delegate that TeleMed call request has been sent to server
			if ([self.delegate respondsToSelector:@selector(callTeleMedPending)])
			{
				[self.delegate callTeleMedPending];
			}
			// Notify delegate that sender call request has been sent to server
			else if ([self.delegate respondsToSelector:@selector(callSenderPending)])
			{
				[self.delegate callSenderPending];
			}
		}
		
		// Ensure that pending callback doesn't fire again after possible error
		self.pendingComplete = YES;
	}];
}

@end
