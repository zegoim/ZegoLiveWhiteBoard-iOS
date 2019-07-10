//
//  ZegoRoomManager.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/22.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoRoomManager.h"
#import <CommonCrypto/CommonCrypto.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-sound-level-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-sound-level-oc.h>
#endif
#import "ZegoDefines.h"
#import "ZegoMultiCastDelegate.h"
#import "NSString+ZG_MD5.h"
#import "ZegoUser+Valid.h"
#import "ZegoUser+NSCopying.h"
#import "ZegoErrorHelper+RoomManager.h"
#import "ZegoUserLiveInfo-Protected.h"
#import "ZegoUserLiveQuality-Protected.h"


@interface ZegoRoomManager (ZegoRoomManagerIDGenerateDelegate) <ZegoRoomManagerIDGenerateDelegate>
- (NSString *)getLiveIDWithUser:(ZegoUser *)user;
@end


@interface ZegoRoomManager ()
<
ZegoRoomDelegate,
ZegoLivePublisherDelegate,
ZegoSoundLevelDelegate
>

@property (strong, nonatomic) ZegoLiveRoomApi *api;

@property (assign, nonatomic) BOOL onlyAudio;
@property (strong, nonatomic) ZegoRoomInfo *roomInfo;
@property (strong, nonatomic) ZegoUser *userInfo;

@property (assign, nonatomic) BOOL isDisconnect;
@property (strong, nonatomic) NSTimer *timeoutTimter;
@property (assign, nonatomic) ZegoRoomLoginStatus loginStatus;
@property (strong, nonatomic) NSMutableSet<ZegoStream*>* allStreams;//不包含自己的stream
@property (strong, nonatomic) NSMutableDictionary<ZegoUser*,ZegoUserLiveInfo*>* liveInfos;

@property (assign, nonatomic) BOOL isPreview;
@property (assign, nonatomic) ZEGOView *previewView;
@property (assign, nonatomic) ZegoVideoViewMode previewViewMode;

@property (assign, nonatomic) BOOL hasCaptureFirstFrame;

@property (copy, nonatomic) ZegoLoginRoomCallback loginCallback;

@property (strong, nonatomic) id<ZegoRoomManagerDelegate> delegate;
@property (strong, nonatomic) id<ZegoRoomManagerLiveStatusDelegate> liveDelegate;
@property (weak, nonatomic) id<ZegoRoomManagerIDGenerateDelegate> idGenDelegate;

@end


NSString * const ZegoApiLiveEventStreamIDKey = @"StreamID";

@implementation ZegoRoomManager

#pragma mark - Life Cycle

- (void)dealloc {
    [self zg_logoutRoom];
    [self removeApiDelegate];
}

+ (instancetype)managerWithApi:(ZegoLiveRoomApi *)api onlyAudio:(BOOL)onlyAudio {
    ZegoRoomManager *instance = [[self alloc] init];
    instance.api = api;
    instance.onlyAudio = onlyAudio;
    
    [api enableCamera:!onlyAudio];
    
    [instance setApiDelegate];
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _allStreams = [NSMutableSet set];
        _liveInfos = [NSMutableDictionary dictionary];
        _reconnectInterval = 1.0;
        _soundLevelMonitorCycle = 1.0;
        _delegate = [ZegoMultiCastDelegate<ZegoRoomManagerDelegate> delegate];
        _liveDelegate = [ZegoMultiCastDelegate<ZegoRoomManagerLiveStatusDelegate> delegate];
    }
    
    return self;
}


#pragma mark - Public Methods

#pragma mark Delegate

- (void)addDelegate:(id <ZegoRoomManagerDelegate>)delegate {
    [(ZegoMultiCastDelegate *)self.delegate addDelegate:delegate];
}

- (void)removeDelegate:(id <ZegoRoomManagerDelegate>)delegate {
    [(ZegoMultiCastDelegate *)self.delegate removeDelegate:delegate];
}

- (void)addLiveStatusDelegate:(id <ZegoRoomManagerLiveStatusDelegate>)delegate {
    [(ZegoMultiCastDelegate *)self.liveDelegate addDelegate:delegate];
}

- (void)removeLiveStatusDelegate:(id <ZegoRoomManagerLiveStatusDelegate>)delegate {
    [(ZegoMultiCastDelegate *)self.liveDelegate removeDelegate:delegate];
}

- (void)setIDGenerateDelegate:(nullable id <ZegoRoomManagerIDGenerateDelegate>)delegate {
    self.idGenDelegate = delegate;
}

#pragma mark Login Room

