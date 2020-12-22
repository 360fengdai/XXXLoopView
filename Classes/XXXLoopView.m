//
//  LoopScrollView.m
//  Test
//
//  Created by liuchong on 2017/4/19.
//  Copyright © 2017年 liuchong. All rights reserved.
//

#import "XXXLoopView.h"
#import "XXXLoopViewProtocol.h"

typedef enum : NSUInteger {
    CountTypeZone,
    CountTypeOne,
    CountTypeTwo,
    CountTypeThreeOrMore,
} XXXLoopViewCountType;

typedef enum : NSUInteger {
    SlidingDirectionUp,
    SlidingDirectionLeft,
    SlidingDirectionDown,
    SlidingDirectionRight,
} SlidingDirection;

@protocol LoopScrollViewDelegate <NSObject>

- (void)loopScrollViewCurrentIndexChange:(NSInteger)currentIndex;//!< 索引变化才会被调用
- (void)loopScrollViewLastIndex:(NSInteger)lastIndex lastView:(UIView *)lastView;//!<   先执行
- (void)loopScrollViewCurrentIndex:(NSInteger)currentIndex currentView:(UIView *)currentView;//!<   后执行
- (void)loopSrcollViewHeaderRefresh;//!< 下拉刷新，第一个itemview再下拉触发
- (void)loopSrcollViewLoadMore; //!< 加载更多，最后一个itemview再上滑触发

@end

@interface XXXLoopView ()<UIScrollViewDelegate,LoopScrollViewDelegate>

@property (nonatomic, assign) CGRect sframe;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@interface LoopScrollItemView : UIView

@property (nonatomic, strong) id model;
@property (nonatomic, strong) UIView<LoopViewResetProtocol> *contentView;
@property (nonatomic, assign) CGRect standardFrame;
@property (nonatomic, assign) NSInteger loopItemIndex;

@end

@implementation LoopScrollItemView

