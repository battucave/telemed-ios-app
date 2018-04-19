//
//  MessageNewTableViewController.h
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RevealTableViewController.h"
#import "AccountModel.h"
#import "HospitalModel.h"
#import "OnCallSlotModel.h"

@interface MessageNewTableViewController : RevealTableViewController <UITextFieldDelegate>

@property (nonatomic) NSMutableDictionary *formValues;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) HospitalModel *selectedHospital;
@property (nonatomic) NSMutableArray *selectedMessageRecipients; // Only used if user returned back to this screen from message recipient picker screen
@property (nonatomic) OnCallSlotModel *selectedOnCallSlot; // Only used if user returned back to this screen from on call slot picker screen

@end
