//
//  HelpUserGuideViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 6/16/14.
//  Copyright (c) 2014 SolutionBuilt. All rights reserved.
//

#import "HelpUserGuideViewController.h"

@interface HelpUserGuideViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webViewPDFViewer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *labelLoading;

@property (nonatomic) NSTimer *timerPDFBackgroundFix;

@end

@implementation HelpUserGuideViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSURL *userGuideUrl = [NSURL URLWithString:@"https://www.mytelemed.com/mytmd2009/mobilehelp/PDF/iPhone.pdf"];
	
	// TODO: Update user guide url
	#if MED2MED
		NSLog(@"UPDATE USER GUIDE URL FOR MED2MED");
	#endif
	
	NSURLRequest *requestObject = [NSURLRequest requestWithURL:userGuideUrl];
	
	[self.webViewPDFViewer setDelegate:self];
	[self.webViewPDFViewer loadRequest:requestObject];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[self.activityIndicator startAnimating];
	[self.labelLoading setHidden:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[self.activityIndicator stopAnimating];
	[self.labelLoading setHidden:YES];
	
	self.timerPDFBackgroundFix = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fixPDFBackground) userInfo:nil repeats:YES];
}

- (void)fixPDFBackground
{
	UIView *view = self.webViewPDFViewer;
	
	while(view)
	{
		view = [view.subviews firstObject];
		
		if ([NSStringFromClass([view class]) isEqualToString:@"UIWebPDFView"])
		{
			// iOS 13+ - Support dark mode
			if (@available(iOS 13.0, *))
			{
				[view setBackgroundColor:[UIColor systemBackgroundColor]];
			}
			// iOS < 13 - Fallback to use System Background Color light appearance
			else
			{
				[view setBackgroundColor:[UIColor whiteColor]];
			}
			
			[self.webViewPDFViewer setHidden:NO];
			
			[self.timerPDFBackgroundFix invalidate];
			self.timerPDFBackgroundFix = nil;
		}
	}
}

// Override CoreViewController's logic to prevent showing CDMAVoiceDataViewController
- (void)showCDMAVoiceDataViewController:(NSNotification *)notification
{
	// Don't show CDMAVoiceDataViewController
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