- (instancetype)initWithContentView:(UIView<LoopViewResetProtocol> *)contentView {
    self = [super init];
    if (self) {
        self.contentView = contentView;
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)setLoopItemIndex:(NSInteger)loopItemIndex {
    _loopItemIndex = loopItemIndex;
    if ([self.contentView respondsToSelector:@selector(setLoopItemIndex:)]) {
        [self.contentView setValue:@(_loopItemIndex) forKey:@"loopItemIndex"];
    }
}

- (void)setContentView:(UIView<LoopViewResetProtocol> *)contentView {
    _contentView = contentView;
    [self addSubview:_contentView];
    _contentView.frame = self.standardFrame;
    
}
- (void)setModel:(id)model {
    _model = model;
    [self.contentView setValue:model forKey:@"model"];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.standardFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.contentView.frame = self.standardFrame;
}


@end

@interface LoopScrollView : UIScrollView<UIScrollViewDelegate> {
    NSMutableArray *_dataArray;
    CGFloat _width;
    CGFloat _height;
    NSTimer *_loopTimer;
    LoopScrollItemView *_firstLoopView;//!< 第一个传入的View的载体View
    LoopScrollItemView *_secondLoopView;
    LoopScrollItemView *_thirdLoopView;
    UIView<LoopViewResetProtocol> *_firstItemView;//!< 第一个传入的View
    UIView<LoopViewResetProtocol> *_secondItemView;
    UIView<LoopViewResetProtocol> *_thirdItemView;
    BOOL _prohibitLoop; //!< 阻止循环滚动
    XXXLoopViewCountType _countType;
}

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isAutoScroll;
@property (nonatomic, assign) NSInteger currentIndex;//!< 当前索引，从0开始，页面显示的数值为索引+1
@property (nonatomic, assign) id<LoopScrollViewDelegate>loopDelegate;
@property (nonatomic, assign) BOOL isVertical;       //!< 是否垂直显示，YES垂直显示，NO横向显示
@property (nonatomic, assign) NSTimeInterval timeSpeed;
@property (nonatomic, assign) BOOL isScrolling; //!< 是否正在滚动

@end

@implementation LoopScrollView

- (void)removeFromSuperview {
    [super removeFromSuperview];
}

- (instancetype)initWithItemViewClassName:(NSString *)className {
    return [self initWithItemViewClassName:className isVertical:NO];
}
- (instancetype)initWithItemViewClassName:(NSString*)className isVertical:(BOOL)isVertical {
    return [self initWithItemViewClassName:className isVertical:isVertical prohibitLoop:NO];
}
- (instancetype)initWithItemViewClassName:(NSString*)className isVertical:(BOOL)isVertical prohibitLoop:(BOOL)prohibitLoop {
    self = [super init];
    if (self) {
        _prohibitLoop = prohibitLoop;
        _isVertical = isVertical;
        self.userInteractionEnabled = YES;
        self.bounces = NO;
        self.scrollsToTop = NO;
        self.pagingEnabled = YES;
        _dataArray = [[NSMutableArray alloc] init];
        [self setUpSubViewsWithItemClassName:className];
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame itemViewClassName:(NSString *)className {
    self = [super initWithFrame:frame];
    if (self) {
        _isVertical = NO;
        self.userInteractionEnabled = NO;
        self.bounces = NO;
        self.scrollsToTop = NO;
        self.pagingEnabled = YES;
        _dataArray = [[NSMutableArray alloc] init];
        [self setUpSubViewsWithItemClassName:className];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame itemViewClassName:(NSString *)className isVertical:(BOOL)isVertical {
    self = [super initWithFrame:frame];
    if (self) {
        self.bounces = NO;
        self.userInteractionEnabled = NO;
        self.scrollsToTop = NO;
        self.pagingEnabled = YES;
        _isVertical = isVertical;
        _dataArray = [[NSMutableArray alloc] init];
        [self setUpSubViewsWithItemClassName:className];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (_width && _width == self.bounds.size.width && _height && _height == self.bounds.size.height) {
        return;
    }
    _width = self.bounds.size.width;
    _height = self.bounds.size.height;
    [self setUpSubViewFrame];
}

- (void)setUpSubViewsWithItemClassName:(NSString *)className {
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    Class item = NSClassFromString(className);
    if (![item isSubclassOfClass:[UIView class]]) {
        NSLog(@"传入类名不是UIView类或其子类的类名");
        return;
    }
    
    _firstItemView = [[item alloc] init];
    _secondItemView = [[item alloc] init];
    _thirdItemView = [[item alloc] init];
    _firstLoopView = [[LoopScrollItemView alloc] initWithContentView:_firstItemView];
    _secondLoopView = [[LoopScrollItemView alloc] initWithContentView:_secondItemView];
    _thirdLoopView = [[LoopScrollItemView alloc] initWithContentView:_thirdItemView];
    [self addSubview:_firstLoopView];
    [self addSubview:_secondLoopView];
    [self addSubview:_thirdLoopView];
    [self setUpSubViewFrame];
}

- (void)setUpSubViewFrame {
    if (!_isVertical) {
        if (_dataArray.count == 0||_dataArray.count == 1) {
            self.contentSize = CGSizeMake(_width + 0.5, _height);
            self.contentOffset = CGPointMake(0, 0);
        }else if(_dataArray.count == 2){
            self.contentSize = CGSizeMake(_width * 2, _height);
            self.contentOffset = CGPointMake(0, 0);
        }else{
            self.contentSize = CGSizeMake(_width * 3, _height);
            self.contentOffset = _prohibitLoop?CGPointZero:CGPointMake(_width, 0);
        }
        _firstLoopView.frame = CGRectMake(0, 0, _width, _height);
        _secondLoopView.frame = CGRectMake(_width, 0, _width, _height);
        _thirdLoopView.frame = CGRectMake(_width * 2, 0, _width, _height);
    }else{
        if (_dataArray.count == 0||_dataArray.count == 1) {
            self.contentSize = CGSizeMake(_width, _height + 0.5);
            self.contentOffset = CGPointMake(0, 0);
        }else if(_dataArray.count == 2){
            self.contentSize = CGSizeMake(_width, _height * 2);
            self.contentOffset = CGPointMake(0, 0);
        }else{
            self.contentSize = CGSizeMake(_width, _height*3);
            self.contentOffset = _prohibitLoop?CGPointZero:CGPointMake(0, _height);
        }
        _firstLoopView.frame = CGRectMake(0, 0, _width, _height);
        _secondLoopView.frame = CGRectMake(0, _height, _width, _height);
        _thirdLoopView.frame = CGRectMake(0, _height * 2, _width, _height);
    }
}

- (void)loopScrollViewWithArray:(NSArray *)dataArray isAlwaysLoop:(BOOL)isAlwaysLoop isReset:(BOOL)isReset {
    if (isReset) {
        if ([_firstLoopView.contentView respondsToSelector:@selector(loopViewResetCurrentLoopItem)]) {
            [_firstLoopView.contentView loopViewResetCurrentLoopItem];
        }
        if ([_secondLoopView.contentView respondsToSelector:@selector(loopViewResetCurrentLoopItem)]) {
            [_secondLoopView.contentView loopViewResetCurrentLoopItem];
        }
        if ([_thirdLoopView.contentView respondsToSelector:@selector(loopViewResetCurrentLoopItem)]) {
            [_secondLoopView.contentView loopViewResetCurrentLoopItem];
        }
    }
    [_dataArray removeAllObjects];
    self.currentPage = 1;
    if (dataArray.count == 0)_countType = CountTypeZone;else if (dataArray.count == 1)_countType = CountTypeOne;else if (dataArray.count == 2)_countType = CountTypeTwo;else _countType = CountTypeThreeOrMore;
    if (isAlwaysLoop) {
        NSArray *sourceArray;
        if (dataArray.count==1 && [dataArray.firstObject respondsToSelector:@selector(copy)]) {
            sourceArray = @[dataArray.firstObject, [dataArray.firstObject copy], [dataArray.firstObject copy]];
        } else if (dataArray.count == 2 && [dataArray.firstObject respondsToSelector:@selector(copy)] && [[dataArray objectAtIndex:1] respondsToSelector:@selector(copy)]){
            sourceArray = @[dataArray.firstObject, [dataArray objectAtIndex:1], [dataArray.firstObject copy], [[dataArray objectAtIndex:1] copy]];
        } else {
            sourceArray = dataArray;
        }
        [_dataArray addObjectsFromArray:sourceArray];
    } else {
        [_dataArray addObjectsFromArray:dataArray];
    }
    self.currentIndex = 0;
    self.bounces = NO;
    if (_dataArray.count == 0) {
        self.contentSize = CGSizeMake(_width, _height);
        self.contentOffset = CGPointMake(0, 0);
    } else if (_dataArray.count == 1){
        self.contentSize = CGSizeMake(_width, _height);
        self.contentOffset = CGPointMake(0, 0);
        _firstLoopView.model = _dataArray.firstObject;
        _firstLoopView.loopItemIndex = 0;
        self.bounces = YES;
    } else if (_dataArray.count == 2){
        if (!_isVertical) {
            self.contentSize = CGSizeMake(_width * 2, _height);
            self.contentOffset = CGPointMake(0, 0);
            _firstLoopView.model = _dataArray.firstObject;
            _secondLoopView.model = [_dataArray objectAtIndex:1];
        } else {
            self.contentSize = CGSizeMake(_width, _height * 2);
            self.contentOffset = CGPointMake(0, 0);
            _firstLoopView.model = _dataArray.firstObject;
            _secondLoopView.model = [_dataArray objectAtIndex:1];
        }
        _firstLoopView.loopItemIndex = 0;
        _secondLoopView.loopItemIndex = 1;
    } else {
        if (_isVertical) {
            self.contentSize = CGSizeMake(_width, _height*3);
            self.contentOffset = CGPointMake(0, _height);
        } else {
            self.contentSize = CGSizeMake(_width * 3, _height);
            self.contentOffset = CGPointMake(_width, 0);
        }
        [self loopScrollViewUpdateDataSourceFirst];
    }
    if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndex:currentView:)]) {
        [self.loopDelegate loopScrollViewCurrentIndex:self.currentIndex currentView:_prohibitLoop?_firstLoopView.contentView:_secondLoopView.contentView];
    }
    [self setUpSubViewFrame];
}

- (void)loopScrollViewWithArray:(NSArray *)dataArray {
    [self loopScrollViewWithArray:dataArray isAlwaysLoop:NO isReset:NO];
}

- (void)loopScrollViewUpdateWithScrollView:(UIScrollView*)scrollView {
    if (_dataArray.count <= 1) {
        return;
    }
    NSArray *change;
    if (_isVertical) {
        if ((scrollView.contentOffset.y>_height&&_prohibitLoop&&self.currentIndex != _dataArray .count - 1)||(scrollView.contentOffset.y>_height&&!_prohibitLoop)||(_prohibitLoop&&self.currentIndex == 0 && scrollView.contentOffset.y == _height)||(_prohibitLoop&&self.currentIndex == 1 && scrollView.contentOffset.y == _height&&_dataArray.count == 2)) {
            //向上滑
            if (_prohibitLoop && self.currentIndex < _dataArray.count - 1 ) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionUp];
            }else if (!_prohibitLoop) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionUp];
            }
            if ((self.currentIndex >= _dataArray.count-1 || self.currentIndex == 1) && _prohibitLoop) {
                
            } else {
                [self loopScrollViewUpdateDataSourceWithSlidingDirection:SlidingDirectionUp];
                [scrollView scrollRectToVisible:CGRectMake(0, _height, _width, _height) animated:NO];
            }
            if (change) {
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewLastIndex:lastView:)]) {
                    [self.loopDelegate loopScrollViewLastIndex:[change.firstObject integerValue] lastView:[change objectAtIndex:1]];
                }
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndex:currentView:)]) {
                    [self.loopDelegate loopScrollViewCurrentIndex:self.currentIndex currentView:[change lastObject]];
                }
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndexChange:)]) {
                    [self.loopDelegate loopScrollViewCurrentIndexChange:self.currentIndex];
                }
            }
        }else if ((scrollView.contentOffset.y<_height && _prohibitLoop && self.currentIndex != 0)||(scrollView.contentOffset.y<_height && !_prohibitLoop)||(_prohibitLoop&&self.currentIndex == _dataArray.count-1 && scrollView.contentOffset.y == _height)||(_prohibitLoop&&self.currentIndex == 0 && scrollView.contentOffset.y == 0&&_dataArray.count == 2)){
            //向下滑
            if (_prohibitLoop && self.currentIndex > 0 ) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionDown];
            }else if (!_prohibitLoop) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionDown];
            }
            if ((self.currentIndex <= 0 || self.currentIndex == _dataArray.count - 2) && _prohibitLoop) {
                
            } else {
                [self loopScrollViewUpdateDataSourceWithSlidingDirection:SlidingDirectionDown];
                [scrollView scrollRectToVisible:CGRectMake(0, _height, _width, _height) animated:NO];
            }
            if (change) {
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewLastIndex:lastView:)]) {
                    [self.loopDelegate loopScrollViewLastIndex:[change.firstObject integerValue] lastView:[change objectAtIndex:1]];
                }
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndex:currentView:)]) {
                    [self.loopDelegate loopScrollViewCurrentIndex:self.currentIndex currentView:[change lastObject]];
                }
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndexChange:)]) {
                    [self.loopDelegate loopScrollViewCurrentIndexChange:self.currentIndex];
                }
            }
        } else {
            return;
        }
    }else{
        if (scrollView.contentOffset.x>_width||(_prohibitLoop&&self.currentIndex == 0 && scrollView.contentOffset.x == _width)||(_prohibitLoop&&self.currentIndex == 1 && scrollView.contentOffset.x == _width&&_dataArray.count == 2)) {
            //向左滑
            if (_prohibitLoop && self.currentIndex < _dataArray.count - 1 ) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionLeft];
            }else if (!_prohibitLoop) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionLeft];
            }
            if ((self.currentIndex >= _dataArray.count - 1 || self.currentIndex == 1) && _prohibitLoop) {
                
            } else {
                [self loopScrollViewUpdateDataSourceWithSlidingDirection:SlidingDirectionLeft];
                [scrollView scrollRectToVisible:CGRectMake(_width, 0, _width, _height) animated:NO];
            }
            
            if (change) {
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewLastIndex:lastView:)]) {
                    [self.loopDelegate loopScrollViewLastIndex:[change.firstObject integerValue] lastView:[change objectAtIndex:1]];
                }
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndex:currentView:)]) {
                    [self.loopDelegate loopScrollViewCurrentIndex:self.currentIndex currentView:[change lastObject]];
                }
            }
        }else if (scrollView.contentOffset.x<_width||(_prohibitLoop&&self.currentIndex == _dataArray.count-1 && scrollView.contentOffset.x == _width)||(_prohibitLoop&&self.currentIndex == 0 && scrollView.contentOffset.x == 0&&_dataArray.count == 2)){
            //向右滑
            if (_prohibitLoop && self.currentIndex > 0 ) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionRight];
            }else if (!_prohibitLoop) {
                change = [self loopScrollViewUpdateCurrentIndexWithSlidingDirection:SlidingDirectionRight];
            }
            if ((self.currentIndex <= 0 || self.currentIndex == _dataArray.count - 2) && _prohibitLoop) {
                
            } else {
                [self loopScrollViewUpdateDataSourceWithSlidingDirection:SlidingDirectionRight];
                [scrollView scrollRectToVisible:CGRectMake(_width, 0, _width, _height) animated:NO];
            }
            if (change) {
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewLastIndex:lastView:)]) {
                    [self.loopDelegate loopScrollViewLastIndex:[change.firstObject integerValue] lastView:[change objectAtIndex:1]];
                }
                if ([self.loopDelegate respondsToSelector:@selector(loopScrollViewCurrentIndex:currentView:)]) {
                    [self.loopDelegate loopScrollViewCurrentIndex:self.currentIndex currentView:[change lastObject]];
                }
            }
        }else{
            return;
        }
    }
}

