//
//  EmailTelemedModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/3/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol EmailTelemedDelegate <NSObject>

@required
- (void)sendMessageSuccess;
- (void)sendMessageError:(NSError *)error;

@end

@interface EmailTelemedModel : Model

@property (weak) id delegate;
@property (nonatomic) BOOL Success;
@property (nonatomic) NSString *Message;

- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress;
- (void)sendTelemedMessage:(NSString *)message fromEmailAddress:(NSString *)fromEmailAddress messageID:(NSNumber *)messageID;

@end
