//
//  ChatParticipantModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol ChatParticipantDelegate <NSObject>

@required
- (void)updateChatParticipants:(NSMutableArray *)newChatParticipants;

@optional
- (void)updateChatParticipantsError:(NSError *)error;

@end

@interface ChatParticipantModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *FirstName;
@property (nonatomic) NSString *LastName;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *FormattedName;
@property (nonatomic) NSString *FormattedNameLF;

- (void)getChatParticipants;

@end
