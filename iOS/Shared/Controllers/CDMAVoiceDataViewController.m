//
//  CDMAVoiceDataViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 2/18/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <sys/utsname.h>

#import "CDMAVoiceDataViewController.h"

@interface CDMAVoiceDataViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonOK;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonShowOnStartup;
@property (weak, nonatomic) IBOutlet UISwitch *switchCDMAVoiceData;
@property (weak, nonatomic) IBOutlet UITextView *textViewCDMA;
@property (weak, nonatomic) IBOutlet UITextView *textViewVerizon;

@end

@implementation CDMAVoiceDataViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.barButtonShowOnStartup setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]} forState:UIControlStateNormal];
	[self.barButtonOK setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:20.0]} forState:UIControlStateNormal];
	
	// Show a different message to VoLTE supported Verizon users
	if ([self isVerizonVoLTESupported])
	{
		[self.textViewCDMA setHidden:YES];
		[self.textViewVerizon setHidden:NO];
	}
}

- (IBAction)dismissViewController:(id)sender
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:YES forKey:@"CDMAVoiceDataHidden"];
	[settings synchronize];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleCDMAVoiceDataWarning:(UISwitch *)sender
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Toggle whether this view should show again on next run
	[settings setBool:sender.isOn forKey:@"showSprintVoiceDataWarning"];
	[settings setBool:sender.isOn forKey:@"showVerizonVoiceDataWarning"];
	[settings synchronize];
}

- (IBAction)toggleSwitchCDMAVoiceData:(UISwitch *)sender
{
	[self.switchCDMAVoiceData setOn: ! self.switchCDMAVoiceData.isOn animated:YES];
}

- (BOOL)isVerizonVoLTESupported
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If running on Verizon network (as determined in AppDelegate)
	if ([settings boolForKey:@"showVerizonVoiceDataWarning"])
	{
		// Get device model
		struct utsname systemInfo;
		
		uname(&systemInfo);
		
		NSString *deviceModelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
		deviceModelName = [[deviceModelName componentsSeparatedByString:@","] objectAtIndex:0];
		
		// VoLTE is supported on iPhone 6 and up
		if (deviceModelName.length >= 6)
		{
			NSString *deviceType = [deviceModelName substringToIndex:6];
			NSString *deviceNumber = [deviceModelName substringFromIndex:6];
			
			// If the device is an iPhone and the model is 7 or higher (iPhone 6 and iPhone 6+ are model 7)
			if ([deviceType isEqualToString:@"iPhone"] && (int)[deviceNumber integerValue] > 6)
			{
				return YES;
			}
		}
	}
	
	return NO;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
