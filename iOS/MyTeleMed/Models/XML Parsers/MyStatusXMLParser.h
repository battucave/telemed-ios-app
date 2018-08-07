//
//  MyStatusXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MyStatusModel.h"

@interface MyStatusXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) MyStatusModel *myStatus;

@end
