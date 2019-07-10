//
//  ZegoReplayViewController.m
//  ZegoWhiteBoardEdu-iOS
//
//  Created by Sky on 2019/5/30.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoReplayViewController.h"
#import <WhiteSDK.h>
#import "PlayerCommandListController.h"

@interface ZegoReplayViewController ()
<WhiteCommonCallbackDelegate,
WhitePlayerEventDelegate,
UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) WhiteSDK *sdk;
@property (nonatomic, nullable, strong) WhitePlayer *player;

@property (strong, nonatomic) AVPlayer *avPlayer;
@property (strong, nonatomic) AVPlayerLayer *avLayer;

@property (strong, nonatomic) UIView *videoView;
@property (strong, nonatomic) WhiteBoardView *boardView;
@property (strong, nonatomic) UIButton *toolBtn;
@property (strong, nonatomic) UIButton *exitBtn;

@end

@implementation ZegoReplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self initPlayer];
    [self setupAVPlayer];
}

- (void)setupUI {
    self.videoView = [[UIView alloc] init];
    self.videoView.backgroundColor = UIColor.lightGrayColor;
    
#warning WhiteboardView 初始化注意事项：
    /**
     请提前将 WhiteBoardView 添加至视图栈中（生成 whiteSDK 前）。否则 iOS 12 真机无法执行正常执行sdk代码。
     */
    self.boardView = [[WhiteBoardView alloc] init];
    
    UIButton *toolBtn = [[UIButton alloc] init];
    [toolBtn setTitle:@"白板工具" forState:UIControlStateNormal];
    [toolBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [toolBtn addTarget:self action:@selector(showTools:) forControlEvents:UIControlEventTouchUpInside];
    self.toolBtn = toolBtn;
    
    UIButton *exitBtn = [[UIButton alloc] init];
    [exitBtn setTitle:@"退出" forState:UIControlStateNormal];
    [exitBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [exitBtn addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
    self.exitBtn = exitBtn;
    
    /*
     需要手动兼容 iOS10 及其以下。
     FIX UIScrollView 自动偏移的问题
     WhiteBoardView 内部有 UIScrollView，在 iOS 10及其以下时，如果 WhiteBoardView 是当前视图栈中第一个的话，会出现内容错位。
     iOS 11 及其以上已做处理。
     */
    if (@available(iOS 11, *)) {
    } else {
        //可以参考此处处理。
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.view addSubview:self.videoView];
    [self.view addSubview:self.boardView];
    [self.view addSubview:self.toolBtn];
    [self.view addSubview:self.exitBtn];
    
    
    CGFloat scrH = UIScreen.mainScreen.bounds.size.height;
    
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.view);
        make.width.mas_equalTo(scrH/2);
        make.height.mas_equalTo(scrH);
    }];
    
    [self.boardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.equalTo(self.view);
        make.left.equalTo(self.videoView.mas_right);
    }];
    
    [self.exitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).inset(10);
        make.right.equalTo(self.view).inset(20);
    }];
    
    [self.toolBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.exitBtn.mas_top);
        make.right.equalTo(self.exitBtn.mas_left).offset(-10);
    }];
}

- (void)initPlayer {
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    config.debug = YES;
    
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:config commonCallbackDelegate:self];
    WhitePlayerConfig *playerConfig = [[WhitePlayerConfig alloc] initWithRoom:self.roomUUID];
    [self.sdk createReplayerWithConfig:playerConfig callbacks:self completionHandler:^(BOOL success, WhitePlayer * _Nonnull player, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"创建回放房间失败 error:%@", [error localizedDescription]);
        } else {
            self.player = player;
            [self.player getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
                [self.player play];
                [self.avPlayer play];
            }];
            NSLog(@"创建回放房间成功，开始回放");
        }
    }];
}

- (void)setupAVPlayer {
    self.avPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:self.videoURL]];
    
    self.avLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    CGFloat scrH = UIScreen.mainScreen.bounds.size.height;
    self.avLayer.frame = CGRectMake(0, 0, scrH/2, scrH);
    [self.videoView.layer addSublayer:self.avLayer];
}

- (void)showPopoverViewController:(UIViewController *)vc sourceView:(id)sourceView {
    vc.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *present = vc.popoverPresentationController;
    present.permittedArrowDirections = UIPopoverArrowDirectionAny;
    present.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
    if ([sourceView isKindOfClass:[UIView class]]) {
        present.sourceView = sourceView;
        present.sourceRect = [sourceView bounds];
    }
    else if ([sourceView isKindOfClass:[UIBarButtonItem class]]) {
        present.barButtonItem = sourceView;
    }
    else {
        present.sourceView = self.view;
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}

#pragma mark - Actions

- (void)exit {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showTools:(UIButton *)sender {
    PlayerCommandListController *controller = [[PlayerCommandListController alloc] initWithPlayer:self.player];
    [self showPopoverViewController:controller sourceView:sender];
}

#pragma mark - WhitePlayerEventDelegate

- (void)phaseChanged:(WhitePlayerPhase)phase {
    NSLog(@"player %s %ld", __FUNCTION__, (long)phase);
}

- (void)loadFirstFrame {
    NSLog(@"player %s", __FUNCTION__);
}

- (void)sliceChanged:(NSString *)slice {
    NSLog(@"player %s slice:%@", __FUNCTION__, slice);
}

- (void)playerStateChanged:(WhitePlayerState *)modifyState {
    NSString *str = [modifyState jsonString];
    NSLog(@"player %s state:%@", __FUNCTION__, str);
}

- (void)stoppedWithError:(NSError *)error {
    NSLog(@"player %s error:%@", __FUNCTION__, error);
}

- (void)scheduleTimeChanged:(NSTimeInterval)time {
    NSLog(@"player %s time:%f", __FUNCTION__, (double)time);
}

#pragma mark - WhiteCommonCallback

- (void)throwError:(NSError *)error {
    NSLog(@"throwError: %@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url {
    return @"https://white-pan-cn.oss-cn-hangzhou.aliyuncs.com/124/image/image.png";
}

@end
