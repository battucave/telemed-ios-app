//
//  MyStatusModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

// Primary Model
@interface MyStatusModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSNumber *ActiveMessageCount;
@property (nonatomic) BOOL OnCallNow;
@property (nonatomic) NSString *NextOnCall;
@property (nonatomic) NSNumber *UnreadMessageCount;

@property (nonatomic) NSArray *CurrentOnCallEntries;
@property (nonatomic) NSArray *FutureOnCallEntries;

+ (MyStatusModel *)sharedInstance;

- (void)getWithCallback:(void (^)(BOOL success, MyStatusModel *status, NSError *error))callback;

@end

@interface OnCallEntryModel : NSObject

@property (nonatomic) NSNumber *AccountID;
@property (nonatomic) NSNumber *AccountKey;
@property (nonatomic) NSString *AccountName;
@property (nonatomic) NSString *SlotDesc;
@property (nonatomic) NSNumber *SlotID;
@property (nonatomic) NSString *WillStart;
@property (nonatomic) NSString *WillEnd;

// Temporary Property only used in OnCallScheduleViewController to control output of date
@property (nonatomic) BOOL shouldDisplayDate;

@end