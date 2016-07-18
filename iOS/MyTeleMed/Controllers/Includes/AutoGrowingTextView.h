//
//  AutoGrowingTextView.h
//
//  Created by Adam on 10/10/13.
//

#import <UIKit/UIKit.h>

@interface AutoGrowingTextView : UITextView

@property (nonatomic) CGFloat maxHeight;
@property (nonatomic) CGFloat minHeight;
// TODO: @property (nonatomic) int maxLines;
// TODO: @property (nonatomic) int minLines;

@end