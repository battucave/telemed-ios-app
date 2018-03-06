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
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	NSDictionary *parameters = @{
		@"recordCall"	: @"false",
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	// This Rest Service Method only returns after the phone call has been answered so increase timeout interval
	[self.operationManager.requestSerializer setTimeoutInterval:120.0];
	
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"CallModel Success: %@", operation.response);
		
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Not currently used
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
			
			/* if ([self.delegate respondsToSelector:@selector(callTeleMedError:)])
			{
				[self.delegate callTeleMedError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		/* if ([self.delegate respondsToSelector:@selector(callTeleMedError:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate callTeleMedError:error];
			}];
		}
		else
		{*/
			// Close Activity Indicator
			[self hideActivityIndicator];
		//}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem requesting a Return Call." andTitle:@"Call TeleMed Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self callTeleMed];
		}];
	}];
	
	// Restore timeout interval to default
	[self.operationManager.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
}

- (void)callSenderForMessage:(NSNumber *)messageID recordCall:(NSString *)recordCall
{
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
		
	NSDictionary *parameters = @{
		@"mdid"			: messageID,
		@"recordCall"	: recordCall,
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	NSLog(@"CallSenderForMessage");
	NSLog(@"%@", parameters);
	
	// The web service only returns a result after the phone call has been answered so increase timeout interval
	[self.operationManager.requestSerializer setTimeoutInterval:120.0];
	
	// This Rest Service Method only returns after the phone call has been answered
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"CallModel Success: %@", operation.response);
		
		// Activity Indicator already closed in AFNetworkingOperationDidStartNotification callback
		
		// Successful Post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Not currently used
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
			
			/* if ([self.delegate respondsToSelector:@selector(callSenderError:)])
			{
				[self.delegate callSenderError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// Remove Network Activity Observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		/* if ([self.delegate respondsToSelector:@selector(callSenderError:)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate callSenderError:error];
			}];
		}
		else
		{*/
			// Close Activity Indicator
			[self hideActivityIndicator];
		//}
	
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem requesting a Return Call." andTitle:@"Return Call Error"];
		
		// Show error even if user has navigated to another screen
		[self showError:error withCallback:^
		{
			// Include callback to retry the request
			[self callSenderForMessage:messageID recordCall:recordCall];
		}];
	}];
	
	// Reset timeout interval to default
	[self.operationManager.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
}

// Network Request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	if ( ! self.pendingComplete)
	{
		// Notify delegate that TeleMed Call Request has been sent to server
		if ([self.delegate respondsToSelector:@selector(callTeleMedPending)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate callTeleMedPending];
			}];
		}
		// Notify delegate that Sender Call Request has been sent to server
		else if ([self.delegate respondsToSelector:@selector(callSenderPending)])
		{
			// Close Activity Indicator with callback
			[self hideActivityIndicator:^
			{
				[self.delegate callSenderPending];
			}];
		}
		else
		{
			// Close Activity Indicator
			[self hideActivityIndicator];
		}
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}

@end
