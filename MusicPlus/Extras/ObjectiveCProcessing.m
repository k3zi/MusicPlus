// 
//  ObjectiveCProcessing.m
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

#import "ObjectiveCProcessing.h"
#import "UIColor+UIColorAdditions.h"

struct Address3D {
    NSInteger x;
    NSInteger y;
    NSInteger z;
    NSInteger w;
};


typedef struct Address3D Address3D;

@interface TintColorOperation ()

@property (nonatomic, retain) UIImage *image;

@property (nonatomic, assign) NSInteger _colorMatrixSize;
@property (nonatomic, assign) NSInteger ***_colorMatrix;
@property (nonatomic, assign) NSInteger _black;
@property (nonatomic, assign) NSInteger _white;
@property (nonatomic, assign) uint32_t *bitmapData;

@end

@implementation TintColorOperation

- (instancetype)initWithImage:(UIImage *)image andColorPallete:(ColorPalete)palete {
    self = [super init];
    if (self) {
        __colorMatrixSize = 0;
        __colorMatrix = nil;
        __black = 0;
        __white = 0;
        _image = image;
    }
    return self;
}

- (void)start {
    float maxDominatingFactor = 0;
    UIColor *returnColor;
    NSArray *colors = [self mostFrequentColors:30 of:_image withColorPallete:ColorPalete1024];
    for (UIColor *color in colors) {
        if (self.isCancelled) {
            break;
        }

        if (([color brightness] + [color saturation]) > maxDominatingFactor) {
            returnColor = color;
            maxDominatingFactor = ([color brightness] + [color saturation]);
        }
    }

    _result = [UIColor colorWithHue:[returnColor hue] saturation:[returnColor saturation] brightness:MAX(0.88, MIN([returnColor brightness], 0.4)) alpha:1.0];
}

- (BOOL)isFinished {
    return _result != nil;
}

- (NSArray *)mostFrequentColors:(NSInteger)frequentColorsCount of:(UIImage *)image withColorPallete:(ColorPalete)palete {
    NSInteger switchSize;
    switch (palete) {
        case ColorPalete64:
            switchSize = 6;
            [self _initColorMatrixWithMatrixSize:4];
            break;
        case ColorPalete512:
            switchSize = 5;
            [self _initColorMatrixWithMatrixSize:8];
            break;
        case ColorPalete1024:
            switchSize = 4;
            [self _initColorMatrixWithMatrixSize:16];
            break;
        case ColorPalete2048:
            switchSize = 3;
            [self _initColorMatrixWithMatrixSize:32];
            break;

        default:
            return nil;
            break;
    }

    CGImageRef imageRef = image.CGImage;

    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];

    if(!context) {
        return nil;
    }

    if (self.isCancelled) {
        CGContextRelease(context);
        return nil;
    }

    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);

    CGRect rect = CGRectMake(0, 0, width, height);

    // Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);

    // Get a pointer to the data
    unsigned char *newBitmap = (unsigned char *)CGBitmapContextGetData(context);

    // Copy the data and release the memory (return memory allocated with new)
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t bufferLength = bytesPerRow * height;

    [self _resetColorMatrix];

    unsigned char r;
    unsigned char g;
    unsigned char b;
    // unsigned char a;
    // unsigned char t; // brightness

    // NSInteger doubleColorMatrixSize = (__colorMatrixSize * __colorMatrixSize);

    for(int i = 0; !self.isCancelled && i < bufferLength; i += 4) {
        // newBitmap[i] = bitmapData[i];
        // r = newBitmap[i] >> 24;
        // pixel = ((pixelRGBA8)newBitmap[i]);
        r = newBitmap[i + 0] >> switchSize;
        g = newBitmap[i + 1] >> switchSize;
        b = newBitmap[i + 2] >> switchSize;

        __colorMatrix[r][g][b] = __colorMatrix[r][g][b] + 1;
    }

    Address3D *mostRecentColors = malloc(frequentColorsCount * sizeof(Address3D));

    for (int i = 0; i < frequentColorsCount; i++) {
        mostRecentColors[i].x = 0;
        mostRecentColors[i].y = 0;
        mostRecentColors[i].z = 0;
        mostRecentColors[i].w = 0;
    }

    NSInteger currentColorCount = 0;
    for (int i = 0; !self.isCancelled && i < __colorMatrixSize; i++) {
        for (int j = 0; !self.isCancelled && j < __colorMatrixSize; j++) {
            for (int k = 0; !self.isCancelled && k < __colorMatrixSize; k++) {
                currentColorCount = __colorMatrix[i][j][k];
                if (currentColorCount > 0) {
                    for (int t = 0; !self.isCancelled && t < frequentColorsCount; t++) {
                        if (mostRecentColors[t].w < currentColorCount) {
                            // should replace color, so switch
                            for (int l = ((int)frequentColorsCount - 1); l > t; l--) {
                                mostRecentColors[l] = mostRecentColors[l - 1];
                            }
                            mostRecentColors[t].x = i;
                            mostRecentColors[t].y = j;
                            mostRecentColors[t].z = k;
                            mostRecentColors[t].w = currentColorCount;
                            break;
                        }
                    }
                }
            }
        }
    }

    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; !self.isCancelled && i < frequentColorsCount; i++) {
        [array addObject:[self _colorFromAddress3D:mostRecentColors[i]]];
    }

    free(mostRecentColors);
    CGContextRelease(context);

    return array;
}

