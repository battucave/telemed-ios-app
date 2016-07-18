//
//  CommentModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol CommentDelegate <NSObject>

@required
- (void)saveCommentSuccess:(NSString *)comment;
- (void)saveCommentError:(NSError *)error;

@end

@interface CommentModel : Model

@property (weak) id delegate;

- (void)addMessageComment:(NSNumber *)messageID comment:(NSString *)comment;

@end