- (void)joinRoom:(ZegoRoomInfo *)roomInfo user:(ZegoUser *)userInfo completion:(nullable ZegoLoginRoomCallback)completion {
    if (self.loginStatus != kZegoRoomLoginStatusLogout) {
        return;
    }
    
    self.roomInfo = roomInfo;
    self.userInfo = userInfo;
    ZegoRole role = [roomInfo.owner isEqual:self.userInfo] ? ZEGO_ANCHOR:ZEGO_AUDIENCE;
    
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventLogin error:nil];
    
    Weakify(self);
    bool result = [self.api loginRoom:roomInfo.roomID roomName:roomInfo.roomName role:role withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        [self onLoginRoomComplete:errorCode streamList:streamList roomInfo:roomInfo completion:completion];
    }];
    
    if (result) {
        self.loginCallback = completion;
        
        if (self.autoReconnectRoom) {
            [self setupTimeoutTimer];
        }
    }
    else {
        NSError *error = [ZegoErrorHelper roomErrorWithCode:ZegoRoomParamErrorCode];
        [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventLoginFailed error:error];
        
        if (self.autoReconnectRoom) {
            [self endLoginRetryWithReason:kZegoRoomReconnectStopReasonParam];
        }
    }
}

- (void)leaveRoom {
    [self releaseAllLiveUsers];
    [self zg_logoutRoom];
    
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventLogout error:nil];
    
    if (self.autoReconnectRoom) {
        [self endLoginRetryWithReason:kZegoRoomReconnectStopReasonLogout];
    }
    
    [self reset];
}


#pragma mark Live User

- (void)startLive {
    [self addLiveUser:self.userInfo];
}

- (void)stopLive {
    [self removeLiveUser:self.userInfo];
}

- (void)startPreview {
    if (self.onlyAudio || self.isPreview) {
        return;
    }
    
    [self.api setPreviewViewMode:self.previewViewMode];
    [self.api setPreviewView:self.previewView];
    [self.api startPreview];
    
    self.isPreview = YES;
}

- (void)stopPreview {
    if (self.onlyAudio || !self.isPreview) {
        return; 
    }
    
    [self.api stopPreview];
    [self.api setPreviewView:nil];
    
    self.isPreview = NO;
    [self updateCaptureFirstFrameIfNeed];
}

- (void)setLiveExtraInfo:(NSString *)extraInfo {
    [self.api updateStreamExtraInfo:extraInfo];
    
    //TODO:目前自己的extraInfo不回调，待后续sdk添加update的callback再修改逻辑
    [self setExtraInfo:extraInfo toUser:self.userInfo];
}

- (void)setVolume:(NSUInteger)volume forUser:(ZegoUser *)user {
    BOOL isLocal = [user isEqual:self.userInfo];
    
    if (isLocal) {
        [self.api setCaptureVolume:(int)volume];
    }
    else {
        ZegoStream *stream = [self streamForUser:user];
        if (stream) {
            [self.api setPlayVolume:(int)volume ofStream:stream.streamID];
        }
    }
}

- (void)setLiveVideoView:(ZEGOView *)view viewMode:(ZegoVideoViewMode)mode forUser:(ZegoUser *)user; {
    if (self.onlyAudio) {
        return;
    }
    
    BOOL isSelf = !user || [user isEqual:self.userInfo];
    if (isSelf) {
        self.previewView = view;
        self.previewViewMode = mode;
        
        [self.api setPreviewView:view];
        [self.api setPreviewViewMode:mode];
        
        return;
    }
    
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (!info) {
        return;
    }
    
    info.videoView = view;
    info.viewMode = mode;
    
    if (info.firstFrame) {
        NSString *streamID = [self streamIDForUser:user];
        [self.api setViewMode:mode ofStream:streamID];
        [self.api updatePlayView:view ofStream:streamID];
    }
}

#pragma mark Custom Command

- (void)sendCustomCommand:(NSString *)content
               memberList:(NSArray<ZegoUser*> *)memberList
               completion:(ZegoSendCustomCmdCallback)completion; {
    Weakify(self);
    bool result = [self.api sendCustomCommand:memberList content:content completion:^(int errorCode, NSString *roomID) {
        Strongify(self);
        
        if (![roomID isEqualToString:self.roomInfo.roomID]) {
            return;
        }
        
        BOOL success = errorCode == 0;
        if (success) {
            if (completion) {
                completion(nil);
            }
            return;
        }
        
        if (completion) {
            NSError *error = [ZegoErrorHelper sendCustomCmdErrorWithCode:errorCode];
            completion(error);
        }
    }];
    
    if (!result) {
        if (completion) {
            NSError *error = [ZegoErrorHelper sendCustomCmdErrorWithCode:ZegoRoomParamErrorCode];
            completion(error);
        }
    }
}

