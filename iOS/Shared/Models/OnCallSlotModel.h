//
//  OnCallSlotModel.h
//  Med2Med
//
//  Created by Shane Goodwin on 4/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"

@interface OnCallSlotModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *CurrentOncall;
@property (nonatomic) NSString *CurrentOncallEntryTypeID; // MyTeleMed only
@property (nonatomic) NSString *Description;
@property (nonatomic) NSString *Header;
@property (nonatomic) BOOL IsEscalationSlot; // MyTeleMed only
@property (nonatomic) NSString *Name;
@property (nonatomic) BOOL SelectRecipient; // MyTeleMed only

- (void)getOnCallSlots:(NSNumber *)accountID;

@end


@protocol OnCallSlotDelegate <NSObject>

@required
- (void)updateOnCallSlots:(NSArray *)newOnCallSlots;

@optional
- (void)updateOnCallSlotsError:(NSError *)error;

@end
