//
//  FilterView.m
//  LearningProject
//
//  Created by Hsusue on 2019/5/23.
//  Copyright © 2019 Hsusue. All rights reserved.
//

#import "FilterView.h"
#import "FilterNameCell.h"

#import <Masonry.h>

static NSString *const FilterNameCellID = @"FilterNameCellID";

@interface FilterView ()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, strong) UIButton *unfoldBtn;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UICollectionView *filterNameCollectionView;

@property (nonatomic, strong) NSArray<NSString *> *nameArray;// 中文
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *dict;// 中文到英文的映射

@end

@implementation FilterView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.3f];
    
    self.unfoldBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.unfoldBtn setBackgroundImage:[UIImage imageNamed:@"filter"] forState:UIControlStateNormal];
    [self.unfoldBtn addTarget:self action:@selector(unfoldBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.unfoldBtn];
    [self.unfoldBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-10);
        make.width.height.equalTo(@40);
    }];
    
    self.cancelBtn = [UIButton new];
    [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.cancelBtn];
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(10);
        make.width.height.equalTo(@40);
    }];
}

- (void)unfoldBtnClick {
    self.filterNameCollectionView.hidden = NO;
}

- (void)cancelBtnClick {
    if ([self.delegate respondsToSelector:@selector(filterView:cancelBtnClick:)]) {
        [self.delegate filterView:self cancelBtnClick:self.cancelBtn];
    }
}

#pragma mark - UICollectionViewDataSource
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(100, 40);      // 让每个cell尺寸都不一样
}

// 设置上左下右边界缩进
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    return UIEdgeInsetsMake(kTopMargin + 5, 5, 0, 5);
}

// 返回cell个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.nameArray.count;
}

// 返回cell内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FilterNameCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FilterNameCellID forIndexPath:indexPath];
    cell.filterName = self.nameArray[indexPath.row];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
// 选中某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.filterNameCollectionView.hidden = YES;
    
    if ([self.delegate respondsToSelector:@selector(filterView:chooseFilterName:)]) {
        [self.delegate filterView:self chooseFilterName:self.dict[self.nameArray[indexPath.row]]];
    }
}

#pragma mark -- 懒加载
- (UICollectionView *)filterNameCollectionView {
    if (!_filterNameCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _filterNameCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _filterNameCollectionView.delegate = self;
        _filterNameCollectionView.dataSource = self;
        _filterNameCollectionView.backgroundColor = [UIColor blackColor];
        [_filterNameCollectionView registerClass:[FilterNameCell class] forCellWithReuseIdentifier:FilterNameCellID];
        [self addSubview:_filterNameCollectionView];
        [_filterNameCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        _filterNameCollectionView.hidden = YES;
    }
    return _filterNameCollectionView;
}

- (NSArray *)nameArray {
    if (!_nameArray) {
        _nameArray = @[@"无", @"方框模糊", @"颜色交叉", @"凹凸变形"];
    }
    return _nameArray;
}

- (NSDictionary *)dict {
    if (!_dict) {
        _dict = @{
                  @"方框模糊" : @"CIBoxBlur",
                  @"颜色交叉" : @"CIColorCrossPolynomial",
                  @"凹凸变形" : @"CIBumpDistortion"
                  };
    }
    return _dict;
}

@end
