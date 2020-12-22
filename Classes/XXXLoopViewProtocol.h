//
//  XXXLoopViewProtocol.h
//  Pods
//
//  Created by chong liu on 2020/12/7.
//

#ifndef XXXLoopViewProtocol_h
#define XXXLoopViewProtocol_h

/// 轮播重置
@protocol LoopViewResetProtocol <NSObject>

@required
/// 轮播ItemView会复用，复用前初始化操作，setModel前会被调用
- (void)loopViewResetCurrentLoopItem;

/// 需要手动在@implementation后写@synthesize loopItemIndex;生成set/get方法，或手写set/get方法
@property (nonatomic, assign) NSInteger loopItemIndex;

@end

#endif /* XXXLoopViewProtocol_h */
