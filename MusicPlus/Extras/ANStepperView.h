// 
//  ANStepperView.h
//  ANStepperViewExample
// 
//  Created by Afonso Cavaco Neto on 21/02/16.
//  Copyright © 2016 Innovation Makers. All rights reserved.
// 

@import UIKit;

typedef NS_ENUM(NSUInteger, ANStepperType) {
    ANStepperTypeDefault,
    ANStepperTypeDefaultNotAnimated,
    ANStepperTypeMinimal,
    ANStepperTypeMinimalAnimated,
    ANStepperTypeMixed,
    ANStepperTypeMixedNotAnimated
};

IB_DESIGNABLE
@class ANStepperView;
@interface ANStepperView : UIControl

@property (nonatomic, strong) IBInspectable UIColor* buttonBackgroundColor;
@property (nonatomic, strong) IBInspectable UIColor* labelBackgroundColor;
@property (nonatomic, strong) IBInspectable UIColor* labelTextColor;
@property (nonatomic, strong) IBInspectable UIColor* buttonTextColor;
@property (nonatomic, strong) IBInspectable UIColor* disabledButtonColor;
@property (nonatomic, assign) IBInspectable CGFloat incrementValue;
@property (nonatomic, assign) IBInspectable NSUInteger stepperType;
@property (nonatomic, assign) IBInspectable CGFloat minimumValue;
@property (nonatomic, assign) IBInspectable CGFloat maximumValue;
@property (nonatomic, strong) IBInspectable UIColor* tintColor;
@property (nonatomic, strong) IBInspectable NSString* decreaseButtonTitle;
@property (nonatomic, strong) IBInspectable NSString* increaseButtonTitle;
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;
@property (nonatomic, assign) IBInspectable CGFloat labelWidthWeight;

@property (nonatomic, strong, readonly) NSString* currentTitle;

-(instancetype)initWithType:(ANStepperType)type;

@end