#pragma mark - Actions

- (void)onLoginRoomComplete:(int)errorCode streamList:(NSArray <ZegoStream*>*)streamList roomInfo:(ZegoRoomInfo *)roomInfo completion:(ZegoLoginRoomCallback)completion {
    BOOL success = errorCode == 0;
    
    if (success) {
        BOOL isReconnect = self.isDisconnect;
        self.isDisconnect = NO;
        [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventLoginSuccess error:nil];
        
        if (isReconnect) {
            [self handleReconnectRoomStreams:streamList];
        }
        else {
            [self addStreams:streamList];
        }
        
        [self releaseTimeoutTimer];
        
        if (completion) {
            completion(nil);
            self.loginCallback = nil;
        }
    }
    else {
        NSError *error = [ZegoErrorHelper roomErrorWithCode:errorCode];
        [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventLoginFailed error:error];
        
        BOOL isCustomTokenError = errorCode == kLiveRoomThirdTokenAuthError;
        BOOL isAudienceCantCreateRoomError = errorCode == kLiveRoomAddUserError;
        if (self.autoReconnectRoom &&
            (isCustomTokenError || isAudienceCantCreateRoomError)) {
            [self zg_logoutRoom];
            [self endLoginRetryWithReason:kZegoRoomReconnectStopReasonParam];
            
            if (completion) {
                completion(error);
                self.loginCallback = nil;
            }
            
            return;
        }
        
        if (self.autoReconnectRoom) {
            [self reconnectRoomAfterReconnectInterval];
        }
        else if (completion) {
            completion(error);
        }
    }
}


#pragma mark - Private Methods

- (void)reset {
    self.roomInfo = nil;
    self.isDisconnect = NO;
    [self.allStreams removeAllObjects];
    [self.liveInfos removeAllObjects];
    self.loginCallback = nil;
}

#pragma mark Room Private Methods
- (void)setApiDelegate {
    [self.api setRoomDelegate:self];
    [self.api setPlayerDelegate:self];
    [self.api setPublisherDelegate:self];
    [self.api setLiveEventDelegate:self];
}

- (void)removeApiDelegate {
    [self.api setRoomDelegate:nil];
    [self.api setPlayerDelegate:nil];
    [self.api setPublisherDelegate:nil];
    [self.api setLiveEventDelegate:nil];
}

- (void)updateLoginStatusWithLoginEvent:(ZegoRoomLoginEvent)event error:(nullable NSError *)error {
    ZegoRoomLoginStatus status = self.loginStatus;
    
    switch (status) {
        case kZegoRoomLoginStatusLogout:{
            switch (event) {
                case kZegoRoomLoginEventLogin:
                    status = kZegoRoomLoginStatusStartLogin;
                    break;
                case kZegoRoomLoginEventLogout:
                    break;
                default:
                    NSAssert(NO, @"ZegoRoomManager error event with current status");
                    break;
            }
            break;
        }
        case kZegoRoomLoginStatusStartLogin:{
            switch (event) {
                case kZegoRoomLoginEventLoginSuccess:
                    status = kZegoRoomLoginStatusLogin;
                    break;
                case kZegoRoomLoginEventLogout:
                case kZegoRoomLoginEventLoginFailed:
                    status = kZegoRoomLoginStatusLogout;
                    break;
                case kZegoRoomLoginEventTempBroke:
                case kZegoRoomLoginEventReconnect://SDK目前登录逻辑待修改，暂时适配
                    break;
                default:
                    NSAssert(NO, @"ZegoRoomManager error event with current status");
                    break;
            }
            break;
        }
        case kZegoRoomLoginStatusLogin:{
            switch (event) {
                case kZegoRoomLoginEventTempBroke:
                    status = kZegoRoomLoginStatusTempBroken;
                    break;
                case kZegoRoomLoginEventReconnect://SDK目前登录逻辑待修改，暂时适配
                    break;
                case kZegoRoomLoginEventLogout:
                case kZegoRoomLoginEventKickOut:
                case kZegoRoomLoginEventDisconnect:
                    status = kZegoRoomLoginStatusLogout;
                    break;
                default:
                    NSAssert(NO, @"ZegoRoomManager error event with current status");
                    break;
            }
            break;
        }
        case kZegoRoomLoginStatusTempBroken:{
            switch (event) {
                case kZegoRoomLoginEventTempBroke:
                    break;
                case kZegoRoomLoginEventReconnect:
                    status = kZegoRoomLoginStatusLogin;
                    break;
                case kZegoRoomLoginEventLogout:
                case kZegoRoomLoginEventKickOut:
                case kZegoRoomLoginEventDisconnect:
                    status = kZegoRoomLoginStatusLogout;
                    break;
                default:
                    NSAssert(NO, @"ZegoRoomManager error event with current status");
                    break;
            }
            break;
        }
    }
    
    self.loginStatus = status;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate roomManager:self didLoginEventOccur:event loginStatus:self.loginStatus error:error];
    });
}