- (void)loopScrollViewDidEndDragging:(UIScrollView *)scrollView {
    if (!_prohibitLoop) {
        return;
    }
    NSUInteger count = 0;
    if (_dataArray.count == 2) {
        count = 1;
    }else if (_dataArray.count >= 3) {
        count = 2;
    }

    if (_isVertical && self.currentIndex == _dataArray.count-1 && ((scrollView.contentOffset.y>=_height*count && count != 0) || (count==0 &&scrollView.contentOffset.y>0))) {
        if ([self.loopDelegate respondsToSelector:@selector(loopSrcollViewLoadMore)]) {
            [self.loopDelegate loopSrcollViewLoadMore];
            return;
        }
    }
    if (_isVertical && ((count == 0 && scrollView.contentOffset.y<0)||(count!=0 && scrollView.contentOffset.y<=0)) && self.currentIndex == 0) {
        if ([self.loopDelegate respondsToSelector:@selector(loopSrcollViewHeaderRefresh)]) {
            [self.loopDelegate loopSrcollViewHeaderRefresh];
            return;
        }
    }
    if (count == 1) {
        [scrollView scrollRectToVisible:CGRectMake(0, 0, _width, _height) animated:YES];
    }
}

- (void)loopScrollViewUpdateDataSourceFirst {
    _firstLoopView.model = [self loopScrollViewFirstModel];
    _secondLoopView.model = [self loopScrollViewSecondModel];
    _thirdLoopView.model = [self loopScrollViewThirdModel];
    if (_prohibitLoop) {
        _firstLoopView.loopItemIndex = 0;
        _secondLoopView.loopItemIndex = 1;
        _thirdLoopView.loopItemIndex = 2;
    }else {
        _firstLoopView.loopItemIndex = _dataArray.count - 1;
        _secondLoopView.loopItemIndex = 0;
        _thirdLoopView.loopItemIndex = 1;
    }
}

