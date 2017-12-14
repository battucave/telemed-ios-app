//
//  CDMAVoiceDataViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 2/18/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "CDMAVoiceDataViewController.h"

@interface CDMAVoiceDataViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonOK;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonShowOnStartup;
@property (weak, nonatomic) IBOutlet UISwitch *switchCDMAVoiceData;

@property (weak, nonatomic) NSUserDefaults *settings;

@end

@implementation CDMAVoiceDataViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.settings = [NSUserDefaults standardUserDefaults];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.barButtonShowOnStartup setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]} forState:UIControlStateNormal];
	[self.barButtonOK setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
}

- (IBAction)toggleSwitchCDMAVoiceData:(UISwitch *)sender
{
	[self.switchCDMAVoiceData setOn: ! self.switchCDMAVoiceData.isOn animated:YES];
}

- (IBAction)toggleCDMAVoiceDataDisabled:(UISwitch *)sender
{
	// Toggle CDMA Voice Data window on change of UISwitch
	[self.settings setBool: ! sender.isOn forKey:@"CDMAVoiceDataDisabled"];
}

- (IBAction)dismissViewController:(id)sender
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:@"CDMAVoiceDataHidden"];
	[settings synchronize];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
