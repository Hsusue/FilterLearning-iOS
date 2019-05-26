//
//  FilterView.h
//  LearningProject
//
//  Created by Hsusue on 2019/5/23.
//  Copyright © 2019 Hsusue. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FilterView;

@protocol FilterViewDelegate <NSObject>

@optional

- (void)filterView:(FilterView *)filterView chooseFilterName:(NSString *)filterName;

- (void)filterView:(FilterView *)filterView cancelBtnClick:(UIButton *)cancelBtn;

@end

@interface FilterView : UIView

@property (nonatomic, weak) id<FilterViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