- (void)loopScrollViewUpdateDataSourceWithSlidingDirection:(SlidingDirection)slidingDirection {
    UIView<LoopViewResetProtocol> *firstView = _firstLoopView.contentView;
    UIView<LoopViewResetProtocol> *secondView = _secondLoopView.contentView;
    UIView<LoopViewResetProtocol> *thirdView = _thirdLoopView.contentView;
    [firstView removeFromSuperview];
    [secondView removeFromSuperview];
    [thirdView removeFromSuperview];
    if (slidingDirection == SlidingDirectionLeft || slidingDirection == SlidingDirectionUp) {
        //加
        _firstLoopView.contentView = secondView;
        _secondLoopView.contentView = thirdView;
        if ([firstView respondsToSelector:@selector(loopViewResetCurrentLoopItem)]) {
            [firstView loopViewResetCurrentLoopItem];
        }
        _thirdLoopView.contentView = firstView;
        _thirdLoopView.model = [self loopScrollViewThirdModel];
        _thirdLoopView.loopItemIndex = self.currentIndex== _dataArray.count-1 ? 0 : self.currentIndex + 1;
    } else {
        //减
        _thirdLoopView.contentView = secondView;
        _secondLoopView.contentView = firstView;
        if ([thirdView respondsToSelector:@selector(loopViewResetCurrentLoopItem)]) {
            [thirdView loopViewResetCurrentLoopItem];
        }
        _firstLoopView.contentView = thirdView;
        _firstLoopView.model = [self loopScrollViewFirstModel];
        _firstLoopView.loopItemIndex = self.currentIndex == 0 ? _dataArray.count-1 : self.currentIndex - 1;
    }
}

