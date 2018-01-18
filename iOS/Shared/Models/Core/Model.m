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

@implementation Model

- (id)init
{
	if (self = [super init])
	{
		// Initialize Operation Manager
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
		[[self getRootViewController] presentViewController:loadingAlertController animated:YES completion:nil];
	});
}

- (void)hideActivityIndicator
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[[self getRootViewController] dismissViewControllerAnimated:YES completion:nil];
	});
}

- (NSError *)buildError:(NSError *)error usingData:(NSData *)data withGenericMessage:(NSString *)message andTitle:(NSString *)title
{
	NSString *errorString;
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	GenericErrorXMLParser *parser = [[GenericErrorXMLParser alloc] init];
	
	[xmlParser setDelegate:parser];
	
	// Parse the XML file to obtain Error Message
	if ([xmlParser parse] && ! [parser.error isEqualToString:@"An error has occurred."])
	{
		errorString = parser.error;
	}
	// Error parsing XML file or generic response returned
	else
	{
		errorString = message;
	}
	
	NSLog(@"Error: %@", errorString);
	
	return [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:error.code userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:title, NSLocalizedFailureReasonErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
}

- (void)showError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

- (void)showError:(NSError *)error withCallback:(void (^)(void))callback
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error withCallback:callback];
}

- (id)getRootViewController
{
	id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
	
	if([rootViewController isKindOfClass:[UINavigationController class]])
	{
		rootViewController = ((UINavigationController *) rootViewController).viewControllers.firstObject;
	
	} else if([rootViewController isKindOfClass:[UITabBarController class]])
	{
		rootViewController = ((UITabBarController *) rootViewController).selectedViewController;
	}
	
	return rootViewController;
}

- (void)dealloc
{
	// Remove all Observers if applicable (models with POST or DELETE requests have Network Activity Observers)
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
