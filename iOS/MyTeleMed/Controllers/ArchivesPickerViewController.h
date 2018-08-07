//
//  ArchivesPickerViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/4/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreViewController.h"
#import "AccountModel.h"

@interface ArchivesPickerViewController : CoreViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) NSInteger selectedAccountIndex;
@property (nonatomic) NSInteger selectedDateIndex;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSString *selectedDate;

//@property (nonatomic) NSString *accountName;
//@property (nonatomic) NSInteger accountPublicKey;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;

@end
