// 
//  ObjectiveCProcessing.m
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

#import "ObjectiveCProcessing.h"
#import "ImageHelper.h"
#import "UIColor+UIColorAdditions.h"

@implementation ObjectiveCProcessing

+ (UIColor *)getDominatingColor:(UIImage *)image {
    float maxDominatingFactor = 0;
    UIColor *returnColor;
    NSArray *colors = [ImageHelper mostFrequentColors:30 of:image withColorPallete:ColorPalete512];
    for (UIColor *color in colors) {
        if (([color brightness] + [color saturation]) > maxDominatingFactor) {
            returnColor = color;
            maxDominatingFactor = ([color brightness] + [color saturation]);
        }
    }

    return [UIColor colorWithHue:[returnColor hue] saturation:[returnColor saturation] brightness:MAX(0.88, MIN([returnColor brightness], 0.4)) alpha:1.0];
}

@end
