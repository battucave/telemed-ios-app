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
@property (nonatomic) NSString *Description;
@property (nonatomic) NSString *Header;
@property (nonatomic) NSString *Name;

- (void)getOnCallSlots:(NSNumber *)accountID;


#pragma mark - MyTeleMed

#ifdef MYTELEMED
@property (nonatomic) BOOL IsEscalationSlot;
@property (nonatomic) BOOL SelectRecipient;
#endif

@end


@protocol OnCallSlotDelegate <NSObject>

@required
- (void)updateOnCallSlots:(NSArray *)newOnCallSlots;

@optional
- (void)updateOnCallSlotsError:(NSError *)error;

@end