- (void)_initColorMatrixWithMatrixSize:(NSInteger)matrixSize {
    if (__colorMatrixSize == matrixSize) {
        [self _resetColorMatrix];
        return;
    } else {
        if (__colorMatrix) {
            [self _freeColorMatrix];
        }
        __colorMatrixSize = matrixSize;
    }

    __colorMatrix = malloc(__colorMatrixSize * sizeof(NSInteger**));
    for (int i = 0; !self.isCancelled && i < __colorMatrixSize; i++) {
        __colorMatrix[i] = malloc(__colorMatrixSize * sizeof(NSInteger*));
        for (int j = 0; !self.isCancelled && j < __colorMatrixSize; j++) {
            __colorMatrix[i][j] = malloc(__colorMatrixSize * sizeof(NSInteger));
            for (int k = 0; !self.isCancelled && k < __colorMatrixSize; k++) {
                __colorMatrix[i][j][k] = 0;
            }
        }
    }
}

- (void)_freeColorMatrix {
    for (int i = 0; i < __colorMatrixSize; i++) {
        for (int j = 0; j < __colorMatrixSize; j++) {
            // for (int k = 0; k < __colorMatrixSize; k++) {
            //    __colorMatrix[i][j][k] = 0;
            // }
            free(__colorMatrix[i][j]);
        }
        free(__colorMatrix[i]);
    }
    free(__colorMatrix);
}

- (void)_resetColorMatrix {
    for (int i = 0; i < __colorMatrixSize; i++) {
        for (int j = 0; j < __colorMatrixSize; j++) {
            for (int k = 0; k < __colorMatrixSize; k++) {
                __colorMatrix[i][j][k] = 0;
            }
        }
    }
    __black = 0;
    __white = 0;
}

- (UIColor *)_colorFromAddress3D:(Address3D)a {
    return [UIColor colorWithRed:((CGFloat)a.x) / __colorMatrixSize green:((CGFloat)a.y) / __colorMatrixSize blue:((CGFloat)a.z) / __colorMatrixSize alpha:1.0f];
}

- (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;

    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;

    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);

    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    if(!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }

    if(_bitmapData)free(_bitmapData);
    // Allocate memory for image data
    _bitmapData = (uint32_t *)malloc(bufferLength);

    if(!_bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }

    // Create bitmap context
    context = CGBitmapContextCreate(_bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);    // RGBA

    if(!context) {
        free(_bitmapData);
        NSLog(@"Bitmap context not created");
    }

    CGColorSpaceRelease(colorSpace);

    return context;
}

@end
