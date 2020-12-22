//
//  ViewController.m
//  LoopViewTest
//
//  Created by liuchong on 2018/5/17.
//  Copyright © 2018年 liuchong. All rights reserved.
//

#import "ViewController.h"
#import "TestModel.h"
#import "XXXLoopView.h"

@interface ViewController ()

@property (nonatomic, strong)XXXLoopView *loopView;
@property (nonatomic, strong)NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    ///已有兼容约束的初始化方法，例如
    ///- (instancetype)initWithItemClassName:(NSString*)className;
    self.loopView = [[XXXLoopView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) itemClassName:@"TestView"];
    
    self.dataArray = [NSMutableArray arrayWithCapacity:4];
    for (int index = 0; index<4; index ++) {
        TestModel *model = [[TestModel alloc] init];
        switch (index) {
            case 0:
                model.imageName = @"1.jpg";
                break;
            case 1:
                model.imageName = @"2.jpg";
                break;
                
            case 2:
                model.imageName = @"3.jpg";
                break;
                
            case 3:
                model.imageName = @"4.jpg";
                break;
                
            default:
                break;
        }
        [self.dataArray addObject:model];
    }
    [self.loopView setUpViewsWithArray:self.dataArray];
    [self.loopView startAutoplay:1];
    [self.view addSubview:self.loopView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
