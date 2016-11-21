//
//  CommentModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"
#import "MessageModel.h"

@protocol CommentDelegate <NSObject>

@optional
- (void)saveCommentPending:(NSString *)comment withPendingID:(NSNumber *)pendingID;
- (void)saveCommentSuccess:(NSString *)comment withPendingID:(NSNumber *)pendingID;
- (void)saveCommentError:(NSError *)error withPendingID:(NSNumber *)pendingID;

@end

@interface CommentModel : Model

@property (weak) id delegate;

- (void)addMessageComment:(MessageModel *)message comment:(NSString *)comment withPendingID:(NSNumber *)pendingID;
- (void)addMessageComment:(MessageModel *)message comment:(NSString *)comment toForwardMessage:(BOOL)toForwardMessage;

@end
