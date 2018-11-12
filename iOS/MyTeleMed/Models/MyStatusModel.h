//
//  MyStatusModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"

// Primary model
@interface MyStatusModel : Model

@property (weak) id delegate;

// Message counts
@property (nonatomic) NSNumber *ActiveMessageCount;
@property (nonatomic) NSNumber *UnreadMessageCount;

// Chat message counts
@property (nonatomic) NSNumber *ActiveChatConvoCount;
@property (nonatomic) NSNumber *UnopenedChatConvoCount;

// On call status
@property (nonatomic) BOOL OnCallNow;
@property (nonatomic) NSDate *NextOnCall;
@property (nonatomic) NSArray *CurrentOnCallEntries;
@property (nonatomic) NSArray *FutureOnCallEntries;

+ (instancetype)sharedInstance;

- (void)getWithCallback:(void (^)(BOOL success, MyStatusModel *status, NSError *error))callback;

@end

@interface OnCallEntryModel : NSObject

@property (nonatomic) NSNumber *AccountID;
@property (nonatomic) NSNumber *AccountKey;
@property (nonatomic) NSString *AccountName;
@property (nonatomic) NSString *SlotDesc;
@property (nonatomic) NSNumber *SlotID;
@property (nonatomic) NSDate *Started;
@property (nonatomic) NSDate *WillEnd;
@property (nonatomic) NSDate *WillStart;

// Temporary property only used in OnCallScheduleViewController to control output of date
@property (nonatomic) BOOL shouldDisplayDate;

@end
