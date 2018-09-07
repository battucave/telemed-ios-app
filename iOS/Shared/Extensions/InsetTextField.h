//
//  InsetTextField.h
//  TeleMed
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

// This category is automatically used by Storyboard to provide extra properties on the Attributes Inspector

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface InsetTextField : UITextField

@property (nonatomic) IBInspectable NSInteger bottomInset;
@property (nonatomic) IBInspectable NSInteger leftInset;
@property (nonatomic) IBInspectable NSInteger rightInset;
@property (nonatomic) IBInspectable NSInteger topInset;

@end