- (NSArray *)loopScrollViewUpdateCurrentIndexWithSlidingDirection:(SlidingDirection)direction {
    UIView *currentView; NSInteger lastIndex = self.currentIndex;
    UIView *lastView;
    if (direction == SlidingDirectionUp||direction == SlidingDirectionLeft) {
        self.currentIndex = self.currentIndex + 1;
        if (self.currentIndex>=_dataArray.count) {
            self.currentIndex = 0;
        }
        if (_prohibitLoop&&lastIndex==0&&self.currentIndex == 1) {
            currentView = _secondLoopView.contentView;
            lastView = _firstLoopView.contentView;
        } else {
            currentView = _thirdLoopView.contentView;
            lastView = _secondLoopView.contentView;
        }
    } else {
        self.currentIndex = self.currentIndex - 1;
        if (self.currentIndex<0) {
            self.currentIndex = _dataArray.count - 1;
        }
        if (_prohibitLoop&&lastIndex==_dataArray.count-1&&self.currentIndex == _dataArray.count-2) {
            currentView = _secondLoopView.contentView;
            lastView = _thirdLoopView.contentView;
        } else {
            currentView = _firstLoopView.contentView;
            lastView = _secondLoopView.contentView;
        }
    }
    if (_countType == CountTypeThreeOrMore) {
        self.currentPage = self.currentIndex + 1;
    }else if (_countType == CountTypeOne){
        self.currentPage = 1;
    }else if (_countType == CountTypeTwo){
        if (self.currentPage == 1) {
            self.currentPage = 2;
        }else{
            self.currentPage = 1;
        }
    }else{
        self.currentPage = 1;
    }
    return @[@(lastIndex), lastView, currentView];
}