- (void)setupTimeoutTimer {
    if (self.timeoutTimter) {
        return;
    }
    
    NSTimeInterval timeoutInterval = self.reconnectTimeout ?:DBL_MAX;
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeoutInterval target:self selector:@selector(onLoginRetryTimeout) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    self.timeoutTimter = timer;
}

- (void)releaseTimeoutTimer {
    if (self.timeoutTimter) {
        [self.timeoutTimter invalidate];
        self.timeoutTimter = nil;
    }
}

- (void)onLoginRetryTimeout {
    NSError *error = [ZegoErrorHelper roomErrorWithCode:ZegoRoomLoginTimeoutErrorCode];
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventLoginFailed error:error];

    if (self.loginCallback) {
        self.loginCallback(error);
        self.loginCallback = nil;
    }

    [self endLoginRetryWithReason:kZegoRoomReconnectStopReasonTimeout];
}

- (void)endLoginRetryWithReason:(ZegoRoomReconnectStopReason)reason {
    [self zg_logoutRoom];
    [self releaseTimeoutTimer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate roomManager:self didAutoReconnectStop:reason];
    });
}

- (void)zg_logoutRoom {
    [self.api logoutRoom];
    
    //取消重连
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)reconnectRoomAfterReconnectInterval {
    if (self.autoReconnectRoom) {
        [self performSelector:@selector(reconnectRoom) withObject:nil afterDelay:self.reconnectInterval inModes:@[NSRunLoopCommonModes]];
    }
}

- (void)reconnectRoom {
    if (!self.autoReconnectRoom) {
        return;
    }

    [self joinRoom:self.roomInfo user:self.userInfo completion:self.loginCallback];
}

- (void)handleReconnectRoomStreams:(NSArray <ZegoStream*>*)streams {
    BOOL isSelfLiveBefore = self.isSelfLive;
    
    NSMutableSet<ZegoStream*>* remoteStreams = [NSMutableSet setWithArray:streams];
    NSMutableSet<ZegoStream*>* localStream = self.allStreams.mutableCopy;
    NSMutableSet<ZegoStream*>* reconnectStreams = self.allStreams.mutableCopy;
    
    [reconnectStreams intersectSet:remoteStreams];//streams to restart
    [localStream minusSet:remoteStreams];//streams to delete
    [remoteStreams minusSet:self.allStreams];//streams to add
    
    if (isSelfLiveBefore) {
        [self startUserLive:self.userInfo];
    }
    [self reconnectStreams:reconnectStreams.allObjects];//重连
    [self addStreams:remoteStreams.allObjects];//添加流
    [self deleteStreams:localStream.allObjects];//删除流
}

- (void)reconnectStreams:(NSArray <ZegoStream*>*)streams {
    for (ZegoStream *stream in streams) {
        ZegoUser *user = [[ZegoUser alloc] init];
        user.userId = stream.userID;
        user.userName = stream.userName;
        
        [self startUserLive:user];
    }
    
    [self updateStreamExtraInfo:streams];
}

- (void)addStreams:(NSArray <ZegoStream*>*)streams {
    [self.allStreams addObjectsFromArray:streams];
    
    for (ZegoStream *stream in streams) {
        ZegoUser *user = [[ZegoUser alloc] init];
        user.userId = stream.userID;
        user.userName = stream.userName;
        
        [self addLiveUser:user];
    }
    
    [self updateStreamExtraInfo:streams];
}

- (void)deleteStreams:(NSArray <ZegoStream*>*)streams {
    for (ZegoStream *stream in streams) {
        ZegoUser *user = [[ZegoUser alloc] init];
        user.userId = stream.userID;
        user.userName = stream.userName;
        
        [self removeLiveUser:user];
    }

    [self.allStreams minusSet:[NSSet setWithArray:streams]];
}

- (void)updateStreamExtraInfo:(NSArray <ZegoStream*>*)streams {
    for (ZegoStream *stream in streams) {
        ZegoUser *user = [[ZegoUser alloc] init];
        user.userId = stream.userID;
        user.userName = stream.userName;
        
        ZegoUserLiveInfo *info = [self liveInfoForUser:user];
        
        BOOL isExtraInfoUpdated = NO;
        if ((stream.extraInfo == nil && info.extraInfo != nil) ||
            (stream.extraInfo != nil && info.extraInfo == nil) ||
            ((stream.extraInfo != nil && info.extraInfo != nil) && ![stream.extraInfo isEqualToString:info.extraInfo])) {
                isExtraInfoUpdated = YES;
        }
        
        if (isExtraInfoUpdated) {
            [self setExtraInfo:stream.extraInfo toUser:user];
        }
    }
}


