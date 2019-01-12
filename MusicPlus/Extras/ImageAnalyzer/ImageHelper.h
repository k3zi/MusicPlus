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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum ColorPalete {
    ColorPalete64,
    ColorPalete512
};
typedef enum ColorPalete ColorPalete;

@interface ImageHelper : NSObject {
	
}

+ (unsigned char *) convertUIImageToBitmapRGBA8:(UIImage *)image;

+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef)image;

+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *)buffer 
								withWidth:(int)width
							   withHeight:(int)height;

+ (NSArray *)mostFrequentColors:(NSInteger)frequentColorsCount
                             of:(UIImage *)image
               withColorPallete:(ColorPalete)palete;

@end
