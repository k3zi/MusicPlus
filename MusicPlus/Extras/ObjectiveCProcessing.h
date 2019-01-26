// 
//  ObjectiveCProcessing.h
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TintColorOperation : NSOperation

enum ColorPalete {
    ColorPalete64,
    ColorPalete512,
    ColorPalete1024,
    ColorPalete2048
};
typedef enum ColorPalete ColorPalete;

@property (nonatomic, retain) UIColor *result;

- (instancetype)initWithImage:(UIImage *)image andColorPallete:(ColorPalete)palete;


@end