#pragma mark - Live Private Methods

- (void)addLiveUser:(ZegoUser *)user {
    if ([self.liveUsers containsObject:user]) {
        return;
    }
    
    self.liveInfos[user] = [[ZegoUserLiveInfo alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate roomManager:self didLiveUserJoin:user];
    });
    
    [self setStreamStatus:kZegoUserLiveStatusWaitConnect throw:nil toUser:user];
    
    [self startUserLive:user];
}

- (void)removeLiveUser:(ZegoUser *)user {
    if (![self.liveUsers containsObject:user]) {
        return;
    }
    
    //调用此方法时移除后续重试操作
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startUserLive:) object:user];
    
    [self stopUserLive:user];
    
    self.liveInfos[user] = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate roomManager:self didLiveUserLeave:user];
    });
}

//退出登录不需要回调removeLiveUser
- (void)releaseAllLiveUsers {
    for (ZegoUser *user in self.liveUsers) {
        [self stopUserLive:user];
    }
    
    [self.liveInfos removeAllObjects];
}

- (void)startUserLive:(ZegoUser *)user {
    //防止房间断连时reconnectLive调用该方法
    if (!self.isLogin) {
        return;
    }
    
    if ([user isEqual:self.userInfo]) {
        [self startPublish];
    }
    else {
        [self startPlayStreamWithUser:user];
    }
}

- (void)stopUserLive:(ZegoUser *)user {
    if ([user isEqual:self.userInfo]) {
        [self stopPublish];
    }
    else {
        [self stopPlayStreamWithUser:user];
    }
}

- (void)startPublish {
    NSString *streamID = [self getLiveIDWithUser:self.userInfo];
    [self.api startPublishing:streamID title:nil flag:ZEGO_JOIN_PUBLISH];
    
    [self setStreamStatus:kZegoUserLiveStatusConnecting throw:nil toUser:self.userInfo];
}

- (void)stopPublish {
    [self.api stopPublishing];
    [self updateCaptureFirstFrameIfNeed];
}

- (void)startPlayStreamWithUser:(ZegoUser *)user {
    NSString *streamID = [self streamIDForUser:user];
    [self.api startPlayingStream:streamID inView:nil];
    
    [self setStreamStatus:kZegoUserLiveStatusConnecting throw:nil toUser:user];
}

- (void)stopPlayStreamWithUser:(ZegoUser *)user {
    NSString *streamID = [self streamIDForUser:user];
    
    [self.api stopPlayingStream:streamID];
    [self.api updatePlayView:nil ofStream:streamID];
}

- (void)startUserLiveAfterReconnectInterval:(ZegoUser *)user {
    if (self.isLogin) {
        [self performSelector:@selector(startUserLive:) withObject:user afterDelay:self.reconnectInterval inModes:@[NSRunLoopCommonModes]];
    }
}

- (void)updateCaptureFirstFrameIfNeed {
    BOOL isCapture = self.isPreview || [self liveInfoForUser:self.userInfo].status != kZegoUserLiveStatusWaitConnect;
    
    if (!isCapture) {
        [self setFirstFrame:NO size:CGSizeZero toUser:self.userInfo];
    }
}

- (void)callbackAllLiveStreamError {
    for (ZegoUser *user in self.liveInfos.allKeys) {
        NSString *streamID = [self streamIDForUser:user];
        ZegoUserLiveInfo *info = [self liveInfoForUser:user];
        
        BOOL shouldCallbackError = info.streamStatus != kZegoUserLiveStatusWaitConnect;
        if (shouldCallbackError) {
            BOOL isSelf = [user isEqual:self.userInfo];
            if (isSelf) {
                [self onPublishStateUpdate:kLiveRoomTimeoutError streamID:streamID streamInfo:nil];
            }
            else {
                [self onPlayStateUpdate:kLiveRoomTimeoutError streamID:streamID];
            }
        }
    }
}


#pragma mark - Convenience Getter

- (nullable ZegoUserLiveInfo *)liveInfoForUser:(ZegoUser *)user {
    ZegoUserLiveInfo *info = self.liveInfos[user];
    
    BOOL isSelf = [user isEqual:self.userInfo];
    if (isSelf) {
        info.videoView = self.previewView;
        info.viewMode = self.previewViewMode;
        info.firstFrame = self.hasCaptureFirstFrame;
    }
    
    return info;
}

