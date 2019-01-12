// 
//  ANStepperView.m
//  ANStepperViewExample
// 
//  Created by Afonso Cavaco Neto on 21/02/16.
//  Copyright © 2016 Innovation Makers. All rights reserved.
// 

#import "ANStepperView.h"

typedef NS_ENUM(NSUInteger, labelDirection) {
    labelDirectionLeft,
    labelDirectionRigth,
    labelDirectionOriginal
};

static const CGFloat thickness = 1;

@interface ANStepperView ()

@property (nonatomic, strong) UIButton* increaseButton;
@property (nonatomic, strong) UILabel* label;
@property (nonatomic, strong) UIButton* decreaseButton;
@property (nonatomic, assign) CGPoint labelOriginalCenter;
@property (nonatomic, assign) CGFloat value;
@property (nonatomic, assign) NSInteger fractionDigits;
@property (nonatomic, assign) CGFloat labelWidth;
@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, assign, getter=isAnimated) BOOL animated;
@property (nonatomic, strong) UIColor* defaultButtonBackgroundColor;
@property (nonatomic, strong) UIColor* defaultLabelBackgroundColor;
@property (nonatomic, strong) UIColor* defaultTextColor;
@property (nonatomic, strong) CAShapeLayer* leftSeparator;
@property (nonatomic, strong) CAShapeLayer* rightSeparator;
@property (nonatomic, strong) CAShapeLayer* increaseLayer;
@property (nonatomic, strong) CAShapeLayer* decreaseLayer;

@end

@implementation ANStepperView

-(instancetype)initWithType:(ANStepperType)type {
    if ((self = [super init])) {
        _labelWidthWeight = 0.5;
        _cornerRadius = 5;
        [self setup];
        _stepperType = type;
    }
    
    return self;
}

-(instancetype)init {
    
    if ((self = [super init])) {
        _labelWidthWeight = 0.5;
        _cornerRadius = 5;
        [self setup];
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        _cornerRadius = 5;
        _labelWidthWeight = 0.5;
        [self setup];
    }
    
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])) {
        _cornerRadius = 5;
        _labelWidthWeight = 0.5;
        [self setup];
    }
    
    return self;
}

