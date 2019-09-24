//
//  Model.m
//  TeleMed
//
//  Created by SolutionBuilt on 11/13/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "TeleMedHTTPRequestOperationManager.h"
#import "ErrorAlertController.h"
#import "GenericErrorXMLParser.h"

@interface Model()

@property (nonatomic) BOOL hasDismissed;

@end

@implementation Model

- (id)init
{
	if (self = [super init])
	{
		// Initialize operation manager
		self.operationManager = [TeleMedHTTPRequestOperationManager sharedInstance];
	}
	
	return self;
}

- (void)showActivityIndicator
{
	[self showActivityIndicator:@"Sending..."];
}

- (void)showActivityIndicator:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// Initialize activity indicator
		UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		UILabel *labelMessage = [[UILabel alloc] init];
		UIAlertController *loadingAlertController = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
		NSDictionary *views = NSDictionaryOfVariableBindings(loadingAlertController.view, activityIndicatorView, labelMessage);
		
		// Configure activity indicator
		[activityIndicatorView setColor:[UIColor blackColor]];
		[activityIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
		[activityIndicatorView setUserInteractionEnabled:NO];
		[activityIndicatorView startAnimating];
		
		// Configure message
		[labelMessage setTranslatesAutoresizingMaskIntoConstraints:NO];
		[labelMessage setText:message];
		
		// Add activity indicator and message to alert controller
		[loadingAlertController.view addSubview:activityIndicatorView];
		[loadingAlertController.view addSubview:labelMessage];
		
		// Add constraints
		NSArray *constraintsVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[activityIndicatorView]-10-[labelMessage]-15-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views];
		NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activityIndicatorView]|" options:0 metrics:nil views:views];
		
		[loadingAlertController.view addConstraints:[constraintsVertical arrayByAddingObjectsFromArray:constraintsHorizontal]];
		
		// Show activity indicator
		[[self getRootViewController] presentViewController:loadingAlertController animated:NO completion:nil];
		
		// Reset the hasDismissed flag
		[self setHasDismissed:NO];
	});
}

- (void)hideActivityIndicator:(void (^)(void))callback
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// If activity indicator has already been dismissed, then manually run any callbacks
		if (self.hasDismissed)
		{
			if (callback != nil)
			{
				// Delay callback to ensure that activity indicator has finished dismissing
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
				{
					callback();
				});
			}
		}
		else
		{
			[[self getRootViewController] dismissViewControllerAnimated:NO completion:callback];
			
			// Update the hasDismissed flag so that future callbacks can still be handled (dismissViewControllerAnimated's completion block only runs if a view actually dismisses)
			[self setHasDismissed:YES];
		}
	});
}

- (NSError *)buildError:(NSError *)error usingData:(NSData *)data withGenericMessage:(NSString *)message andTitle:(NSString *)title
{
	NSString *errorString;
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	GenericErrorXMLParser *parser = [[GenericErrorXMLParser alloc] init];
	
	[xmlParser setDelegate:parser];
	
	// Parse the xml file to obtain error message
	if ([xmlParser parse] && ! [parser.error isEqualToString:@"An error has occurred."])
	{
		errorString = parser.error;
	}
	// Error parsing xml file or generic response returned
	else
	{
		errorString = message;
	}
	
	NSLog(@"Build Error: %@", errorString);
	
	return [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:error.code userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:title, NSLocalizedFailureReasonErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
}

- (void)showError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

- (void)showError:(NSError *)error withRetryCallback:(void (^)(void))callback
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error withRetryCallback:callback];
}

- (void)showError:(NSError *)error withRetryCallback:(void (^)(void))retryCallback cancelCallback:(void (^)(void))cancelCallback
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error withRetryCallback:retryCallback cancelCallback:cancelCallback];
}

- (id)getRootViewController
{
	// In TeleMed apps, root view controller will almost always be of type SWRevealViewController
	id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
	
	if ([rootViewController isKindOfClass:UINavigationController.class])
	{
		rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
	
	} else if ([rootViewController isKindOfClass:UITabBarController.class])
	{
		rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
	}
	
	return rootViewController;
}

- (void)dealloc
{
	// Remove all observers if applicable (models with POST or DELETE requests have network activity observers)
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end