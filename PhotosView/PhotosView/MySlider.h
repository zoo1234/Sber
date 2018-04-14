//
//  MySlider.h
//  PhotosView
//
//  Created by Никифоров Иван on 14.04.18.
//  Copyright © 2018 Никифоров Иван. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySlider;
@protocol MySliderDelegate

- (void)touchBegin:(MySlider*)slider;
- (void)touchEnd:(MySlider*)slider;

@end

@interface MySlider : UISlider

@property (nonatomic, assign) id <MySliderDelegate> delegate;

@end
