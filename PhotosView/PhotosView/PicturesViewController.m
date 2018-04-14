//
//  PicturesViewController.m
//  PhotosView
//
//  Created by Никифоров Иван on 11.04.18.
//  Copyright © 2018 Никифоров Иван. All rights reserved.
//

#import "PicturesViewController.h"
#import "extobjc.h"
#import "UIImage+AutoScaleResize.h"

@interface PicturesViewController ()

@property (nonatomic, strong) NSMutableArray *images; //[<urlSmall: ,urlLarge: ,imgSmall: , largeImg: >, ... ]
@property (nonatomic, assign) NSInteger numberOfPicturesForUpdate;
@property (nonatomic, strong) OFFlickrAPIRequest *request;
@property (nonatomic, strong) NSString *groupUrl;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSMutableArray *arrOfPhotosLinks;
@property (nonatomic, strong) NSMutableArray *arrOfPhotosUrl;
@property (nonatomic, assign) BOOL isUpdated;
@property (nonatomic, assign) BOOL animation;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) CGSize sizeLargePhoto;
@property (nonatomic, assign) CGSize sizeSmallPhoto;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, assign) NSInteger numberOfColons;
@property (nonatomic, strong) NSString *lastUpdatePhoto;
@property (weak, nonatomic) IBOutlet MySlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *numberColonsOnSlider;

@end

@implementation PicturesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collection.delegate = self;
    self.collection.dataSource = self;
    
    [self initVariables];
    [self setupApp];
    [self getPhotos];
}


#pragma mark Init variables

- (void)initVariables {
    myAPIKey = @"413d758edfe59d68c4c29c0651ca4fe4";
    mySecretKey = @"b39fcdc1effb45e6";
    self.groupUrl = @"https://www.flickr.com/groups/central/pool/";
    self.images = [NSMutableArray new];
    self.arrOfPhotosUrl = [NSMutableArray new];
    self.arrOfPhotosLinks = [NSMutableArray new];
    self.numberOfPicturesForUpdate = 10;
    backgroundQueue = dispatch_queue_create("com.kvass.PhotosView.PictuiresViewController.bgQueue", NULL);
    self.isUpdated = NO;
    self.numberOfColons = 3;
    self.lastUpdatePhoto = @"";
}


#pragma mark Setup

-(void)setupApp{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(smallImageUpdated:) name:@"com.kvass.PhotosView.PictuiresViewController.smallImageUpdated" object:nil];
    self.imageView.contentMode = UIViewNoIntrinsicMetric;
    [self setupFlickr];
    [self setupSizesImg];
    [self setupSlider];
}

- (void)setupFlickr {
    OFFlickrAPIContext *context = [[OFFlickrAPIContext alloc] initWithAPIKey:myAPIKey sharedSecret:mySecretKey];
    self.request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
    [self.request setDelegate:self];
}

- (void)setupSizesImg {
    self.sizeLargePhoto = self.imageView.frame.size;
    CGFloat border = 5;
    CGFloat widthAllBorders = (self.numberOfColons*2-2)*border;
    CGFloat size = (self.collection.frame.size.width - widthAllBorders)/self.numberOfColons;
    self.sizeSmallPhoto = CGSizeMake(size, size);
}

-(void)setupSlider {
    self.slider.delegate = self;
    self.numberColonsOnSlider.text = [NSString localizedStringWithFormat:@"%ld", (long)self.numberOfColons];
    self.numberColonsOnSlider.hidden = YES;
}


#pragma mark IBActions

- (IBAction)valueSliderChanged:(UISlider *)sender {
    CGFloat border = (self.view.frame.size.width - self.slider.frame.size.width)/2;
    CGFloat xCircle = (self.slider.value - sender.minimumValue)/(sender.maximumValue-sender.minimumValue);
    CGPoint point = CGPointMake(border*(1-xCircle) + self.slider.frame.size.width*xCircle -border*(xCircle) + self.numberColonsOnSlider.frame.size.width*1.2/2, self.slider.frame.origin.y - self.slider.frame.size.height/2);
    self.numberColonsOnSlider.center = point;
    
    NSInteger val = (NSInteger)sender.value;
    if (val != self.numberOfColons){
        self.numberOfColons = val;
        [self setupSizesImg];
        [self.collection reloadData];
        self.numberColonsOnSlider.text = [NSString localizedStringWithFormat:@"%ld", (long)self.numberOfColons];
    }
}