- (nullable ZegoStream *)streamForUser:(ZegoUser *)user {
    for (ZegoStream *stream in self.allStreams) {
        if ([stream.userID isEqualToString:user.userId]) {
            return stream;
        }
    }
    
    return nil;
}

- (nullable NSString *)streamIDForUser:(ZegoUser *)user {
    if ([user isEqual:self.userInfo]) {
        return [self getLiveIDWithUser:user];
    }
    return [self streamForUser:user].streamID;
}

- (ZegoUser *)userForStreamID:(NSString *)streamID {
    for (ZegoStream *stream in self.allStreams) {
        if ([stream.streamID isEqualToString:streamID]) {
            ZegoUser *user = [[ZegoUser alloc] init];
            user.userId = stream.userID;
            user.userName = stream.userName;
            
            return user;
        }
    }
    
    NSString *selfStreamID = [self getLiveIDWithUser:self.userInfo];
    if ([streamID isEqualToString:selfStreamID]) {
        return self.userInfo;
    }
    
    return nil;
}


#pragma mark - Convenience Setter

- (void)setStreamStatus:(ZegoUserLiveStatus)status throw:(NSError *)error toUser:(ZegoUser *)user {
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (info) {
        ZegoUserLiveStatus oldStatus = info.status;
        
        info.streamStatus = status;
        ZegoUserLiveStatus newStatus = info.status;
        
        if (newStatus != oldStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.liveDelegate roomManager:self didLiveStatusChange:status user:user error:error];
            });
        }
    }
}

- (void)setLiveStatus:(ZegoUserLiveStatus)status throw:(NSError *)error toUser:(ZegoUser *)user {
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (info) {
        ZegoUserLiveStatus oldStatus = info.status;
        
        info.liveStatus = status;
        ZegoUserLiveStatus newStatus = info.status;
        
        if (newStatus != oldStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.liveDelegate roomManager:self didLiveStatusChange:status user:user error:error];
            });
        }
    }
}

- (void)setExtraInfo:(NSString *)extraInfo toUser:(ZegoUser *)user {
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (info) {
        info.extraInfo = extraInfo;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.liveDelegate roomManager:self didExtraInfoUpdate:extraInfo user:user];
        });
    }
}

- (BOOL)setSoundLevel:(float)soundLevel toUser:(ZegoUser *)user {
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (info) {
        info.soundLevel = soundLevel;
        return YES;
    }
    
    return NO;
}

- (void)setFirstFrame:(BOOL)firstFrame size:(CGSize)size toUser:(ZegoUser *)user {
    BOOL isSelf = [user isEqual:self.userInfo];
    if (isSelf) {
        self.hasCaptureFirstFrame = firstFrame;
        
        if (firstFrame) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.liveDelegate roomManager:self didUserGetFirstFrame:user size:size];
            });
        }
        
        return;
    }
    
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (info) {
        info.firstFrame = firstFrame;
        
        if (firstFrame) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.liveDelegate roomManager:self didUserGetFirstFrame:user size:size];
            });
        }
    }
    
}

- (void)setUserLiveQuality:(ZegoUserLiveQuality *)quality toUser:(ZegoUser *)user {
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (info) {
        info.liveQuality = quality;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.liveDelegate roomManager:self didUserLiveQualityUpdate:quality user:user];
        });
    }
}

- (void)updateLiveRoomSoundLevelMonitorState {
    BOOL enable = self.isLogin && self.soundLevelMonitor;
    
    enable ? [ZegoSoundLevel.sharedInstance startSoundLevelMonitor]:[ZegoSoundLevel.sharedInstance stopSoundLevelMonitor];
    [ZegoSoundLevel.sharedInstance setSoundLevelDelegate:enable ? self:nil];
    [ZegoSoundLevel.sharedInstance setSoundLevelMonitorCycle:(self.soundLevelMonitorCycle*1000)];
}


#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    self.isDisconnect = YES;
    
    NSError *error = [ZegoErrorHelper roomKickoutErrorWithCode:reason];
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventKickOut error:error];
    
    [self callbackAllLiveStreamError];
    
    if (self.autoReconnectRoom) {
        [self endLoginRetryWithReason:kZegoRoomReconnectStopReasonKickout];
    }
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    self.isDisconnect = YES;
    
    NSError *error = [ZegoErrorHelper roomDisconnectErrorWithCode:errorCode];
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventDisconnect error:error];
    
    [self callbackAllLiveStreamError];
    
    if (self.autoReconnectRoom) {
        [self reconnectRoomAfterReconnectInterval];
    }
}

