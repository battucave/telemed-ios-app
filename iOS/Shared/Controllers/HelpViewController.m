//
//  HelpViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 6/13/14.
//  Copyright (c) 2014 SolutionBuilt. All rights reserved.
//

#import "HelpViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface HelpViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelVersion;
@property (weak, nonatomic) IBOutlet UIButton *playClicked;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintUserGuideCenterX;

@end

@implementation HelpViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	
	// Remove menu button if showing Back button. This MUST happen before [super viewWillAppear] so that Back Button will be added (Back button only shown when navigating from Login.storyboard View Controllers)
	if(self.showBackButton)
	{
		self.navigationItem.leftBarButtonItem = nil;
	}
	
	[super viewWillAppear:animated];
	
	[self.labelVersion setText:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

// Help Video Control Action button with direct link to video
- (IBAction)playClicked:(id)sender
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

@end
