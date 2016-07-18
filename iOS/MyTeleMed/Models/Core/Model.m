//
//  Model.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/13/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "AppDelegate.h"
#import "TeleMedHTTPRequestOperationManager.h"
#import "CustomAlertView.h"
#import "GenericErrorXMLParser.h"

@interface Model ()

@property (nonatomic) CustomAlertView *activityIndicatorView;

@end

@implementation Model

- (id)init
{
	if(self = [super init])
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
		if(self.activityIndicatorView == nil)
		{
			[self setActivityIndicatorView:[[CustomAlertView alloc] init]];
			[self.activityIndicatorView showWithDialog:message];
		}
	});
}

- (void)hideActivityIndicator
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		if(self.activityIndicatorView != nil)
		{
			[self.activityIndicatorView close];
			
			self.activityIndicatorView = nil;
		}
	});
}

- (NSError *)buildError:(NSError *)error usingData:(NSData *)data withGenericMessage:(NSString *)message
{
	NSString *errorString;
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	GenericErrorXMLParser *parser = [[GenericErrorXMLParser alloc] init];
	
	[xmlParser setDelegate:parser];
	
	// Parse the XML file to obtain Error Message
	if([xmlParser parse] && ! [parser.error isEqualToString:@"An error has occurred."])
	{
		errorString = parser.error;
	}
	// If error is offline, then set offline message (this is not necessary because it will be reset anyway in showOfflineError, but is here anyway for completeness)
	else if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		errorString = @"You must connect to a Wi-Fi or cellular data network to continue.";
	}
	// Error parsing XML file or generic response returned
	else
	{
		errorString = message;
	}
	
	NSLog(@"Error: %@", errorString);
	
	return [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:error.code userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil]];
}

- (void)showOfflineError
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[appDelegate showOfflineError];
}

@end
