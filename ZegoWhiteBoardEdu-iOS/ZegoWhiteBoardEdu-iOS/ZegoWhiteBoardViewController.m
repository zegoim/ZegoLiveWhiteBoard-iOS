//
//  ZegoWhiteBoardViewController.m
//  ZegoWhiteBoardEdu-iOS
//
//  Created by Sky on 2019/5/28.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoWhiteBoardViewController.h"
#import "RoomCommandListController.h"
#import <WhiteSDK.h>
#import "ZegoRoomManager.h"

@interface ZegoWhiteBoardViewController ()
<WhiteRoomCallbackDelegate,
WhiteCommonCallbackDelegate,
UIPopoverPresentationControllerDelegate,
ZegoRoomManagerDelegate,
ZegoIMDelegate>

@property (strong, nonatomic) UIView *remoteView;
@property (strong, nonatomic) UIView *localView;
@property (strong, nonatomic) WhiteBoardView *boardView;
@property (strong, nonatomic) UIButton *toolBtn;
@property (strong, nonatomic) UIButton *exitBtn;

@property (strong, nonatomic) WhiteSDK *whiteSDK;
@property (strong, nonatomic) WhiteRoom *whiteRoom;

@property (strong, nonatomic) ZegoRoomManager *roomManager;

@property (nonatomic, assign, getter=isReconnecting) BOOL reconnecting;

@end

@implementation ZegoWhiteBoardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupRoomManager];
    [self setupUserLeaveRoomListen];
    [self joinRoom];
}

- (void)setupViews {
    self.remoteView = [[UIView alloc] init];
    self.remoteView.backgroundColor = UIColor.lightGrayColor;
    
    self.localView = [[UIView alloc] init];
    self.localView.backgroundColor = UIColor.darkGrayColor;
    
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
    
    [self.view addSubview:self.remoteView];
    [self.view addSubview:self.localView];
    [self.view addSubview:self.boardView];
    [self.view addSubview:self.toolBtn];
    [self.view addSubview:self.exitBtn];
    
    
    CGFloat scrH = UIScreen.mainScreen.bounds.size.height;
    
    [self.remoteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.view);
        make.width.height.mas_equalTo(scrH/2);
    }];
    
    [self.localView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(self.view);
        make.top.equalTo(self.remoteView.mas_bottom);
        make.width.height.equalTo(self.remoteView.mas_height);
    }];
    
    [self.boardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.equalTo(self.view);
        make.left.equalTo(self.remoteView.mas_right);
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

- (void)joinRoom {
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    
    //如果不需要拦截图片API，则不需要开启，页面内容较为复杂时，可能会有性能问题
    config.enableInterrupterAPI = YES;
    config.debug = YES;
    //打开用户头像显示信息
    config.userCursor = YES;
    //SDK 只提供数据信息，不实现用户头像
    //config.customCursor = YES;
    
    
    self.whiteSDK = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:config commonCallbackDelegate:self];
    
    //UserId 需要保证每个用户唯一，否则同一个 userId，最先加入的人，会被踢出房间。
    WhiteMemberInformation *memberInfo = [[WhiteMemberInformation alloc] initWithUserId:ZGHelper.user.userId name:ZGHelper.user.userName avatar:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg"];
    
    WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUuid:self.roomUUID roomToken:self.roomToken memberInfo:memberInfo];
    
    Weakify(self);
    [self.whiteSDK joinRoomWithConfig:roomConfig callbacks:self completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
        Strongify(self);
        
        if (success) {
            self.whiteRoom = room;
            [self.whiteRoom addMagixEventListener:WhiteCommandCustomEvent];
            
            [self joinLiveRoom];
        }
        else {
            [self showJoinFailed:error];
        }
    }];
}

- (void)setupRoomManager {
    ZegoRoomManager *roomManager = [ZegoRoomManager managerWithApi:ZGApiManager.api onlyAudio:NO];
    roomManager.autoReconnectRoom = YES;
    roomManager.reconnectTimeout = 3*60;
    [roomManager addDelegate:self];
//    [roomManager addLiveStatusDelegate:self];
    
    self.roomManager = roomManager;
}

