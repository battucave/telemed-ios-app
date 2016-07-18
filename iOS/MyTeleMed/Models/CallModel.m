//
//  CallModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "CallModel.h"
#import "RegisteredDeviceModel.h"

@implementation CallModel

- (void)callTeleMed
{
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	NSDictionary *parameters = @{
		@"recordCall"	: @"false",
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	NSLog(@"CallTeleMed");
	NSLog(@"%@", parameters);
	
	// The web service only returns a result after the phone call has been answered so increase timeout interval
	[self.operationManager.requestSerializer setTimeoutInterval:90.0];
	
	// This Rest Service Method only returns after the phone call has been answered
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"CallModel Success: %@", operation.response);
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(callTeleMedSuccess)])
			{
				[self.delegate callTeleMedSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem calling TeleMed.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(callTeleMedError:)])
			{
				[self.delegate callTeleMedError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem calling TeleMed."];
		
		if([self.delegate respondsToSelector:@selector(callTeleMedError:)])
		{
			[self.delegate callTeleMedError:error];
		}
	}];
	
	// Reset timeout interval to default
	[self.operationManager.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
}

- (void)callSenderForMessage:(NSNumber *)messageID recordCall:(NSString *)recordCall
{
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
		
	NSDictionary *parameters = @{
		@"mdid"			: messageID,
		@"recordCall"	: recordCall,
		@"userNumber"	: registeredDeviceModel.PhoneNumber
	};
	
	NSLog(@"CallSenderForMessage");
	NSLog(@"%@", parameters);
	
	// The web service only returns a result after the phone call has been answered so increase timeout interval
	[self.operationManager.requestSerializer setTimeoutInterval:90.0];
	
	// This Rest Service Method only returns after the phone call has been answered
	[self.operationManager POST:@"Calls" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"CallModel Success: %@", operation.response);
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(callSenderSuccess)])
			{
				[self.delegate callSenderSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem calling the Message Sender.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(callSenderError:)])
			{
				[self.delegate callSenderError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"CallModel Error: %@", error);
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem calling the Message Sender."];
		
		if([self.delegate respondsToSelector:@selector(callSenderError:)])
		{
			[self.delegate callSenderError:error];
		}
	}];
	
	// Reset timeout interval to default
	[self.operationManager.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_INTERVAL];
}

@end