-(void)setup {
    
    self.defaultButtonBackgroundColor = [UIColor colorWithRed:0.21 green:0.5 blue:0.74 alpha:1];
    self.defaultLabelBackgroundColor = [UIColor colorWithRed:0.26 green:0.6 blue:0.87 alpha:1];
    self.defaultTextColor = [UIColor whiteColor];
    self.disabledButtonColor = [UIColor grayColor];
    self.increaseButtonTitle = @"+";
    self.decreaseButtonTitle = @"-";
    
    self.decreaseButton = [[UIButton alloc] init];
    [self.decreaseButton setTitleColor:self.defaultTextColor forState:UIControlStateNormal];
    self.decreaseButton.backgroundColor = self.defaultButtonBackgroundColor;
    
    [self.decreaseButton addTarget:self
                            action:@selector(decreaseButtonTouchDown:)
                  forControlEvents:UIControlEventTouchDown];
    
    [self.decreaseButton addTarget:self
                            action:@selector(buttonTouchUp:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    [self.decreaseButton addTarget:self
                            action:@selector(buttonTouchUp:)
                  forControlEvents:UIControlEventTouchUpOutside];
    
    [self addSubview:self.decreaseButton];
    
    self.increaseButton = [[UIButton alloc] init];
    [self.increaseButton setTitleColor:self.defaultTextColor forState:UIControlStateNormal];
    self.increaseButton.backgroundColor = self.defaultButtonBackgroundColor;
    
    [self.increaseButton addTarget:self
                            action:@selector(increaseButtonTouchDown:)
                  forControlEvents:UIControlEventTouchDown];
    
    [self.increaseButton addTarget:self
                            action:@selector(buttonTouchUp:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    [self.increaseButton addTarget:self
                            action:@selector(buttonTouchUp:)
                  forControlEvents:UIControlEventTouchUpOutside];
    
    [self addSubview:self.increaseButton];
    
    self.label = [[UILabel alloc] init];
    [self.label setText:@"0"];
    [self.label setTextAlignment:NSTextAlignmentCenter];
    self.label.backgroundColor = self.defaultLabelBackgroundColor;
    self.label.textColor = self.defaultTextColor;
    [self addSubview:self.label];
    self.value = 0;
    if (self.incrementValue == 0) {
        self.incrementValue = 1;
    }
    self.maximumValue = 10;
    self.minimumValue = -10;
    self.animated = YES;
    self.stepperType = ANStepperTypeDefault;
    
}

-(void)layoutSubviews {
    
    self.buttonWidth = CGRectGetWidth(self.bounds) * ((1 - self.labelWidthWeight) / 2);
    self.labelWidth = CGRectGetWidth(self.bounds) * self.labelWidthWeight;
    
    self.decreaseButton.frame = CGRectMake(0, 0, self.buttonWidth, CGRectGetHeight(self.bounds));
    self.label.frame = CGRectMake(self.buttonWidth, 0, self.labelWidth, CGRectGetHeight(self.bounds));
    self.increaseButton.frame = CGRectMake(self.buttonWidth + self.labelWidth, 0, self.buttonWidth, CGRectGetHeight(self.bounds));
    
    self.labelOriginalCenter = self.label.center;
}

-(void)drawRect:(CGRect)rect {
    
    CGFloat halfThickness = thickness / 2;
    CGFloat iconSize = self.buttonWidth * 0.3;
    CGFloat height = CGRectGetHeight(self.bounds);
    
    [self setupType];
    
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.cornerRadius;
    
    self.tintColor = (self.tintColor)?self.tintColor:[UIColor whiteColor];
    self.buttonTextColor = (self.buttonTextColor)?self.buttonTextColor:self.tintColor;
    
    if (self.stepperType == ANStepperTypeMinimal || self.stepperType == ANStepperTypeMinimalAnimated || self.stepperType == ANStepperTypeMixed || self.stepperType == ANStepperTypeMixedNotAnimated) {
        
        if (self.stepperType != ANStepperTypeMixed && self.stepperType != ANStepperTypeMixedNotAnimated) {
            self.buttonBackgroundColor = [UIColor clearColor];
            self.labelBackgroundColor = [UIColor clearColor];
            self.layer.borderColor = self.tintColor.CGColor;
            self.layer.borderWidth = thickness;
            
            if (!self.leftSeparator) {
                UIBezierPath* leftPath = [UIBezierPath bezierPath];
                [leftPath moveToPoint:CGPointMake(self.buttonWidth, 0)];
                [leftPath addLineToPoint:CGPointMake(self.buttonWidth, CGRectGetHeight(self.bounds))];
                [self.tintColor setStroke];
                [leftPath stroke];
                
                self.leftSeparator = [CAShapeLayer layer];
                self.leftSeparator.path = leftPath.CGPath;
                self.leftSeparator.strokeColor = self.tintColor.CGColor;
                [self.layer addSublayer:self.leftSeparator];
            }
            if (!self.rightSeparator) {
                UIBezierPath* rightPath = [UIBezierPath bezierPath];
                [rightPath moveToPoint:CGPointMake(self.buttonWidth + self.labelWidth, 0)];
                [rightPath addLineToPoint:CGPointMake(self.buttonWidth + self.labelWidth, CGRectGetHeight(self.bounds))];
                [self.tintColor setStroke];
                [rightPath stroke];
                
                self.rightSeparator = [CAShapeLayer layer];
                self.rightSeparator.path = rightPath.CGPath;
                self.rightSeparator.strokeColor = self.tintColor.CGColor;
                [self.layer addSublayer:self.rightSeparator];
            }
        }
        
        UIBezierPath* decreasePath = [UIBezierPath bezierPath];
        decreasePath.lineWidth = thickness;
        [decreasePath moveToPoint:CGPointMake((self.buttonWidth - iconSize) / 2 + halfThickness, height / 2 + halfThickness)];
        [decreasePath addLineToPoint:CGPointMake((self.buttonWidth - iconSize) / 2 + halfThickness + iconSize, height / 2 + halfThickness)];
        [self.buttonTextColor setStroke];
        [decreasePath stroke];
        
        self.decreaseLayer = [CAShapeLayer layer];
        self.decreaseLayer.path = decreasePath.CGPath;
        self.decreaseLayer.strokeColor = self.buttonTextColor.CGColor;
        [self.layer addSublayer:self.decreaseLayer];
        
        UIBezierPath* increasePath = [UIBezierPath bezierPath];
        increasePath.lineWidth = thickness;
        [increasePath moveToPoint:CGPointMake((self.buttonWidth - iconSize) / 2 + halfThickness + self.buttonWidth + self.labelWidth, height / 2 + halfThickness)];
        [increasePath addLineToPoint:CGPointMake((self.buttonWidth - iconSize) / 2 + halfThickness + iconSize + self.buttonWidth + self.labelWidth, height / 2 + halfThickness)];
        [increasePath moveToPoint:CGPointMake(self.buttonWidth / 2 + halfThickness + self.buttonWidth + self.labelWidth, (height / 2) - (iconSize / 2) + halfThickness)];
        [increasePath addLineToPoint:CGPointMake(self.buttonWidth / 2 + halfThickness + self.buttonWidth + self.labelWidth, (height / 2) + (iconSize / 2) + halfThickness)];
        [self.buttonTextColor setStroke];
        [increasePath stroke];
        
        self.increaseLayer = [CAShapeLayer layer];
        self.increaseLayer.path = increasePath.CGPath;
        self.increaseLayer.strokeColor = self.buttonTextColor.CGColor;
        [self.layer addSublayer:self.increaseLayer];
    }
    [self setupButtonState];
}

#pragma mark - Actions

-(void)decreaseButtonTouchDown:(id)sender {
    self.value -= self.incrementValue;
    [self slideLabelTo:labelDirectionLeft];
}

-(void)increaseButtonTouchDown:(id)sender {
    self.value += self.incrementValue;
    [self slideLabelTo:labelDirectionRigth];
}

-(void)buttonTouchUp:(id)sender {
    [self slideLabelTo:labelDirectionOriginal];
}

#pragma mark - Animations

-(void)slideLabelTo:(labelDirection)direction {
    
    if (self.isAnimated) {
        static const NSInteger sideLenght = 5;
        switch (direction) {
            case labelDirectionLeft:
                [self slideLabel:-sideLenght original:NO];
                break;
            case labelDirectionRigth:
                [self slideLabel:sideLenght original:NO];
                break;
            case labelDirectionOriginal:
                [self slideLabel:sideLenght original:YES];
                break;
        }
    }
    
}

-(void)slideLabel:(CGFloat)sideLenght original:(BOOL)original {
    if (original) {
        if (self.label.center.x != self.labelOriginalCenter.x) {
            [UIView animateWithDuration:0.1 animations:^{
                self.label.center = self.labelOriginalCenter;
            }];
        }
    } else {
        [UIView animateWithDuration:0.1 animations:^{
            CGFloat side = sideLenght;
            side += self.label.center.x;
            self.label.center = CGPointMake(side, self.label.center.y);
        }];

    }
}

#pragma mark - Setters

-(void)setValue:(CGFloat)value {
    
    if (_value != value) {
        if (!(value < self.minimumValue || value > self.maximumValue)) {
            NSString* valueString = [NSString stringWithFormat:@"%0.*f", (int)self.fractionDigits, value];
            if ((self.fractionDigits > 0) && ([valueString doubleValue] == [valueString integerValue])) {
                valueString = [NSString stringWithFormat:@"%ld", (long)[valueString integerValue]];
                
            }
            _value = [valueString doubleValue];
            [self.label setText:valueString];
            _currentTitle = valueString;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
            [self setupButtonState];
        }
    }
}

-(void)setIncrementValue:(CGFloat)incrementValue {
    _incrementValue = incrementValue;
    _fractionDigits = [self numberOfFractionNumbersIn:incrementValue];
}

-(void)setButtonBackgroundColor:(UIColor *)buttonBackgroundColor {
    _buttonBackgroundColor = buttonBackgroundColor;
    self.decreaseButton.backgroundColor = buttonBackgroundColor;
    self.increaseButton.backgroundColor = buttonBackgroundColor;
    self.backgroundColor = buttonBackgroundColor;
}

-(void)setButtonTextColor:(UIColor *)buttonTextColor {
    _buttonTextColor = buttonTextColor;
    if (self.stepperType == ANStepperTypeDefault || self.stepperType == ANStepperTypeDefaultNotAnimated) {
        [self.decreaseButton setTitleColor:buttonTextColor forState:UIControlStateNormal];
        [self.increaseButton setTitleColor:buttonTextColor forState:UIControlStateNormal];
    } else {
        self.increaseLayer.strokeColor = buttonTextColor.CGColor;
        self.decreaseLayer.strokeColor = buttonTextColor.CGColor;
    }
}

-(void)setLabelBackgroundColor:(UIColor *)labelBackgroundColor {
    _labelBackgroundColor = labelBackgroundColor;
    self.label.backgroundColor = labelBackgroundColor;
}

-(void)setLabelTextColor:(UIColor *)labelTextColor {
    _labelTextColor = labelTextColor;
    self.label.textColor = labelTextColor;
}

-(void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    self.layer.borderColor = tintColor.CGColor;
    self.leftSeparator.strokeColor = tintColor.CGColor;
    self.rightSeparator.strokeColor = tintColor.CGColor;
    
}

-(void)setDecreaseButtonTitle:(NSString *)decreaseButtonTitle {
    _decreaseButtonTitle = decreaseButtonTitle;
    if (self.stepperType == ANStepperTypeDefault || self.stepperType == ANStepperTypeDefaultNotAnimated) {
        [self.decreaseButton setTitle:decreaseButtonTitle forState:UIControlStateNormal];
    }
}

-(void)setIncreaseButtonTitle:(NSString *)increaseButtonTitle {
    _increaseButtonTitle = increaseButtonTitle;
    if (self.stepperType == ANStepperTypeDefault || self.stepperType == ANStepperTypeDefaultNotAnimated) {
        [self.increaseButton setTitle:increaseButtonTitle forState:UIControlStateNormal];
    }
}

#pragma mark - helpers

-(void)setupType {
    
    switch (self.stepperType) {
        case ANStepperTypeDefault:
            self.animated = YES;
            [self.decreaseButton setTitle:self.decreaseButtonTitle forState:UIControlStateNormal];
            [self.increaseButton setTitle:self.increaseButtonTitle forState:UIControlStateNormal];
            [self.increaseButton setTitleColor:self.disabledButtonColor forState:UIControlStateDisabled];
            [self.decreaseButton setTitleColor:self.disabledButtonColor forState:UIControlStateDisabled];
            break;
        case ANStepperTypeMinimalAnimated:
        case ANStepperTypeMixed:
            self.animated = YES;
            [self.decreaseButton setTitle:@"" forState:UIControlStateNormal];
            [self.increaseButton setTitle:@"" forState:UIControlStateNormal];
            break;
        case ANStepperTypeDefaultNotAnimated:
            self.animated = NO;
            [self.decreaseButton setTitle:self.decreaseButtonTitle forState:UIControlStateNormal];
            [self.increaseButton setTitle:self.increaseButtonTitle forState:UIControlStateNormal];
            [self.increaseButton setTitleColor:self.disabledButtonColor forState:UIControlStateDisabled];
            [self.decreaseButton setTitleColor:self.disabledButtonColor forState:UIControlStateDisabled];
            break;
        case ANStepperTypeMinimal:
        case ANStepperTypeMixedNotAnimated:
            self.animated = NO;
            [self.decreaseButton setTitle:@"" forState:UIControlStateNormal];
            [self.increaseButton setTitle:@"" forState:UIControlStateNormal];
            break;
    }
}

-(void)setupButtonState {
    
    if (self.value >= self.maximumValue) {
        self.increaseButton.enabled = NO;
        if (self.stepperType == ANStepperTypeMinimal || self.stepperType == ANStepperTypeMinimalAnimated || self.stepperType == ANStepperTypeMixed || self.stepperType == ANStepperTypeMixedNotAnimated) {
            self.increaseLayer.strokeColor = self.disabledButtonColor.CGColor;
        }
        
    } else if (self.value <= self.minimumValue) {
        self.decreaseButton.enabled = NO;
        if (self.stepperType == ANStepperTypeMinimal || self.stepperType == ANStepperTypeMinimalAnimated || self.stepperType == ANStepperTypeMixed || self.stepperType == ANStepperTypeMixedNotAnimated) {
            self.decreaseLayer.strokeColor = self.disabledButtonColor.CGColor;
        }
    } else {
        self.increaseButton.enabled = YES;
        self.decreaseButton.enabled = YES;
        if (self.stepperType == ANStepperTypeMinimal || self.stepperType == ANStepperTypeMinimalAnimated || self.stepperType == ANStepperTypeMixed || self.stepperType == ANStepperTypeMixedNotAnimated) {
            self.increaseLayer.strokeColor = (self.buttonTextColor)?self.buttonTextColor.CGColor:self.tintColor.CGColor;
            self.decreaseLayer.strokeColor = (self.buttonTextColor)?self.buttonTextColor.CGColor:self.tintColor.CGColor;
        }
    }
}

-(NSInteger)numberOfFractionNumbersIn:(CGFloat)number {
    
    NSString *priorityString = [[NSNumber numberWithFloat:number] stringValue];
    NSRange range = [priorityString rangeOfString:@"."];
    NSInteger digits;
    if (range.location != NSNotFound) {
        priorityString = [priorityString substringFromIndex:range.location + 1];
        digits = [priorityString length];
    } else {
        range = [priorityString rangeOfString:@"e-"];
        if (range.location != NSNotFound) {
            priorityString = [priorityString substringFromIndex:range.location + 2];
            digits = [priorityString intValue];
        } else {
            digits = 0;
        }
    }
    
    return digits;
}

@end
