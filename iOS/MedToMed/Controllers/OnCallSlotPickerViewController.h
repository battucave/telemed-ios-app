//
//  OnCallSlotPickerViewController.h
//  MedToMed
//
//  Created by Shane Goodwin on 4/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "AccountModel.h"
#import "OnCallSlotModel.h"

@interface OnCallSlotPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (weak) id delegate;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) OnCallSlotModel *selectedOnCallSlot;

@property (nonatomic) NSMutableDictionary *formValues; // Store form values to be passed to next screen
@property (nonatomic) NSMutableArray *selectedMessageRecipients; // Only used if user returns back to this screen after selecting message recipients

@end