#pragma mark Delegate Slider

-(void)touchBegin:(MySlider *)slider{
    self.numberColonsOnSlider.hidden = NO;
}

- (void)touchEnd:(MySlider *)slider{
    self.numberColonsOnSlider.hidden = YES;
}


#pragma mark Collection Data Source

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = @"MyCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UIImageView *imgView = [UIImageView new];
    [imgView setImage:[(UIImage*)[self.images[indexPath.row] valueForKey:@"imgSmall"] imageByScalingAndCroppingForSize:self.sizeSmallPhoto]];
    
    [cell setBackgroundView:imgView];
    
    return cell;
    
}


#pragma mark Layout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return self.sizeSmallPhoto;
}


#pragma mark Collection Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    self.selectedIndexPath = indexPath;
    if (((NSDictionary*)self.images[indexPath.row]).count == 3){
        self.imageView.image = [(UIImage*)[(NSDictionary*)self.images[indexPath.row] valueForKey:@"imgSmall"] imageByScalingAndCroppingForSize:self.sizeLargePhoto];
        @weakify(self);
        dispatch_async(backgroundQueue, ^(void) {
            @strongify(self);
            [self.images[indexPath.row] setValue:[(UIImage*)([self downloadImgFromUrl:[self.images[indexPath.row] valueForKey:@"urlLarge"]]) imageByScalingAndCroppingForSize:self.sizeLargePhoto] forKey:@"imgLarge"];
            if (self.selectedIndexPath == indexPath){
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
                });
            }
        });
    }else{
        self.imageView.image = [(NSDictionary*)self.images[indexPath.row] valueForKey:@"imgLarge"];
    }
}


#pragma mark Scroll Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger pixelsForUpdate = 20;
    if (scrollView.contentOffset.y < -pixelsForUpdate){
        NSDictionary *dictForGetPhotos = [NSDictionary dictionaryWithObjectsAndKeys:myAPIKey, @"api_key", self.groupId, @"group_id", nil];
        [self.request callAPIMethodWithGET:@"flickr.groups.pools.getPhotos" arguments:dictForGetPhotos];
    }
}


#pragma mark My Methods

- (void)smallImageUpdated:(NSNotification *)notif {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.collection insertItemsAtIndexPaths:@[path]];
        if (self.imageView.image == nil){
            [self collectionView:self.collection didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
    });
}

- (void)setStatusLabel:(NSString*)str {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (!([str isEqualToString:@"Download complete"] || [str isEqualToString:@"No new photos"])){
                self.label.textColor = [UIColor blackColor];
            if (!self.animation){
                self.animation = YES;
                [self animationLabel];
            }
        }else{
            self.label.textColor = [UIColor colorWithDisplayP3Red:0.2 green:0.6 blue:0.2 alpha:1];
            self.animation = NO;
        }
        self.label.text = str;
    });
}

- (void)animationLabel {
    @weakify(self);
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        @strongify(self);
        self.label.alpha = 0.3;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn  animations:^{
            self.label.alpha = 1;
        } completion:^(BOOL finished) {
            if (self.animation) [self animationLabel];
        }];
    }];
}

- (void)downloadLargePhotos {
    for (long i = 0; i<self.images.count; i++){
        if(((NSDictionary*)self.images[i]).count == 3){
            [self setStatusLabel:@"loading Large Photos"];
            @weakify(self);
            dispatch_async(backgroundQueue, ^(void) {
                @strongify(self);
                [self.images[i] setValue:[(UIImage*)([self downloadImgFromUrl:[self.images[i] valueForKey:@"urlLarge"]]) imageByScalingAndCroppingForSize:self.sizeLargePhoto] forKey:@"imgLarge"];
            });
        }
        
    }
    @weakify(self);
    dispatch_async(backgroundQueue, ^(void) {
        @strongify(self);
        if (((NSDictionary*)[self.images lastObject]).count == 3){ //check all Large Photos
            [self downloadLargePhotos];
        }else{
            [self setStatusLabel:@"Download complete"];
        }
    });
}

