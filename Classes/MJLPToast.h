//
//  MJLPToast.h
//  
//
//  Created by 刘鹏i on 2020/7/16.
//  Copyright © 2020 liu. All rights reserved.
//  Toast显示框

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MJLPToast : NSObject
@property (nonatomic, assign) BOOL onlyLatestMessage;///< 只保留最新消息

/// 实例化
+ (instancetype)sharedInstance;

/// 显示底部提示信息
+ (void)toast:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
