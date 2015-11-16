//
//  HFWaterflowView.m
//  瀑布流
//
//  Created by van on 15/10/22.
//  Copyright © 2015年 van. All rights reserved.
//

#import "HFWaterflowView.h"
#import "HFWaterflowViewCell.h"

#define HFWaterflowViewDefaultCellH 70;
#define HFWaterflowViewDefaultColumns 3;
#define HFWaterflowViewDefaultMargin 8;

@interface HFWaterflowView ()
/**
 *  所有cell的frame数据
 */
@property (nonatomic,strong)  NSMutableArray *cellFrames;
/**
 *  正在展示的cell
 */
@property (nonatomic,strong)  NSMutableDictionary *displayingCells;
/**
 *  缓存池 （用set存放离开屏幕的cell）
 */
@property (nonatomic,strong) NSMutableSet *reusableCells;
@end

@implementation HFWaterflowView
- (NSMutableArray *)cellFrames
{
    if (_cellFrames == nil) {
        self.cellFrames = [NSMutableArray array];
    }
    return _cellFrames;
}
- (NSMutableDictionary *)displayingCells
{
    if (_displayingCells == nil) {
        self.displayingCells = [NSMutableDictionary dictionary];
    }
    return _displayingCells;
}

/**
 *  刷新数据
 */
- (void)reloadData
{
    // 清空之前的所有数据
    // 移除正在正在显示cell
    [self.displayingCells.allValues makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.displayingCells removeAllObjects];
    [self.cellFrames removeAllObjects];
    [self.reusableCells removeAllObjects];
    
//    cell的总数
    NSInteger numberOfCells = [self.dataSource numberOfCellsInWaterflow:self];
//    总列数
    NSInteger numberOfColumns = [self numberOfColumn];
    
    CGFloat topM = [self marginForType:HFWaterflowViewMarginTypeTop];
    CGFloat bottomM = [self marginForType:HFWaterflowViewMarginTypeBottom];
    CGFloat leftM = [self marginForType:HFWaterflowViewMarginTypeLeft];
    CGFloat RightM = [self marginForType:HFWaterflowViewMarginTypeRight];
    CGFloat columnM = [self marginForType:HFWaterflowViewMarginTypeColumn];
    CGFloat rowM = [self marginForType:HFWaterflowViewMarginTypeRow];
    
//    cell宽度
    CGFloat cellW = (self.bounds.size.width - leftM - RightM - (numberOfColumns - 1)*columnM) / numberOfColumns;
    
//    用一个C语言数组存放所有最大的Y值
    CGFloat maxYOfColumns[numberOfColumns];
    for (int i = 0; i < numberOfColumns; i++) {
        maxYOfColumns[i] = 0.0;
    }
    
//    计算所有的cell的frame
    for (int i = 0; i < numberOfCells; i++) {
//        cell所处在第几列(最短那列)
        NSUInteger cellColumn = 0;
//        cell所处列的最大Y值（最短那列的最大Y值）
        CGFloat maxYOfCellColumn = maxYOfColumns[cellColumn];
        
        for (int j = 0; j < numberOfColumns; j++) {
            if (maxYOfColumns[j] < maxYOfCellColumn) {
//                找出最短列
                cellColumn = j;
//                找出最短列的最大Y值
                maxYOfCellColumn = maxYOfColumns[j];
            }
        }
        
//        询问代理i位置cell的高度
        CGFloat cellH = [self heightAtIndex:i];
        
//        cell的位置
        CGFloat cellX = leftM + (cellW + columnM) * cellColumn;
        
        CGFloat cellY = 0;
        if (maxYOfCellColumn == 0) { //首行
            cellY = topM;
        } else {
            cellY = maxYOfCellColumn + rowM;
        }
        
        CGRect cellFrame = CGRectMake(cellX, cellY, cellW, cellH);
        [self.cellFrames addObject:[NSValue valueWithCGRect:cellFrame]];
//        更新最短那一行的最大Y值
        maxYOfColumns[cellColumn] = CGRectGetMaxY(cellFrame);
        
    }
    // 设置contentSize
    CGFloat contentH = maxYOfColumns[0];
    for (int j = 1; j<numberOfColumns; j++) {
        if (maxYOfColumns[j] > contentH) {
            contentH = maxYOfColumns[j];
        }
    }
    contentH += bottomM;
    self.contentSize = CGSizeMake(0, contentH);
    
}
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [self reloadData];
}
/**
 *  在UIScrollView里 每次移动都会调用这个方法
 */
- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    想数据源索要对应位置的cell
    NSUInteger numberOfCells = self.cellFrames.count;
    for (int i = 0; i < numberOfCells; i++) {
        
//        取出i位置的frame
        CGRect cellFrame = [self.cellFrames[i] CGRectValue];
        
//        优先从字典中取出i位置的cell
        HFWaterflowViewCell *cell = self.displayingCells[@(i)];
//
//        判断cell是不是在屏幕上
        if ([self isInScreen:cellFrame]) { //在屏幕上
            if (cell == nil) {
                cell = [self.dataSource waterflowView:self cellAtIndex:i];
                cell.frame = cellFrame;
                [self addSubview:cell];
                
//                存放到字典中
                self.displayingCells[@(i)] = cell;
            }
        } else { //不在屏幕上
            if (cell) {
//                清空字典和uiview的不用的cell
                [cell removeFromSuperview];
                [self.displayingCells removeObjectForKey:@(i)];
                
//                存放进缓存池
                [self.reusableCells addObject:cell];
            }
        }
    }
//    NSLog(@"%d",self.displayingCells.count);
}
#pragma mark - 私有方法
/**
 *  判断一个cell是否显示在屏幕上
 */
- (BOOL)isInScreen:(CGRect)frame
{
    return (CGRectGetMaxY(frame) > self.contentOffset.y) && (CGRectGetMinY(frame) < self.contentOffset.y + self.bounds.size.height);
}

/**
 *  根据type取出间距
 */
- (CGFloat)marginForType:(HFWaterflowViewMarginType)type
{
    if ([self.delegate respondsToSelector:@selector(waterflowView:marginForType:)]) {
        return [self.delegate waterflowView:self marginForType:type];
    }else
    {
        return HFWaterflowViewDefaultMargin;
    }
}
/**
 *  算出多少列
 */
- (NSUInteger)numberOfColumn
{
    if ([self.dataSource respondsToSelector:@selector(numberOfColumsInWaterflow:)]) {
        return [self.dataSource numberOfColumsInWaterflow:self];
    }else
    {
        return HFWaterflowViewDefaultColumns;
    }
}
/**
 *  返回cell的高度
 */
- (CGFloat)heightAtIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(waterflowView:heightAtIndex:)]) {
        return [self.delegate waterflowView:self heightAtIndex:index];
    }else
    {
        return HFWaterflowViewDefaultCellH;
    }
}
#pragma mark - 公共方法
/**
 *  cell的宽度
 */
- (CGFloat)cellWidth
{
    // 总列数
    NSInteger numberOfColumns = [self numberOfColumn];
    CGFloat leftM = [self marginForType:HFWaterflowViewMarginTypeLeft];
    CGFloat rightM = [self marginForType:HFWaterflowViewMarginTypeRight];
    CGFloat columnM = [self marginForType:HFWaterflowViewMarginTypeColumn];
    return (self.bounds.size.width - leftM - rightM - (numberOfColumns - 1) * columnM) / numberOfColumns;
}
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    __block HFWaterflowViewCell *reusableCell = nil;
    
    [self.reusableCells enumerateObjectsUsingBlock:^(HFWaterflowViewCell *cell, BOOL *stop) {
        if ([cell.identifier isEqualToString:identifier]) {
            reusableCell = cell;
            *stop = YES;
        }
    }];
    
    if (reusableCell) { // 从缓存池中移除
        [self.reusableCells removeObject:reusableCell];
    }
    return reusableCell;
}
#pragma mark - 事件处理
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self.delegate respondsToSelector:@selector(waterflowView:didSelectedAtIndex:)]) return;
    
    // 获得触摸点
    UITouch *touch = [touches anyObject];
    //    CGPoint point = [touch locationInView:touch.view];
    CGPoint point = [touch locationInView:self];
    
    __block NSNumber *selectIndex = nil;
    [self.displayingCells enumerateKeysAndObjectsUsingBlock:^(id key, HFWaterflowViewCell *cell, BOOL *stop) {
        if (CGRectContainsPoint(cell.frame, point)) {
            selectIndex = key;
            *stop = YES;
        }
    }];
    
    if (selectIndex) {
        [self.delegate waterflowView:self didSelectedAtIndex:selectIndex.unsignedIntegerValue];
    }
}
@end
