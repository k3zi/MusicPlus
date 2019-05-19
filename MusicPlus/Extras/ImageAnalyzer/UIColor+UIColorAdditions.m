// 
//  UIColor+UIColorAdditions.m
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

#import "UIColor+UIColorAdditions.h"

typedef enum { R, G, B, A } UIColorComponentIndices;
#define MIN3(x,y,z)  ((y) <= (z) ? \
((x) <= (y) ? (x) : (y)) \
: \
((x) <= (z) ? (x) : (z)))

#define MAX3(x,y,z)  ((y) >= (z) ? \
((x) >= (y) ? (x) : (y)) \
: \
((x) >= (z) ? (x) : (z)))

struct rgb_color {
    CGFloat r, g, b;
};

struct hsv_color {
    CGFloat hue;
    CGFloat sat;
    CGFloat val;
};

@implementation UIColor (UIColorAdditions)

- (CGFloat)red{ return CGColorGetComponents(self.CGColor)[R]; }

- (CGFloat)green{ return CGColorGetComponents(self.CGColor)[G]; }

- (CGFloat)blue{ return CGColorGetComponents(self.CGColor)[B]; }

- (CGFloat)alpha{ return CGColorGetComponents(self.CGColor)[A]; }

+ (struct hsv_color)HSVfromRGB:(struct rgb_color)rgb{
    struct hsv_color hsv;

    CGFloat rgb_min, rgb_max;
    rgb_max = MAX3(rgb.r, rgb.g, rgb.b);

    hsv.val = rgb_max;
    if (hsv.val == 0) {
        hsv.hue = hsv.sat = 0;
        return hsv;
    }

    rgb.r /= hsv.val;
    rgb.g /= hsv.val;
    rgb.b /= hsv.val;
    rgb_min = MIN3(rgb.r, rgb.g, rgb.b);
    rgb_max = MAX3(rgb.r, rgb.g, rgb.b);

    hsv.sat = rgb_max - rgb_min;
    if (hsv.sat == 0) {
        hsv.hue = 0;
        return hsv;
    }

    if (rgb_max == rgb.r) {
        hsv.hue = 0.0 + 60.0*(rgb.g - rgb.b);
        if (hsv.hue < 0.0) {
            hsv.hue += 360.0;
        }
    } else if (rgb_max == rgb.g) {
        hsv.hue = 120.0 + 60.0*(rgb.b - rgb.r);
    } else /* rgb_max == rgb.b */ {
        hsv.hue = 240.0 + 60.0*(rgb.r - rgb.g);
    }

    return hsv;
}

- (CGFloat)hue{
    struct hsv_color hsv;
    struct rgb_color rgb;
    rgb.r = [self red];
    rgb.g = [self green];
    rgb.b = [self blue];
    hsv = [UIColor HSVfromRGB: rgb];
    return (hsv.hue / 360.0);
}

- (CGFloat)saturation{
    struct hsv_color hsv;
    struct rgb_color rgb;
    rgb.r = [self red];
    rgb.g = [self green];
    rgb.b = [self blue];
    hsv = [UIColor HSVfromRGB: rgb];
    return hsv.sat;
}

- (CGFloat)brightness{
    struct hsv_color hsv;
    struct rgb_color rgb;
    rgb.r = [self red];
    rgb.g = [self green];
    rgb.b = [self blue];
    hsv = [UIColor HSVfromRGB: rgb];
    return hsv.val;
}

- (CGFloat)value{
    return [self brightness];
}
@end

