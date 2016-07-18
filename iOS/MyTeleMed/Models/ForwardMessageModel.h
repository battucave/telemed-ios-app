//
//  ForwardMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol ForwardMessageDelegate <NSObject>

@required
- (void)sendMessageSuccess;
- (void)sendMessageError:(NSError *)error;

@end

@interface ForwardMessageModel : Model

@property (weak) id delegate;
@property (nonatomic) BOOL Success;
@property (nonatomic) NSString *Message;

- (void)forwardMessage:(NSNumber *)messageID messageRecipientIDs:(NSArray *)messageRecipientIDs;

@end