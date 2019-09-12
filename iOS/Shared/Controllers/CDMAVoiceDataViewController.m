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
@property (weak, nonatomic) IBOutlet UITextView *textViewCDMA;

@end

@implementation CDMAVoiceDataViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.barButtonShowOnStartup setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]} forState:UIControlStateNormal];
	[self.barButtonOK setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
}

- (IBAction)dismissViewController:(id)sender
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:CDMAVoiceDataHidden];
	[settings synchronize];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleCDMAVoiceDataWarning:(UISwitch *)sender
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Toggle whether this view should show again on next run
	[settings setBool:sender.isOn forKey:ShowSprintVoiceDataWarning];
	[settings setBool:sender.isOn forKey:ShowVerizonVoiceDataWarning];
	[settings synchronize];
}

- (IBAction)toggleSwitchCDMAVoiceData:(UISwitch *)sender
{
	[self.switchCDMAVoiceData setOn: ! self.switchCDMAVoiceData.isOn animated:YES];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