- (void)onTempBroken:(int)errorCode roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    NSError *error = [ZegoErrorHelper roomTempBrokeErrorWithCode:errorCode];
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventTempBroke error:error];
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    [self updateLoginStatusWithLoginEvent:kZegoRoomLoginEventReconnect error:nil];
}

- (void)onStreamUpdated:(int)type streams:(NSArray<ZegoStream*> *)streamList roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    if (type == ZEGO_STREAM_ADD) {
        [self addStreams:streamList];
    }
    else if (type == ZEGO_STREAM_DELETE) {
        [self deleteStreams:streamList];
    }
}

- (void)onStreamExtraInfoUpdated:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    for (ZegoStream *stream in streamList) {
        ZegoUser *user = [[ZegoUser alloc] init];
        user.userId = stream.userID;
        user.userName = stream.userName;
        
        [self setExtraInfo:stream.extraInfo toUser:user];
    }
}

- (void)onReceiveCustomCommand:(NSString *)fromUserID userName:(NSString *)fromUserName content:(NSString *)content roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomInfo.roomID]) {
        return;
    }
    
    ZegoUser *user = [[ZegoUser alloc] init];
    user.userId = fromUserID;
    user.userName = fromUserName;
    
    [self.delegate roomManager:self didRecvCustomCommand:user content:content];
}


#pragma mark - ZegoLiveEventDelegate

- (void)zego_onLiveEvent:(ZegoLiveEvent)event info:(NSDictionary<NSString*, NSString*>*)info {
    NSString *streamID = info[ZegoApiLiveEventStreamIDKey];
    ZegoUser *user = [self userForStreamID:streamID];
    
    ZegoUserLiveStatus newStatus;
    NSError *error;
    
    switch (event) {
        case Play_TempDisconnected:
        case Publish_TempDisconnected:
            newStatus = kZegoUserLiveStatusWaitConnect;
            error = [ZegoErrorHelper liveEventTempBrokeError];
            break;
        case Play_BeginRetry:
        case Publish_BeginRetry:
            newStatus = kZegoUserLiveStatusConnecting;
            break;
        case Play_RetrySuccess:
        case Publish_RetrySuccess:
            newStatus = kZegoUserLiveStatusLive;
            break;
        default:
            return;
    }
    
    [self setLiveStatus:newStatus throw:error toUser:user];
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    BOOL success = stateCode == 0;
    
    if (success) {
        [self setStreamStatus:kZegoUserLiveStatusLive throw:nil toUser:self.userInfo];
        return;
    }
    
    NSError *error = [ZegoErrorHelper publishErrorWithCode:stateCode];
    [self setStreamStatus:kZegoUserLiveStatusWaitConnect throw:error toUser:self.userInfo];
    [self updateCaptureFirstFrameIfNeed];

    [self startUserLiveAfterReconnectInterval:self.userInfo];
}

- (void)onCaptureVideoSizeChangedTo:(CGSize)size {
    BOOL sizeValid = !CGSizeEqualToSize(size, CGSizeZero);
    ZegoUserLiveInfo *info = [self liveInfoForUser:self.userInfo];
    
    if (sizeValid && !info.firstFrame) {
        [self setFirstFrame:YES size:size toUser:self.userInfo];
    }
    
    if (info.firstFrame) {
        [self.liveDelegate roomManager:self didUserVideoFrameChange:self.userInfo size:size];
    }
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    ZegoUserLiveQuality *publishQuality = [ZegoUserLiveQuality liveQualityWithPublishQuality:quality];
    [self setUserLiveQuality:publishQuality toUser:self.userInfo];
}


#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    BOOL success = stateCode == 0;
    ZegoUser *user = [self userForStreamID:streamID];
    
    if (success) {
        [self setStreamStatus:kZegoUserLiveStatusLive throw:nil toUser:user];
        return;
    }
    
    NSError *error = [ZegoErrorHelper playErrorWithCode:stateCode];
    [self setStreamStatus:kZegoUserLiveStatusWaitConnect throw:error toUser:user];
    
    //拉流失败重置firstFrame
    [self setFirstFrame:NO size:CGSizeZero toUser:user];
    
    [self startUserLiveAfterReconnectInterval:user];
}

- (void)onVideoSizeChangedTo:(CGSize)size ofStream:(NSString *)streamID {
    BOOL sizeValid = !CGSizeEqualToSize(size, CGSizeZero);
    ZegoUser *user = [self userForStreamID:streamID];
    ZegoUserLiveInfo *info = [self liveInfoForUser:user];
    
    if (sizeValid && !info.firstFrame) {
        [self setFirstFrame:YES size:size toUser:user];
        
        if (info.videoView) {
            [self.api setViewMode:info.viewMode ofStream:streamID];
            [self.api updatePlayView:info.videoView ofStream:streamID];
        }
    }
    
    if (info.firstFrame) {
        [self.liveDelegate roomManager:self didUserVideoFrameChange:user size:size];
    }
}

