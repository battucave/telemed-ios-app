//
//  CommentModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"
#import "MessageProtocol.h"

@interface CommentModel : Model

@property (weak) id delegate;

- (void)addMessageComment:(id <MessageProtocol>)message comment:(NSString *)comment withPendingID:(NSNumber *)pendingID;
- (void)addMessageComment:(id <MessageProtocol>)message comment:(NSString *)comment toForwardMessage:(BOOL)toForwardMessage;

@end


@protocol CommentDelegate <NSObject>

@optional
- (void)saveCommentPending:(NSString *)comment withPendingID:(NSNumber *)pendingID;
- (void)saveCommentSuccess:(NSString *)comment withPendingID:(NSNumber *)pendingID;
- (void)saveCommentError:(NSError *)error withPendingID:(NSNumber *)pendingID;

@end
