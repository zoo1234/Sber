//
//  PicturesViewController.h
//  PhotosView
//
//  Created by Никифоров Иван on 11.04.18.
//  Copyright © 2018 Никифоров Иван. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjectiveFlickr.h"
#import "MySlider.h"

@interface PicturesViewController : UIViewController <UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, UICollectionViewDataSource, OFFlickrAPIRequestDelegate, MySliderDelegate> {
    dispatch_queue_t backgroundQueue;
    NSString *myAPIKey;
    NSString *mySecretKey;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *collection;

@end
