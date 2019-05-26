//
//  Adaption.h
//  LearningProject
//
//  Created by Hsusue on 2019/5/24.
//  Copyright © 2019 Hsusue. All rights reserved.
//

#ifndef Adaption_h
#define Adaption_h

// 判断是否为iPhone x 或者 xs
#define iPhoneX [[UIScreen mainScreen] bounds].size.width == 375.0f && [[UIScreen mainScreen] bounds].size.height == 812.0f
// 判断是否为iPhone xr 或者 xs max
#define iPhoneXR [[UIScreen mainScreen] bounds].size.width == 414.0f && [[UIScreen mainScreen] bounds].size.height == 896.0f
// 是全面屏手机
#define isFullScreen (iPhoneX || iPhoneXR)

// 全面屏适配 适配
// 状态栏高度
#define kStateBarHeight (isFullScreen ? 44.0 : 20.0)
// 导航栏高度
#define kNavigationBarHeight (kStateBarHeight + 44.0)
// 底部tabbar高度
#define kTabBarHeight (isFullScreen ? (49.0+34.0) : 49.0)
// 底部间距
#define kBottomMargin (isFullScreen ? 34.f : 0)
// 顶部间距
#define kTopMargin (isFullScreen ? 24.f : 0)

//也可以参照这种方式 通过对比像素分辨率定义出所有的全面屏手机
#define iPhone6P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)

#define KScreenWidth  [UIScreen mainScreen].bounds.size.width
#define KScreenHeight  [UIScreen mainScreen].bounds.size.height


#endif /* Adaption_h */