- (void)loopSrcollViewScrollUpManual {
    if (self.isTracking) { return; }
    if (_prohibitLoop && self.currentIndex == 0) {
        [self scrollRectToVisible:CGRectMake(0, _height, _width, _height) animated:YES];
    } else if (_prohibitLoop && self.currentIndex == _dataArray.count - 1) {
        if ([self.loopDelegate respondsToSelector:@selector(loopSrcollViewLoadMore)]) {
            [self.loopDelegate loopSrcollViewLoadMore];
        }
        return;
    } else {
        [self scrollRectToVisible:CGRectMake(0, _height * 2, _width, _height) animated:YES];
    }
}


- (void)loopSrcollViewScrollRightManual {
    if (self.isTracking) { return; }
    if (_prohibitLoop && self.currentIndex == 0) {
        [self scrollRectToVisible:CGRectMake(_width, 0, _width, _height) animated:YES];
    } else if (_prohibitLoop && self.currentIndex == _dataArray.count - 1) {
        return;
    } else {
        [self scrollRectToVisible:CGRectMake(_width * 2, 0, _width, _height) animated:YES];
    }
}


- (void)loopSrcollViewScrollDownManual {
    if (self.isTracking) { return; }
    if (_prohibitLoop && self.currentIndex == _dataArray.count - 1) {
        [self scrollRectToVisible:CGRectMake(0, _height, _width, _height) animated:YES];
    } else if (_prohibitLoop && self.currentIndex == 0) {
        return;
    } else {
        [self scrollRectToVisible:CGRectMake(0, 0, _width, _height) animated:YES];
    }
}

- (void)loopSrcollViewScrollLeftManual {
    if (self.isTracking) { return; }
    if (_prohibitLoop && self.currentIndex == _dataArray.count - 1) {
        [self scrollRectToVisible:CGRectMake(_width, 0, _width, _height) animated:YES];
    } else if (_prohibitLoop && self.currentIndex == 0) {
        return;
    } else {
        [self scrollRectToVisible:CGRectMake(_width * 2, 0, _width, _height) animated:YES];
    }
}

- (UIView *)loopScrollItemViewWithIndex:(NSUInteger)index {
    if (_prohibitLoop &&( (self.currentIndex == 0 && index == 1)||(self.currentIndex == _dataArray.count - 1 && index == _dataArray.count - 2))) {
        return _secondLoopView.contentView;
    }
    if (index == self.currentIndex) {
        return _secondLoopView.contentView;
    } else if (index == self.currentIndex - 1) {
        return _firstLoopView.contentView;
    } else if (index == self.currentIndex + 1) {
        return _thirdLoopView.contentView;
    } else {
        return nil;
    }
}

- (void)loopScrollViewAddDataSourceWithArray:(NSArray *)dataArray {
    if (!dataArray||dataArray.count == 0) {
        return;
    }
    BOOL isLast = _prohibitLoop&&self.currentIndex == _dataArray.count-1;
    [_dataArray addObjectsFromArray:dataArray];
    if (isLast) {
        UIView<LoopViewResetProtocol> *firstView = _firstLoopView.contentView;
        UIView<LoopViewResetProtocol> *secondView = _secondLoopView.contentView;
        UIView<LoopViewResetProtocol> *thirdView = _thirdLoopView.contentView;
        [firstView removeFromSuperview];
        [secondView removeFromSuperview];
        [thirdView removeFromSuperview];
        _firstLoopView.contentView = secondView;
        _secondLoopView.contentView = thirdView;
        if ([thirdView respondsToSelector:@selector(loopViewResetCurrentLoopItem)]) {
            [thirdView loopViewResetCurrentLoopItem];
        }
        _thirdLoopView.contentView = firstView;
        _thirdLoopView.model = [self loopScrollViewThirdModel];
        if (_isVertical) {
            [self scrollRectToVisible:CGRectMake(0, _height, _width, _height) animated:NO];
        } else {
            [self scrollRectToVisible:CGRectMake(_width, 0, _width, _height) animated:NO];
        }
    }
    
}

