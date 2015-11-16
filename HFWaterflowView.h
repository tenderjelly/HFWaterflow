//
//  HFWaterflowView.h
//  瀑布流
//
//  Created by van on 15/10/22.
//  Copyright © 2015年 van. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    HFWaterflowViewMarginTypeTop,
    HFWaterflowViewMarginTypeBottom,
    HFWaterflowViewMarginTypeLeft,
    HFWaterflowViewMarginTypeRight,
    HFWaterflowViewMarginTypeColumn,  //每一列
    HFWaterflowViewMarginTypeRow,  //每一行
} HFWaterflowViewMarginType;

@class HFWaterflowView,HFWaterflowViewCell;

/**
 *  数据源方法
 */
@protocol HFWaterflowViewDataSource <NSObject>

@required
/**
 *  一共有多少个数据
 */
- (NSUInteger)numberOfCellsInWaterflow:(HFWaterflowView *)waterflowView;
/**
 *  返回对应index的cell数据
 */
- (HFWaterflowViewCell *)waterflowView:(HFWaterflowView *)waterflowView cellAtIndex:(NSUInteger)index;

@optional
/**
 *  一共有多少列
 */
- (NSUInteger)numberOfColumsInWaterflow:(HFWaterflowView *)waterflowView;

@end

/**
 *  代理方法
 */
@protocol HFWaterflowViewDelegate <UIScrollViewDelegate>
@optional
/**
 *  返回对应index的高度
 */
- (CGFloat)waterflowView:(HFWaterflowView *)waterflowView heightAtIndex:(NSUInteger)index;
/**
 *  选中第index行位置的cell
 */
- (void)waterflowView:(HFWaterflowView *)waterflowView didSelectedAtIndex:(NSUInteger)index;
/**
 *  返回间距
 */
- (CGFloat)waterflowView:(HFWaterflowView *)waterflowView marginForType:(HFWaterflowViewMarginType)type;

@end

/**
 *  瀑布流控件
 */
@interface HFWaterflowView : UIScrollView

/**
 *  数据源代理
 */
@property (nonatomic,weak) id<HFWaterflowViewDataSource> dataSource;

/**
 *  代理
 */
@property (nonatomic,weak) id<HFWaterflowViewDelegate> delegate;

/**
 *  刷新数据
 */
- (void)reloadData;

/**
 *  根据标识去缓存池查找可循环利用的cell
 */
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;

/**
 *  cell的宽度
 */
- (CGFloat)cellWidth;


@end
