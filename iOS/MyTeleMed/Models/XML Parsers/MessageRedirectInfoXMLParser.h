//
//  MessageRedirectInfoXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/09/18.
//  Copyright (c) 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MessageRedirectInfoModel.h"

@interface MessageRedirectInfoXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) MessageRedirectInfoModel *messageRedirectInfo;

@end