- (id)loopScrollViewFirstModel {
    if (_prohibitLoop&&self.currentIndex == 0) {
        return [_dataArray firstObject];
    }
    if (self.currentIndex==0) {
        return [_dataArray lastObject];
    }else{
        return [_dataArray objectAtIndex:self.currentIndex - 1];
    }
}

- (id)loopScrollViewSecondModel{
    if (_prohibitLoop&&self.currentIndex == 0) {
        return [_dataArray objectAtIndex:1];
    }
    return [_dataArray objectAtIndex:self.currentIndex];
}

- (id)loopScrollViewThirdModel{
    if (_prohibitLoop&&self.currentIndex == 0) {
        return [_dataArray objectAtIndex:2];
    }
    if (self.currentIndex >= _dataArray.count - 1) {
        return [_dataArray firstObject];
    }else{
        return [_dataArray objectAtIndex:self.currentIndex + 1];
    }
}

#pragma mark - 开始动画
- (void)loopScrollViewStartAutoplay:(NSTimeInterval)interval scrollSpeed:(NSTimeInterval)time {
    [self loopScrollViewStopAutoplay];
    self.timeSpeed = time;
    if (self.timeSpeed == 0) {
        self.timeSpeed = 1;
    }
    __weak typeof(self)weakself = self;
    _loopTimer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakself loopScrollViewTimerAction];
    }];
}

- (void)loopScrollViewStartAutoplay:(NSTimeInterval)interval {
    [self loopScrollViewStartAutoplay:interval scrollSpeed:1];
}

- (void)loopScrollViewTimerAction {
    if (_dataArray.count<3) {
        return ;
    }
    if (_isVertical) {
        [self loopScrollViewScrollToVisibleWithPoint:loopScrollViewPoint(0, _height*2)];
    }else{
        [self loopScrollViewScrollToVisibleWithPoint:loopScrollViewPoint(_width*2, 0)];
    }
}

CGPoint loopScrollViewPoint(CGFloat x, CGFloat y) {
    return CGPointMake(x, y);
}

- (void)loopScrollViewScrollToVisibleWithPoint:(CGPoint)point {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:1 animations:^{
        [weakSelf setContentOffset:point];
    } completion:^(BOOL finished) {
        if ([weakSelf.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
            [weakSelf.delegate scrollViewDidEndScrollingAnimation:weakSelf];
        }
    }];
}

#pragma mark - 结束动画
- (void)loopScrollViewStopAutoplay {
    [_loopTimer invalidate];
    _loopTimer = nil;
}

- (void)dealloc{
    [self loopScrollViewStopAutoplay];
}

@end

@implementation XXXLoopView

/**
 * 自定义初始化方法 可配置水平/垂直滚动
 * @param className 循环滚动item的类名
 * @param frame 位置
 * @param isVertical 是否垂直滚动
 */
- (instancetype)initWithFrame:(CGRect)frame itemClassName:(NSString*)className isVertical:(BOOL)isVertical {
    self = [super initWithFrame:frame];
    if (self) {
        
        _loopScroll = [[LoopScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) itemViewClassName:className isVertical:isVertical];
        _loopScroll.delegate = self;
        _loopScroll.loopDelegate = self;
        [self addSubview:_loopScroll];
    }
    return self;
}

- (instancetype)initWithItemClassName:(NSString*)className isVertical:(BOOL)isVertical prohibitLoop:(BOOL)prohibitLoop {
    self = [super init];
    if (self) {
        _loopScroll = [[LoopScrollView alloc] initWithItemViewClassName:className isVertical:isVertical prohibitLoop:prohibitLoop];
        _loopScroll.delegate = self;
        _loopScroll.loopDelegate = self;
        [self addSubview:_loopScroll];
    }
    return self;
}
/**
 * 自定义初始化方法 水平滚动
 * @param className 循环滚动item的类名
 * @param frame 位置
 */
