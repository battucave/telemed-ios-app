//
//  PasswordChangeModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/27/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "PasswordChangeModel.h"

@interface PasswordChangeModel ()

@property (nonatomic) BOOL pendingComplete;

@end

@implementation PasswordChangeModel

- (void)changePassword:(NSString *)newPassword withOldPassword:(NSString *)oldPassword
{
	// Simple validation to ensure that both passwords are set
	// Don't do any further password validations. The server should be the only source of truth for passwords
	if([newPassword length] < 1 || [oldPassword length] < 1)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Change Password Error", NSLocalizedFailureReasonErrorKey, @"Current password and new password values are required.", NSLocalizedDescriptionKey, nil]];
		
		// Show error
		[self showError:error];
		
		/*if([self.delegate respondsToSelector:@selector(changePasswordError:)])
		{
			[self.delegate changePasswordError:error];
		}*/
		
		return;
	}
	
	// Show Activity Indicator
	[self showActivityIndicator];
	
	// Add Network Activity Observer (not used because can't assume success - old password may be incorrect, new password may not meet requirements, etc)
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<PasswordChange xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<NewPassword>%@</NewPassword>"
			"<OldPassword>%@</OldPassword>"
		"</PasswordChange>",
		newPassword, oldPassword];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	[self.operationManager POST:@"PasswordChanges" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			if([self.delegate respondsToSelector:@selector(changePasswordSuccess)])
			{
				[self.delegate changePasswordSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Change Password Error", NSLocalizedFailureReasonErrorKey, @"There was a problem changing your Password. Please verify that your Current Password is correct and that your New Password meets requirements.", NSLocalizedDescriptionKey, nil]];
			
			// Show error
			[self showError:error];
			
			/*if([self.delegate respondsToSelector:@selector(changePasswordError:)])
			{
				[self.delegate changePasswordError:error];
			}*/
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"PasswordChangeModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// Remove Network Activity Observer (not used because can't assume success - old password may be incorrect, new password may not meet requirements, etc)
		//[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem changing your Password. Please verify that your Current Password is correct and that your New Password meets requirements." andTitle:@"Change Password Error"];
		
		// Show error
		[self showError:error];
		
		/*if([self.delegate respondsToSelector:@selector(changePasswordError:)])
		{
			[self.delegate changePasswordError:error];
		}*/
	}];
}

// Network Request has been sent, but still awaiting response (not used because can't assume success - old password may be incorrect, new password may not meet requirements, etc)
/*- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Close Activity Indicator
	[self hideActivityIndicator];
	
	// Remove Network Activity Observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Notify delegate that Message has been sent to server
	if( ! self.pendingComplete && [self.delegate respondsToSelector:@selector(changePasswordPending)])
	{
		[self.delegate changePasswordPending];
	}
	
	// Ensure that pending callback doesn't fire again after possible error
	self.pendingComplete = YES;
}*/

@end
