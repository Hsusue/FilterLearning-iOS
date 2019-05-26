//
//  FilterNameCell.m
//  LearningProject
//
//  Created by Hsusue on 2019/5/23.
//  Copyright © 2019 Hsusue. All rights reserved.
//

#import "FilterNameCell.h"

#import <Masonry.h>

@interface FilterNameCell ()

@property (nonatomic, strong) UILabel *nameLabel;

@end

@implementation FilterNameCell

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.textColor = [UIColor orangeColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}

- (void)setFilterName:(NSString *)filterName {
    _filterName = filterName;
    
    self.nameLabel.text = filterName;
    [self.nameLabel sizeToFit];
}


@end