- (UIImage*)downloadImgFromUrl:(NSString*)url {
    NSData *imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: url]];
    return [UIImage imageWithData:imageData];
}

- (void)getPhotos {
    NSDictionary *dictForLookupGallery = [NSDictionary dictionaryWithObjectsAndKeys:myAPIKey, @"api_key", self.groupUrl, @"url", nil];
    [self.request callAPIMethodWithGET:@"flickr.urls.lookupGroup" arguments:dictForLookupGallery];
}


#pragma mark Flickr Delegate Methods

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary {
    
    if (!self.groupId){ //находим id группы
        [self setStatusLabel:@"get group ID"];
        self.groupId = [inResponseDictionary valueForKeyPath:@"group.id"];
        NSDictionary *dictForGetPhotos = [NSDictionary dictionaryWithObjectsAndKeys:myAPIKey, @"api_key", self.groupId, @"group_id", nil];
        [self.request callAPIMethodWithGET:@"flickr.groups.pools.getPhotos" arguments:dictForGetPhotos];
    }else if (!self.isUpdated){ //находим ссылки на фотки группы (inside id)
        [self setStatusLabel:@"get photos links"];
        self.isUpdated = YES;
        long start = self.arrOfPhotosLinks.count;
//фотки обновляются каждую секунду, так что если пользователь давно не обновлял ему не будут загружаться овер дохера всех пропущенных им фоток, поставим ограничение в 10 новых фотографий (self.numberOfPicturesForUpdate = 10)
        long i =0;
        for (; i<self.numberOfPicturesForUpdate; i++){
            NSString *linkPhoto = [[[inResponseDictionary valueForKeyPath:@"photos.photo"] objectAtIndex:i] valueForKey:@"id"];
            if ([self.lastUpdatePhoto isEqualToString:linkPhoto]){
                break;
            }
            [self.arrOfPhotosLinks addObject:linkPhoto];
        }
        if (self.arrOfPhotosLinks.count > start){
            self.lastUpdatePhoto = self.arrOfPhotosLinks[self.arrOfPhotosLinks.count-i];
            [self.request callAPIMethodWithGET:@"flickr.photos.getSizes" arguments:[NSDictionary dictionaryWithObjectsAndKeys:myAPIKey, @"api_key", self.arrOfPhotosLinks[start], @"photo_id", nil]];
        }else{
            [self setStatusLabel:@"No new photos"];
            self.isUpdated = NO;
        }
    }else{ //находим конечный url фотки (два размера)
        if (self.arrOfPhotosLinks.count > self.arrOfPhotosUrl.count){
            NSArray *path = [inResponseDictionary valueForKeyPath:@"sizes.size"];
            NSInteger quality = 2; //качество фотки 0 - самое лучшее, path.count - самое худшее
            NSString *urlSmall = [path[0] valueForKey:@"source"];
            NSString *urlLarge = [path[path.count-quality] valueForKey:@"source"];
            
            @weakify(self);
            dispatch_async(backgroundQueue, ^(void) {
                @strongify(self);
                [self setStatusLabel:@"load small photos"];
                UIImage *img = [self downloadImgFromUrl: urlSmall];
                [self.images insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:urlSmall, @"urlSmall", urlLarge, @"urlLarge", img, @"imgSmall", nil] atIndex:0];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"com.kvass.PhotosView.PictuiresViewController.smallImageUpdated" object:img];
            });
            
            [self.arrOfPhotosUrl addObject:urlSmall];
        }
        if (self.arrOfPhotosLinks.count == self.arrOfPhotosUrl.count) {
            self.isUpdated = NO;
            [self downloadLargePhotos];
            return;
        }
        [self.request callAPIMethodWithGET:@"flickr.photos.getSizes" arguments:[NSDictionary dictionaryWithObjectsAndKeys:myAPIKey, @"api_key", self.arrOfPhotosLinks[self.arrOfPhotosUrl.count], @"photo_id", nil]];
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError {
    NSLog(@"error %@", inError);
}


#pragma mark Other

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.kvass.PhotosView.PictuiresViewController.smallImageUpdated" object:nil];
}

@end
