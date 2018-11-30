//
//  MessageRedirectInfoModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/09/18.
//  Copyright (c) 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"
#import "OnCallSlotModel.h"

@interface MessageRedirectInfoModel : Model

@property (nonatomic) NSNumber *DeliveryID;
@property (nonatomic) OnCallSlotModel *EscalationSlot;
@property (nonatomic) NSArray *ForwardRecipients;
@property (nonatomic) NSArray *RedirectRecipients;
@property (nonatomic) NSArray *RedirectSlots;

- (void)getMessageRedirectInfoForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, MessageRedirectInfoModel *messageRedirectInfo, NSError *error))callback;

- (BOOL)canEscalate;
- (BOOL)canForwardCopy;
- (BOOL)canRedirect;

@end
