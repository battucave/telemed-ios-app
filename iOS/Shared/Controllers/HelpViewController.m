//
//  HelpViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 6/13/14.
//  Copyright (c) 2014 SolutionBuilt. All rights reserved.
//

#import "HelpViewController.h"
#import "AccountPickerViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface HelpViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonCallTeleMed;
@property (weak, nonatomic) IBOutlet UIButton *buttonDemoVideo;
@property (weak, nonatomic) IBOutlet UIButton *buttonUserGuide;
@property (weak, nonatomic) IBOutlet UILabel *labelIntro;
@property (weak, nonatomic) IBOutlet UILabel *labelVersion;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintCallTeleMedCenterX;

@end

@implementation HelpViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// If showing Back button, remove existing menu button so that Back Button will be added in its place (Back button only shown when navigating from LoginSSO.storyboard view controllers)
	if (self.showBackButton)
	{
		self.navigationItem.leftBarButtonItem = nil;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Show navigation bar (if navigating from LoginSSO.storyboard view controllers)
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	
	// Update label version with app version from bundle
	NSString *buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *versionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

	// Show only the version number for release version to eliminate confusion for TeleMed's support staff
	#if RELEASE
		[self.labelVersion setText:versionNumber];

	// Also show build number for debug and beta versions
	#else
		[self.labelVersion setText:[NSString stringWithFormat:@"%@ (%@)", versionNumber, buildNumber]];
	#endif
	
	// Med2Med
	#ifdef MED2MED
		// Update intro text with correct app name
		[self.labelIntro setText:[self.labelIntro.text stringByReplacingOccurrencesOfString:@"MyTeleMed" withString:@"Med2Med"]];
	
		// Replace demo video button with call telemed button
		[self.buttonCallTeleMed setHidden:NO];
		[self.buttonDemoVideo setHidden:YES];
	
		// TEMPORARY (remove when user guide is created for Med2Med)
		[self.buttonUserGuide setHidden:YES];
		[self.constraintCallTeleMedCenterX setConstant:0.0f];
		[self.labelIntro setText:@"If you have questions or need further instruction on how to use the Med2Med app, please contact TeleMed using the button below."];
	
	#else
		// Hide call telemed button
		[self.buttonCallTeleMed setHidden:YES];
	#endif
}

// Help Video Control Action button with direct link to video
- (IBAction)showDemoVideo:(id)sender
{
	NSURL *videoStreamURL = [NSURL URLWithString:@"http://www.telemedinc.com/ios-app/resources/TeleMed-AppPreview-Update.mp4"];
	MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:videoStreamURL];
	
	[self presentMoviePlayerViewControllerAnimated:player];
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

#ifdef MED2MED
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Account picker
	if ([segue.identifier isEqualToString:@"showAccountPickerFromHelp"])
	{
		AccountPickerViewController *accountPickerViewController = segue.destinationViewController;
		
		// Update account picker screen title
		[accountPickerViewController setTitle:@"Call TeleMed"];
		
		// Enable account calling and account selection on account picker screen
		[accountPickerViewController setShouldCallAccount:YES];
		[accountPickerViewController setShouldSelectAccount:YES];
	}
}
#endif

@end
