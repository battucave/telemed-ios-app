//
//  EmailTelemedModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@interface EmailTelemedModel : Model

@property (weak) id delegate;

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress;
- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress withMessageDeliveryID:(NSNumber *)messageDeliveryID;

@end


@protocol EmailTelemedDelegate <NSObject>

@optional
- (void)emailTeleMedMessagePending;
- (void)emailTeleMedMessageSuccess;
- (void)emailTeleMedMessageError:(NSError *)error;

@end