- (instancetype)initWithFrame:(CGRect)frame itemClassName:(NSString*)className {
    self = [super initWithFrame:frame];
    if (self) {
        _loopScroll = [[LoopScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) itemViewClassName:className];
        _loopScroll.delegate = self;
        _loopScroll.loopDelegate = self;
        [self addSubview:_loopScroll];
    }
    return self;
}

/**
 * 自定义初始化方法 水平滚动
 * @param className 循环滚动item的类名
 */
- (instancetype)initWithItemClassName:(NSString*)className {
    self = [super init];
    if (self) {
        _loopScroll = [[LoopScrollView alloc] initWithFrame:CGRectZero itemViewClassName:className];
        _loopScroll.delegate = self;
        _loopScroll.loopDelegate = self;
        [self addSubview:_loopScroll];
    }
    return self;
}

- (instancetype)initWithItemClassName:(NSString*)className isVertical:(BOOL)isVertical {
    return [self initWithItemClassName:className isVertical:isVertical prohibitLoop:NO];
}

- (void)loopSrcollViewHeaderRefresh {
    if ([self.delegate respondsToSelector:@selector(loopViewHeaderRefresh)]) {
        [self.delegate loopViewHeaderRefresh];
    }
}

- (void)loopSrcollViewLoadMore {
    if ([self.delegate respondsToSelector:@selector(loopViewLoadMore)]) {
        [self.delegate loopViewLoadMore];
    }
}

- (void)loopScrollViewCurrentIndex:(NSInteger)currentIndex currentView:(UIView *)currentView {
    if ([self.delegate respondsToSelector:@selector(loopViewCurrentIndex:currentView:)]) {
        [self.delegate loopViewCurrentIndex:currentIndex currentView:currentView];
    }
    
}

- (void)loopScrollViewCurrentIndexChange:(NSInteger)currentIndex {
    if ([self.delegate respondsToSelector:@selector(loopViewCurrentIndexChange:)]) {
        [self.delegate loopViewCurrentIndexChange:currentIndex];
    }
}

- (void)loopScrollViewLastIndex:(NSInteger)lastIndex lastView:(UIView *)lastView {
    if ([self.delegate respondsToSelector:@selector(loopViewLastIndex:lastView:)]) {
        [self.delegate loopViewLastIndex:lastIndex lastView:lastView];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _loopScroll.frame = self.bounds;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _loopScroll.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

- (void)setScrollViewUserInteractionEnabled:(BOOL)isUserInteractionEnabled {
    _loopScroll.userInteractionEnabled = isUserInteractionEnabled;
}

- (void)setUpViewsWithArray:(NSArray *)dataArray isAlwaysLoop:(BOOL)isAlwaysLoop {
    [_loopScroll loopScrollViewWithArray:dataArray isAlwaysLoop:isAlwaysLoop isReset:!self.dataArray];
    self.dataArray = [NSMutableArray arrayWithArray:dataArray];
}

- (void)setUpViewsWithArray:(NSArray*)dataArray {
    [self setUpViewsWithArray:dataArray isAlwaysLoop:NO];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [_loopScroll loopScrollViewUpdateWithScrollView:_loopScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.loopScroll loopScrollViewDidEndDragging:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [_loopScroll loopScrollViewUpdateWithScrollView:scrollView];
}

- (void)startAutoplay:(NSTimeInterval)interval scrollSpeed:(NSTimeInterval)time {
    [_loopScroll loopScrollViewStartAutoplay:interval scrollSpeed:time];
}

- (void)startAutoplay:(NSTimeInterval)interval {
    _loopScroll.isAutoScroll = YES;
    [_loopScroll loopScrollViewStartAutoplay:interval];
}

- (void)stopAutoplay {
    _loopScroll.isAutoScroll = NO;
    [_loopScroll loopScrollViewStopAutoplay];
}

- (void)loopViewScrollUpManual{
    [self.loopScroll loopSrcollViewScrollUpManual];
}

- (void)loopViewScrollDownManual {
    [self.loopScroll loopSrcollViewScrollDownManual];
}

- (void)loopViewScrollLeftManual {
    [self.loopScroll loopSrcollViewScrollLeftManual];
}

- (void)loopViewScrollRightManual {
    [self.loopScroll loopSrcollViewScrollRightManual];
}

- (UIView *)loopViewItemWithIndex:(NSUInteger)index {
    return [self.loopScroll loopScrollItemViewWithIndex:index];
}

- (void)loopViewAddDataSourceWithArray:(NSArray *)dataArray {
    [self.dataArray addObjectsFromArray:dataArray];
    [self.loopScroll loopScrollViewAddDataSourceWithArray:dataArray];
}

@end
