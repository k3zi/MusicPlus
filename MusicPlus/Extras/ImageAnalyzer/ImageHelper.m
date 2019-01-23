/*
 * The MIT License
 *
 * Copyright (c) 2011 Paul Solt, PaulSolt@gmail.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
// 
//  Created by Stas Cherednichenko on 1/10/12.
//  Copyright (c) 2012 JAMG. All rights reserved.
// 

#import "ImageHelper.h"

static uint32_t *bitmapData;

@implementation ImageHelper


+ (unsigned char *) convertUIImageToBitmapRGBA8:(UIImage *) image {
	
	CGImageRef imageRef = image.CGImage;
	
	// Create a bitmap context to draw the uiimage into
	CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];
	
	if(!context) {
		return NULL;
	}
	
	size_t width = CGImageGetWidth(imageRef);
	size_t height = CGImageGetHeight(imageRef);
	
	CGRect rect = CGRectMake(0, 0, width, height);
	
	// Draw image into the context to get the raw image data
	CGContextDrawImage(context, rect, imageRef);
	
	// Get a pointer to the data	
	unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
	
	// Copy the data and release the memory (return memory allocated with new)
	size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
	size_t bufferLength = bytesPerRow * height;
	
	unsigned char *newBitmap = NULL;
	
	if(bitmapData) {
		newBitmap = (unsigned char *)malloc(sizeof(unsigned char) * bytesPerRow * height);
		
		if(newBitmap) {	// Copy the data
			for(int i = 0; i < bufferLength; ++i) {
				newBitmap[i] = bitmapData[i];
			}
		}
		
		free(bitmapData);
		
	} else {
		NSLog(@"Error getting bitmap pixel data\n");
	}
	
	CGContextRelease(context);
	
	return newBitmap;	
}

+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image {
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
	
    if(bitmapData)free(bitmapData);
	// Allocate memory for image data
	bitmapData = (uint32_t *)malloc(bufferLength);
	
	if(!bitmapData) {
		NSLog(@"Error allocating memory for bitmap\n");
		CGColorSpaceRelease(colorSpace);
		return NULL;
	}
	
	// Create bitmap context
	context = CGBitmapContextCreate(bitmapData, 
									width, 
									height, 
									bitsPerComponent, 
									bytesPerRow, 
									colorSpace, 
                                    kCGImageAlphaPremultipliedLast);	// RGBA
	
	if(!context) {
		free(bitmapData);
		NSLog(@"Bitmap context not created");
	}
	
	CGColorSpaceRelease(colorSpace);
	
	return context;	
}

+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer 
								withWidth:(int) width
							   withHeight:(int) height {
	
	
	size_t bufferLength = width * height * 4;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
	size_t bitsPerComponent = 8;
	size_t bitsPerPixel = 32;
	size_t bytesPerRow = 4 * width;
	
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	if(colorSpaceRef == NULL) {
		NSLog(@"Error allocating color space");
		CGDataProviderRelease(provider);
		return nil;
	}
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	CGImageRef iref = CGImageCreate(width, 
									height, 
									bitsPerComponent, 
									bitsPerPixel, 
									bytesPerRow, 
									colorSpaceRef, 
									bitmapInfo, 
									provider,	// data provider
									NULL,		// decode
									YES,			// should interpolate
									renderingIntent);
    
	uint32_t* pixels = (uint32_t*)malloc(bufferLength);
	
	if(pixels == NULL) {
		NSLog(@"Error: Memory not allocated for bitmap");
		CGDataProviderRelease(provider);
		CGColorSpaceRelease(colorSpaceRef);
		CGImageRelease(iref);		
		return nil;
	}
	
	CGContextRef context = CGBitmapContextCreate(pixels, 
												 width, 
												 height, 
												 bitsPerComponent, 
												 bytesPerRow, 
												 colorSpaceRef,
                                                 bitmapInfo);
	
	if(context == NULL) {
		NSLog(@"Error context not created");
		free(pixels);
	}
	
	UIImage *image = nil;
	if(context) {
		
		CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
		
		CGImageRef imageRef = CGBitmapContextCreateImage(context);
		
		// Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
		if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
			float scale = [[UIScreen mainScreen] scale];
			image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
		} else {
			image = [UIImage imageWithCGImage:imageRef];
		}
		
		CGImageRelease(imageRef);	
		CGContextRelease(context);	
	}
	
	CGColorSpaceRelease(colorSpaceRef);
	CGImageRelease(iref);
	CGDataProviderRelease(provider);
	
	if(pixels) {
		free(pixels);
	}	
	return image;
}


struct Address3D {
    NSInteger x;
    NSInteger y;
    NSInteger z;
    NSInteger w;
};

typedef struct Address3D Address3D;

static NSInteger __colorMatrixSize = 0;
static NSInteger ***__colorMatrix = nil;
static NSInteger __black = 0;
static NSInteger __white = 0;



+ (void)_freeColorMatrix {
    for (int i = 0; i < __colorMatrixSize; i++) {
        for (int j = 0; j < __colorMatrixSize; j++) {
            // for (int k = 0; k < __colorMatrixSize; k++) {
            //    __colorMatrix[i][j][k] = 0;
            // }
            free(__colorMatrix[i][j]);
        }
        free(*__colorMatrix[i]);
    }
    free(**__colorMatrix);
}

+ (void)_resetColorMatrix {
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

+ (void)_initColorMatrixWithMatrixSize:(NSInteger)matrixSize {
    if (__colorMatrixSize == matrixSize) {
        [self _resetColorMatrix];
        return;
    } else {
        if (__colorMatrix) {
            [self _freeColorMatrix];
        }
        __colorMatrixSize = matrixSize;
    }
    
    __colorMatrix = malloc(__colorMatrixSize * sizeof(NSInteger));
    for (int i = 0; i < __colorMatrixSize; i++) {
        __colorMatrix[i] = malloc(__colorMatrixSize * sizeof(NSInteger));
        for (int j = 0; j < __colorMatrixSize; j++) {
            __colorMatrix[i][j] = malloc(__colorMatrixSize * sizeof(NSInteger));
            for (int k = 0; k < __colorMatrixSize; k++) {
                __colorMatrix[i][j][k] = 0;
            }   
        }   
    }
}

+ (UIColor *)_colorFromAddress3D:(Address3D)a {
    return [UIColor colorWithRed:((CGFloat)a.x) / __colorMatrixSize green:((CGFloat)a.y) / __colorMatrixSize blue:((CGFloat)a.z) / __colorMatrixSize alpha:1.0f];
}

+ (NSArray *)mostFrequentColors:(NSInteger)frequentColorsCount of:(UIImage *)image withColorPallete:(ColorPalete)palete {
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
    
    for(int i = 0; i < bufferLength; i += 4) {
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
    for (int i = 0; i < __colorMatrixSize; i++) {
        for (int j = 0; j < __colorMatrixSize; j++) {
            for (int k = 0; k < __colorMatrixSize; k++) {
                currentColorCount = __colorMatrix[i][j][k];
                if (currentColorCount > 0) {
                    for (int t = 0; t < frequentColorsCount; t++) {
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
    for (int i = 0; i < frequentColorsCount; i++) {
        [array addObject:[self _colorFromAddress3D:mostRecentColors[i]]];
    }
    
    free(mostRecentColors);
	CGContextRelease(context);
    
    return array;
    
}

@end
