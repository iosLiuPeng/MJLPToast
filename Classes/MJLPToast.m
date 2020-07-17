//
//  MJLPToast.m
//  
//
//  Created by 刘鹏i on 2020/7/16.
//  Copyright © 2020 liu. All rights reserved.
//

#import "MJLPToast.h"
#import <UIKit/UIKit.h>

@interface MJLPToast ()
@property (nonatomic, strong) NSMutableArray<UIView *> *arrAleradyDisplay;  ///< 已显示view
@property (nonatomic, strong) NSMutableArray<NSString *> *arrWaitMessage;   ///< 待显示的消息
@end

static MJLPToast *s_Singleton = nil;

@implementation MJLPToast
#pragma mark - Life Cycle
/// 实例化
+ (instancetype)sharedInstance
{
    static dispatch_once_t once_patch;
    dispatch_once(&once_patch, ^() {
        s_Singleton = [[self alloc] init];
    });
    return s_Singleton;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_Singleton = [super allocWithZone:zone];
    });
    
    return s_Singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 初始化变量
        _arrAleradyDisplay = [[NSMutableArray alloc] init];
        _arrWaitMessage = [[NSMutableArray alloc] init];
        
        // 监听屏幕旋转
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

#pragma mark - Toast
/// 显示底部提示信息
+ (void)toast:(NSString *)message
{
    [[MJLPToast sharedInstance] toastMessage:message];
}

/// 显示底部提示信息
- (void)toastMessage:(NSString *)message
{
    if (message.length == 0) {
        return;
    }
    
    // 只显示最新消息
    if (_onlyLatestMessage) {
        for (UIView *aView in _arrAleradyDisplay) {
            [aView removeFromSuperview];
        }
        [_arrAleradyDisplay removeAllObjects];
        [_arrWaitMessage removeAllObjects];
    }
    
    [_arrWaitMessage insertObject:message atIndex:0];
    
    if (_arrWaitMessage.count == 1) {
        [self showNextMessage];
    }
}

/// 显示下一条消息
- (void)showNextMessage
{
    if (_arrWaitMessage.count) {
        NSString *message = _arrWaitMessage.lastObject;
        
        // 创建view
        UIView *view = [self createToastView:message];
        // 更新位置
        [self updateTostView:view offset:0];
        
        if (_arrAleradyDisplay.count) {
            // 移动旧消息
            CGFloat offset = view.bounds.size.height + 10;
            [self moveUpAnimation:offset completion:^{
                // 显示新消息
                [self displayToastView:view];
                
                // 执行下一条
                [self showNextMessage];
            }];
        } else {
            // 显示新消息
            [self displayToastView:view];
        }
    }
}

// 显示新消息
- (void)displayToastView:(UIView *)view
{
    [[self toastContainerView] addSubview:view];
    [_arrAleradyDisplay addObject:view];
    [_arrWaitMessage removeLastObject];
    
    // 3秒后自动消失
    __weak UIView *weakView = view;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakView) {
            [self hiddenAnimation:weakView duration:0.6];
        }
    });
    
    // 当前屏幕一次最多显示3条，立即移除最旧的消息
    if (_arrAleradyDisplay.count > 3) {
        [self hiddenAnimation:_arrAleradyDisplay.firstObject duration:0.2];
    }
}

/// taost的容器视图
- (UIView *)toastContainerView
{
    // 使用keyWindow
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindow *aWindow in [UIApplication sharedApplication].windows.reverseObjectEnumerator.allObjects) {
            if ([aWindow isKeyWindow]) {
                window = aWindow;
                break;
            }
        }
    } else {
        window = [UIApplication sharedApplication].keyWindow;
    }
    
    // keyWindow隐藏的情况
    if (window.isHidden) {
        NSMutableArray *arrDisplay = [[NSMutableArray alloc] init];
        for (UIWindow *aWindow in [UIApplication sharedApplication].windows) {
            if ([aWindow isMemberOfClass:UIWindow.class] &&
                aWindow.hidden == NO &&
                CGRectEqualToRect(aWindow.bounds, [UIScreen mainScreen].bounds)) {
                [arrDisplay addObject:aWindow];
            }
        }
 
        window = arrDisplay.lastObject;
    }
    
    return window;
}

/// 创建toast视图
- (UIView *)createToastView:(NSString *)message
{
    // wrapperView
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    wrapperView.layer.cornerRadius = 6.0;
    
    // label
    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 3;
    label.font = [UIFont systemFontOfSize:16];
    [wrapperView addSubview:label];
        
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [wrapperView addGestureRecognizer:tap];
    
    return wrapperView;
}

/// 移除toast视图
- (void)removeView:(UIView *)view
{
    [view removeFromSuperview];
    [_arrAleradyDisplay removeObject:view];
}

#pragma mark - Action
/// 点击toastView事件
- (void)tapAction:(UITapGestureRecognizer *)tap
{
    [self removeView:tap.view];
}

#pragma mark - 位置
/// 更新tostView位置
- (void)updateTostView:(UIView *)view offset:(CGFloat)offset
{
    // label
    UILabel *label = (UILabel *)view.subviews.firstObject;
    
    // label位置
    CGSize containerSize = [self toastContainerView].bounds.size;
    CGSize labelSize = [label sizeThatFits:CGSizeMake(containerSize.width * 0.7, CGFLOAT_MAX)];
    // 控制高度
    if (labelSize.height > containerSize.height * 0.1) {
        labelSize.height = containerSize.height * 0.1;
    }
    if (labelSize.height < 20) {
        labelSize.height = 20;
    }
    
    NSInteger spacing = 10;
    label.frame = CGRectMake(spacing, spacing, labelSize.width, labelSize.height);
    
    // 底部间距
    CGFloat bottomSpacing = 30;
    // 加上safeArea高度
    if (@available(iOS 11.0, *)) {
        bottomSpacing += [self toastContainerView].safeAreaInsets.bottom;
    }
    
    if (offset) {
        bottomSpacing += offset;
    }
    
    // view位置
    CGSize viewSize = CGSizeMake(labelSize.width + spacing * 2, labelSize.height + spacing * 2);
    view.frame = CGRectMake((containerSize.width - viewSize.width) / 2.0, containerSize.height - viewSize.height - bottomSpacing, viewSize.width, viewSize.height);
}

// 更新所有toastView位置
- (void)updateAllToastView:(CGFloat)staringOffset
{
    CGFloat offset = staringOffset;
    NSArray *arrReverse = [_arrAleradyDisplay reverseObjectEnumerator].allObjects;
    for (UIView *aView in arrReverse) {
        [self updateTostView:aView offset:offset];
        offset += aView.bounds.size.height + 10;
    }
}

#pragma mark - 动画
/// 旧消息上移动画
- (void)moveUpAnimation:(CGFloat)staringOffset completion:(void (^)(void))completion
{
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self updateAllToastView:staringOffset];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

/// 消失动画
- (void)hiddenAnimation:(UIView *)view duration:(CGFloat)duration
{
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        [self.arrAleradyDisplay removeObject:view];
    }];
}

#pragma mark - 屏幕旋转
/// 屏幕旋转
- (void)statusBarOrientationDidChange:(NSNotification *)notification
{
    // 更新位置
    [self updateAllToastView:0];
}

@end
