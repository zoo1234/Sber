//
//  UIImage+AutoScaleResize_h.h
//  PhotosView
//
//  Created by Никифоров Иван on 13.04.18.
//  Copyright © 2018 Никифоров Иван. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (AutoScaleResize)

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize;

@end