- (void)onRenderRemoteVideoFirstFrame:(NSString *)streamID {
    ZegoUser *user = [self userForStreamID:streamID];
    [self.liveDelegate roomManager:self didRenderRemoteUserVideoFrame:user];
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    ZegoUser *user = [self userForStreamID:streamID];
    ZegoUserLiveQuality *liveQuality = [ZegoUserLiveQuality liveQualityWithPlayQuality:quality];
    [self setUserLiveQuality:liveQuality toUser:user];
}


#pragma mark - ZegoSoundLevelDelegate

- (void)onSoundLevelUpdate:(NSArray<ZegoSoundLevelInfo *> *)soundLevels {
    NSMutableDictionary<ZegoUser*,NSNumber*> *levels = [NSMutableDictionary dictionary];
    
    for (ZegoSoundLevelInfo *soundLevel in soundLevels) {
        ZegoUser *user = [self userForStreamID:soundLevel.streamID];
        BOOL userExist = [self setSoundLevel:soundLevel.soundLevel toUser:user];
        
        if (userExist) {
            levels[user] = @(soundLevel.soundLevel);
        }
    }
    
    [self.liveDelegate roomManager:self didGetSoundLevels:levels];
}

- (void)onCaptureSoundLevelUpdate:(ZegoSoundLevelInfo *)captureSoundLevel {
    [self setSoundLevel:captureSoundLevel.soundLevel toUser:self.userInfo];
    
    ZegoUser *user = self.userInfo;
    if (!user) {//如果当前没有user则默认id=0
        user = [[ZegoUser alloc] init];
        user.userId = @"0";
        user.userName = @"0";
    }
    
    [self.liveDelegate roomManager:self
                 didGetSoundLevels:@{user:@(captureSoundLevel.soundLevel)}];
}


#pragma mark - Access

- (void)setUserInfo:(ZegoUser *)userInfo {
    _userInfo = userInfo;
    
    [ZegoLiveRoomApi setUserID:userInfo.userId userName:userInfo.userName];
}

- (BOOL)isLogin {
    return self.loginStatus == kZegoUserLiveStatusLive || self.loginStatus == kZegoRoomLoginStatusTempBroken;
}

- (BOOL)isSelfLive {
    return [self.liveUsers containsObject:self.userInfo];
}

- (NSArray<ZegoUser *> *)liveUsers {
    return self.liveInfos.allKeys;
}

- (void)setAutoReconnectRoom:(BOOL)autoReconnectRoom {
    if (_autoReconnectRoom == autoReconnectRoom) {
        return;
    }
    
    _autoReconnectRoom = autoReconnectRoom;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(reconnectRoomAfterReconnectInterval)
                                               object:nil];
}

- (void)setLoginStatus:(ZegoRoomLoginStatus)loginStatus {
    _loginStatus = loginStatus;
    [self updateLiveRoomSoundLevelMonitorState];
}

- (void)setSoundLevelMonitor:(BOOL)soundLevelMonitor {
    if (_soundLevelMonitor == soundLevelMonitor) {
        return;
    }
    
    _soundLevelMonitor = soundLevelMonitor;
    [self updateLiveRoomSoundLevelMonitorState];
}

- (void)setSoundLevelMonitorCycle:(NSTimeInterval)soundLevelMonitorCycle {
    if (soundLevelMonitorCycle > 3.0) {
        soundLevelMonitorCycle = 3.0;
    }
    else if (soundLevelMonitorCycle < 0.1) {
        soundLevelMonitorCycle = 0.1;
    }
    
    _soundLevelMonitorCycle = soundLevelMonitorCycle;
    [ZegoSoundLevel.sharedInstance setSoundLevelMonitorCycle:(soundLevelMonitorCycle*1000)];
}

@end


@implementation ZegoRoomManager (ZegoRoomManagerIDGenerateDelegate)

- (NSString *)genLiveIDWithUser:(ZegoUser *)user {
    NSString *liveID = user.userId;
    NSString *roomIDMD5 = self.roomInfo.roomID.zg_md5;
    NSString *liveIDWithRoomID = [NSString stringWithFormat:@"%@-%@",roomIDMD5, liveID];
    return liveIDWithRoomID;
}

- (NSString *)getLiveIDWithUser:(ZegoUser *)user {
    NSString *liveID = self.idGenDelegate ? [self.idGenDelegate genLiveIDWithUser:user]:[self genLiveIDWithUser:user];
    return liveID;
}

@end
