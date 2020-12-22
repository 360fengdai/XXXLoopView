//
//  LoopScrollView.h
//  Test
//
//  Created by liuchong on 2017/4/19.
//  Copyright © 2017年 liuchong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoopScrollView;

@protocol LoopViewDelegate <NSObject>
@optional
- (void)loopViewCurrentIndexChange:(NSInteger)currentIndex;//!<当前索引变化才会被调用
- (void)loopViewCurrentIndex:(NSInteger)currentIndex currentView:(UIView *)currentView; //!<后执行（第一个索引也会被调用）
- (void)loopViewLastIndex:(NSInteger)lastIndex lastView:(UIView *)lastView;             //!<先执行
- (void)loopViewHeaderRefresh;//!< 下拉刷新，第一个itemview再下拉触发
- (void)loopViewLoadMore; //!< 加载更多，最后一个itemview再上滑触发

@end

///循环滚动View
@interface XXXLoopView : UIView

@property(nonatomic,strong)LoopScrollView *loopScroll;
@property(nonatomic,assign)id<LoopViewDelegate>delegate;

/**
 设置数据源

 @param dataArray 数据源
 @param isAlwaysLoop 1个数据和两个数据时是否滚动，YES为滚动，NO为不滚动，设置滚动需要数据实现copy方法
 */
- (void)setUpViewsWithArray:(NSArray *)dataArray isAlwaysLoop:(BOOL)isAlwaysLoop;
- (void)loopViewAddDataSourceWithArray:(NSArray *)dataArray;
- (instancetype)initWithItemClassName:(NSString*)className;
- (instancetype)initWithItemClassName:(NSString*)className isVertical:(BOOL)isVertical;
/// 初始化，控件约束后自动适配内部item大小
/// @param className 循环滚动item的类名
/// @param isVertical 是否竖直滚动，默认NO横向滚动
/// @param prohibitLoop 是否禁止轮播，刷视频效果，上滑到最后一个，再滑就触发上拉加载代理，同理在第一个item下拉触发刷新代理
- (instancetype)initWithItemClassName:(NSString*)className isVertical:(BOOL)isVertical prohibitLoop:(BOOL)prohibitLoop;
/// 带Frame参数初始化
- (instancetype)initWithFrame:(CGRect)frame itemClassName:(NSString*)className;
- (instancetype)initWithFrame:(CGRect)frame itemClassName:(NSString*)className isVertical:(BOOL)isVertical;//!< isVertical: YES为垂直滚动, NO为水平滚动
///设置数据源 数据源跟itemClass之间使用KVC对model字段赋值，itemClassName通过setModel接收数据
- (void)setUpViewsWithArray:(NSArray*)dataArray;
/// 设置是否可以手动滑动，默认不可以
- (void)setScrollViewUserInteractionEnabled:(BOOL)isUserInteractionEnabled;
///开启动画滚动, interval: 间隔时间
- (void)startAutoplay:(NSTimeInterval)interval;
/// 开启动画滚动
/// @param interval 间隔时间
/// @param time 滚动速度，默认一秒
- (void)startAutoplay:(NSTimeInterval)interval scrollSpeed:(NSTimeInterval)time;
- (void)stopAutoplay;//!<   结束动画
- (void)loopViewScrollUpManual;//!<  上滑
- (void)loopViewScrollDownManual;//!< 下滑
- (void)loopViewScrollLeftManual;//!< 左滑
- (void)loopViewScrollRightManual;//! < 右滑
///根据索引获取view
/// @param index 索引
- (UIView *)loopViewItemWithIndex:(NSUInteger)index;

@end


