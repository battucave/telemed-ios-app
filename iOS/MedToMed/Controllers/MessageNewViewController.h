//
//  MessageNewViewController.h
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RevealTableViewController.h"
#import "AccountModel.h"
#import "HospitalModel.h"

@interface MessageNewViewController : RevealTableViewController <UITextFieldDelegate>

@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) HospitalModel *selectedHospital;

@end
