//
//  IBImageBannerScrollView.m
//  ImageBannarScrollView
//
//  Created by Keisuke Karijuku on 2014/03/31.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "IBImageBannerScrollView.h"


@interface IBGradientView : UIView
@property (nonatomic) CGFloat gradientHeight;
@end

@implementation IBGradientView

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setGradientHeight:(CGFloat)gradientHeight {
    _gradientHeight = gradientHeight;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    CGContextAddRect(context, self.frame);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {
        0.0f, 0.0f, 0.0f, 0.5f,
        0.0f, 0.0f, 0.0f, 0.0f
    };
    CGFloat locations[] = { 0.0f, 1.0f };
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    CGGradientRef gradientRef =
    CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, count);
    
    CGRect frame = self.bounds;
    CGPoint startPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame) - _gradientHeight);
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
}

@end



@interface IBImageBannerScrollView ()
@property (strong, nonatomic) IBGradientView *gradientView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSArray *imageViews;
@property (strong, nonatomic) NSArray *actionBlocks;
@property (strong, nonatomic) NSTimer *scrollTimer;
@end

@implementation IBImageBannerScrollView

- (id)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDidTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.bounces = YES;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        _gradientView = [[IBGradientView alloc] init];
        [self addSubview:_gradientView];
        
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.userInteractionEnabled = NO;
        [self addSubview:_pageControl];
        
        _imageViews = @[];
        _actionBlocks = @[];
        
        [self startScrollTimer];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    
    _imageViews = nil;
    _actionBlocks = nil;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.bounds;
    
    _scrollView.frame = rect;
    
    _gradientView.frame = rect;
    _gradientView.gradientHeight = CGRectGetHeight(rect) / 4.0f;
    
    _pageControl.center = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect) - 10.0f);
    
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(rect) * _imageViews.count, CGRectGetHeight(rect));
    NSUInteger count = 0;
    for (UIImageView *imageView in _imageViews) {
        CGFloat positionX = count * CGRectGetWidth(rect);
        imageView.frame = CGRectMake(positionX, 0.0f, CGRectGetWidth(rect), CGRectGetHeight(rect));
        ++count;
    }
}

- (void)addBannerImage:(UIImage *)image actionBlock:(void (^)())actionBlock {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_scrollView addSubview:imageView];
    
    _imageViews = [_imageViews arrayByAddingObject:imageView];
    if (actionBlock) {
        _actionBlocks = [_actionBlocks arrayByAddingObject:actionBlock];
    }
    else {
        _actionBlocks = [_actionBlocks arrayByAddingObject:[NSNull null]];
    }
    
    [self setNeedsLayout];
    
    ++_pageControl.numberOfPages;
    if (_pageControl.numberOfPages == 1) {
        _pageControl.hidden = YES;
    }
    else {
        _pageControl.hidden = NO;
    }
}

- (void)changeBannerImage:(UIImage *)image atIndex:(NSUInteger)index {
    if (index >= _imageViews.count) {
        return;
    }
    
    UIImageView *imageView = _imageViews[index];
    imageView.image = image;
}

- (void)removeBannerImageAtIndex:(NSUInteger)index {
    if (index >= _imageViews.count) {
        return;
    }
    
    UIImageView *imageView = _imageViews[index];
    [imageView removeFromSuperview];
    NSMutableArray *tmpImageViews = [NSMutableArray arrayWithArray:_imageViews];
    [tmpImageViews removeObject:imageView];
    _imageViews = tmpImageViews.copy;
    
    NSInteger numberOfPages = _pageControl.numberOfPages;
    NSInteger currentPages = _pageControl.currentPage;
    if (currentPages < numberOfPages) {
        --_pageControl.currentPage;
    }
    --_pageControl.numberOfPages;
    
    [self setNeedsLayout];
}

- (void)startAutoScrolling {
    [self startScrollTimer];
}

- (void)stopAutoScrolling {
    [self stopScrollTimer];
}

#pragma mark Property
- (void)setIsEnableAutoScrolling:(BOOL)isEnableAutoScrolling {
    _isEnableAutoScrolling = isEnableAutoScrolling;
    
    if (isEnableAutoScrolling) {
        [self startAutoScrolling];
    }
    else {
        [self stopAutoScrolling];
    }
}

#pragma mark NSTimer
- (void)timerFired:(NSTimer *)timer {
    CGPoint offset = _scrollView.contentOffset;
    CGRect rect = self.bounds;
    NSUInteger positionX = offset.x / CGRectGetWidth(rect);
    CGFloat destinationPositionX = (positionX + 1) * CGRectGetWidth(rect);
    CGRect destinationRect = CGRectMake(destinationPositionX, 0.0f, CGRectGetWidth(rect), CGRectGetHeight(rect));
    
    [_scrollView scrollRectToVisible:destinationRect animated:YES];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect rect = self.bounds;
    
    NSUInteger index = offset.x / CGRectGetWidth(rect);
    _pageControl.currentPage = index;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect rect = self.bounds;
    
    NSUInteger index = offset.x / CGRectGetWidth(rect);
    _pageControl.currentPage = index;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopScrollTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self startScrollTimer];
}

#pragma mark NSTimer
- (void)startScrollTimer {
    if (!_scrollTimer) {
        _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    }
}

- (void)stopScrollTimer {
    if (_scrollTimer) {
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
}

#pragma mark UITapGestureRecognizer
- (void)scrollViewDidTap:(UIGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:_scrollView];
    CGRect rect = self.bounds;
    
    NSUInteger index = point.x / CGRectGetWidth(rect);
    
    void (^actionBlock)() = [_actionBlocks objectAtIndex:index];
    if (actionBlock && ![actionBlock isEqual:[NSNull null]]) {
        actionBlock();
    }
}


@end







