//
//  MySlider.m
//  PhotosView
//
//  Created by Никифоров Иван on 14.04.18.
//  Copyright © 2018 Никифоров Иван. All rights reserved.
//

#import "MySlider.h"

@implementation MySlider

- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.delegate touchBegin:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    [self.delegate touchEnd:self];
}

@end
