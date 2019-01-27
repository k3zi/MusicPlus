// 
//  UIColor+UIColorAdditions.h
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor (UIColorAdditions)

- (CGFloat)red;
- (CGFloat)green;
- (CGFloat)blue;
- (CGFloat)alpha;
- (CGFloat)hue;
- (CGFloat)brightness;
- (CGFloat)saturation;

@end

@interface NSString (UIColorAdditions)

+ (UIColor *)colorFromNSString:(NSString *)string;

@end