- (void)setupUserLeaveRoomListen {
    [ZGApiManager.api setIMDelegate:self];
}

- (void)joinLiveRoom {
    ZegoRoomInfo *info = [ZegoRoomInfo new];
    info.roomID = self.roomID;
    
    [ZegoHudManager showNetworkLoading];
    
    Weakify(self);
    [self.roomManager joinRoom:info user:ZGHelper.user completion:^(NSError * _Nullable error) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        
        ZegoAVConfig *config = [ZegoAVConfig new];
        config.videoEncodeResolution = CGSizeMake(400, 400);
        config.videoCaptureResolution = CGSizeMake(400, 400);
        config.fps = 15;
        config.bitrate = 500000;
        
        [ZGApiManager.api setAVConfig:config];
        
        [ZGApiManager.api setAppOrientation:UIInterfaceOrientationLandscapeLeft];
        [self.roomManager startPreview];
        [self.roomManager startLive];
    }];
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
    RoomCommandListController *controller = [[RoomCommandListController alloc] initWithRoom:self.whiteRoom];
    [self showPopoverViewController:controller sourceView:sender];
}

- (void)showJoinFailed:(NSError *)error {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"加入房间失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self exit];
    }];
    
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showTeacherLeave {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"老师已离开房间" message:nil    preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self exit];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - WhiteRoomCallbackDelegate

- (void)firePhaseChanged:(WhiteRoomPhase)phase {
    NSLog(@"%s, %ld", __FUNCTION__, (long)phase);
    
    if (phase == WhiteRoomPhaseDisconnected && self.whiteSDK && !self.isReconnecting) {
        self.reconnecting = YES;
        
        Weakify(self);
        [self.whiteSDK joinRoomWithUuid:self.roomUUID roomToken:self.roomToken completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
            Strongify(self);
            
            self.reconnecting = NO;
            NSLog(@"reconnected");
            
            if (success) {
                self.whiteRoom = room;
            }
            else {
                NSLog(@"error:%@", [error localizedDescription]);
            }
        }];
    }
}

- (void)fireRoomStateChanged:(WhiteRoomState *)magixPhase {
    NSLog(@"%s, %@", __func__, [magixPhase jsonString]);
}

- (void)fireBeingAbleToCommitChange:(BOOL)isAbleToCommit {
    NSLog(@"%s, %d", __func__, isAbleToCommit);
}

- (void)fireDisconnectWithError:(NSString *)error {
    NSLog(@"%s, %@", __func__, error);
}

- (void)fireKickedWithReason:(NSString *)reason {
    NSLog(@"%s, %@", __func__, reason);
}

- (void)fireCatchErrorWhenAppendFrame:(NSUInteger)userId error:(NSString *)error {
    NSLog(@"%s, %lu %@", __func__, (unsigned long)userId, error);
}

- (void)fireMagixEvent:(WhiteEvent *)event {
    NSLog(@"fireMagixEvent: %@", [event jsonString]);
}

- (void)cursorViewsUpdate:(WhiteUpdateCursor *)updateCursor {
    NSLog(@"cursorViewsUpdate: %@", [updateCursor jsonString]);
}


#pragma mark - WhiteCommonCallbackDelegate

- (void)throwError:(NSError *)error {
    NSLog(@"throwError: %@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url {
    return @"https://white-pan-cn.oss-cn-hangzhou.aliyuncs.com/124/image/image.png";
}

#pragma mark - ZegoRoomManagerDelegate

- (void)roomManager:(ZegoRoomManager *)manager didLiveUserJoin:(ZegoUser *)user {
    UIView *videoView;
    
    if ([user.userId isEqualToString:self.teacherUserID]) {
        videoView = self.remoteView;
    }
    else if ([user.userId isEqualToString:ZGHelper.user.userId]) {
        videoView = self.localView;
    }
    
    [self.roomManager setLiveVideoView:videoView viewMode:ZegoVideoViewModeScaleAspectFill forUser:user];
}

- (void)roomManager:(ZegoRoomManager *)manager didLiveUserLeave:(ZegoUser *)user {
    if ([user.userId isEqualToString:self.teacherUserID]) {
        [self showTeacherLeave];
    }
}


@end
