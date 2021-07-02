//
//  PreferredAccountModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/27/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "PreferredAccountModel.h"
#import "AccountModel.h"
#import "MyProfileModel.h"

@implementation PreferredAccountModel

- (void)savePreferredAccount:(AccountModel *)account
{
	// Initialize MyProfileModel
	MyProfileModel *myProfileModel = MyProfileModel.sharedInstance;
	
	// Save preferred account to MyProfileModel (assume success so save it immediately and then roll back if error occurs)
	[myProfileModel setMyPreferredAccount:account];
	
	NSDictionary *parameters = @{
		@"accountID"	: account.ID,
	};
	
	// Notify delegate that message has been sent to server
	if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountPending)])
	{
		[self.delegate savePreferredAccountPending];
	}
	// Show activity indicator
    else
    {
        [self showActivityIndicator];
	}
    
	[self.operationManager POST:@"PreferredAcct" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
            // Successful post returns a 204 code with no response
            if (operation.response.statusCode == 204)
            {
                // Handle success via delegate (not currently used)
                if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountSuccess)])
                {
                    [self.delegate savePreferredAccountSuccess];
                }
            }
            else
            {
                // Roll back MyProfileModel's my preferred account to previous value
                [myProfileModel restoreMyPreferredAccount];
                
                NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Preferred Account Error", NSLocalizedFailureReasonErrorKey, @"There was a problem changing your Preferred Account.", NSLocalizedDescriptionKey, nil]];
                
                // Handle error via delegate
                if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountError:)])
                {
                    [self.delegate savePreferredAccountError:error];
                }
                
                // Show error even if user has navigated to another screen
                [self showError:error withRetryCallback:^
                {
                    // Include callback to retry the request
                    [self savePreferredAccount:account];
                }];
            }
        }];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"PasswordChangeModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem changing your Preferred Account." andTitle:@"Preferred Account Error"];
		
		// Close activity indicator with callback
		[self hideActivityIndicator:^
		{
			// Roll back MyProfileModel's MyPreferredAccount to previous value
			[myProfileModel restoreMyPreferredAccount];
			
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(savePreferredAccountError:)])
			{
				[self.delegate savePreferredAccountError:error];
			}
		
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self savePreferredAccount:account];
			}];
		}];
	}];
}

@end
