//
//  PasswordChangeModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 3/27/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "PasswordChangeModel.h"

@implementation PasswordChangeModel

- (void)changePassword:(NSString *)newPassword withOldPassword:(NSString *)oldPassword
{
	// Simple validation to ensure that both passwords are set. Don't do any further password validations as the server should be the sole source of truth for passwords
	if (newPassword.length < 1 || oldPassword.length < 1)
	{
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Change Password Error", NSLocalizedFailureReasonErrorKey, @"Current password and new password fields are required.", NSLocalizedDescriptionKey, nil]];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(changePasswordError:)])
		{
			[self.delegate changePasswordError:error];
		}
		
		// Show error
		[self showError:error];
		
		return;
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<PasswordChange xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<NewPassword>%@</NewPassword>"
			"<OldPassword>%@</OldPassword>"
		"</PasswordChange>",
		
		newPassword,
		oldPassword
	];
	
	NSLog(@"XML Body: %@", xmlBody);
	
	// Don't add pending callback because can't assume success - old password may be incorrect, new password may not meet requirements, etc
	
	// Show activity indicator
	[self showActivityIndicator];
	
	[self.operationManager POST:@"PasswordChanges" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Successful post returns a 204 code with no response
			if (operation.response.statusCode == 204)
			{
				// Handle success via delegate
				if (self.delegate && [self.delegate respondsToSelector:@selector(changePasswordSuccess)])
				{
					[self.delegate changePasswordSuccess];
				}
			}
			else
			{
				NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Change Password Error", NSLocalizedFailureReasonErrorKey, @"There was a problem changing your Password. Please verify that your Current Password is correct and that your New Password meets requirements.", NSLocalizedDescriptionKey, nil]];
				
				// Handle error via delegate
				if (self.delegate && [self.delegate respondsToSelector:@selector(changePasswordError:)])
				{
					[self.delegate changePasswordError:error];
				}
				
				// Show error
				[self showError:error];
			}
		}];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"PasswordChangeModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem changing your Password. Please verify that your Current Password is correct and that your New Password meets requirements." andTitle:@"Change Password Error"];
	
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(changePasswordError:)])
			{
				[self.delegate changePasswordError:error];
			}
		
			// Show error
			[self showError:error];
		}];
	}];
}

@end
