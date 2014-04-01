//
//  IBImageBannerScrollView.h
//  ImageBannerScrollView
//
//  Created by Keisuke Karijuku on 2014/03/31.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IBImageBannerScrollView : UIView <UIScrollViewDelegate>
- (void)addBannerImage:(UIImage *)image actionBlock:(void (^)())actionBlock;
- (void)changeBannerImage:(UIImage *)image atIndex:(NSUInteger)index;
- (void)removeBannerImageAtIndex:(NSUInteger)index;
- (void)startAutoScrolling;
- (void)stopAutoScrolling;
@property (nonatomic) BOOL isEnableAutoScrolling;
@end
