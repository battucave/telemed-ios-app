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
@property (nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) IBOutlet UILabel *labelLoading;

@property (nonatomic) NSTimer *timerPDFBackgroundFix;

@end

@implementation HelpUserGuideViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSURL *userGuideUrl = [NSURL URLWithString:@"https://www.mytelemed.com/mytmd2009/mobilehelp/PDF/iPhone.pdf"];
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
			[view setBackgroundColor:[UIColor whiteColor]];
			
			[self.webViewPDFViewer setHidden:NO];
			
			[self.timerPDFBackgroundFix invalidate];
			self.timerPDFBackgroundFix = nil;
		}
	}
}

// Override CoreViewController's logic to prevent showing CDMA Voice Data screen
- (void)showCDMAVoiceDataViewController:(NSNotification *)notification
{
	// Don't show CDMA Voice Data screen
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
