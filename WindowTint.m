#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <math.h>
#import <unistd.h>

@interface BorderView : NSView
@property(nonatomic, strong) NSColor *tint;
@property(nonatomic, copy) NSString *label;
@property(nonatomic) BOOL showsLabel;
@end

@implementation BorderView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _tint = NSColor.systemGreenColor;
        _label = @"";
        _showsLabel = NO;
    }
    return self;
}
- (void)setTint:(NSColor *)tint { _tint = tint; [self setNeedsDisplay:YES]; }
- (void)setLabel:(NSString *)label { _label = [label copy]; [self setNeedsDisplay:YES]; }
- (void)setShowsLabel:(BOOL)showsLabel { _showsLabel = showsLabel; [self setNeedsDisplay:YES]; }
- (void)drawRect:(NSRect)dirtyRect {
    NSRect edge = NSInsetRect(self.bounds, 4, 4);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:edge xRadius:11 yRadius:11];
    [[self.tint colorWithAlphaComponent:0.94] setStroke];
    path.lineWidth = 5;
    [path stroke];

    if (!self.showsLabel) return;
    NSRect badge = NSMakeRect(100, self.bounds.size.height - 34, MIN(180, self.bounds.size.width - 115), 22);
    [[self.tint colorWithAlphaComponent:0.96] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:badge xRadius:7 yRadius:7] fill];
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSTextAlignmentCenter;
    [self.label drawInRect:NSInsetRect(badge, 5, 3) withAttributes:@{
        NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: NSColor.whiteColor,
        NSParagraphStyleAttributeName: paragraph
    }];
}
@end

@interface OverlayPanel : NSPanel @end
@implementation OverlayPanel
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }
@end

@interface WindowTintController : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSDictionary<NSString *, NSDictionary *> *styles;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, OverlayPanel *> *panels;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) CVDisplayLinkRef displayLink;
@property(nonatomic) BOOL refreshScheduled;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSValue *> *lastFrames;
@property(nonatomic, copy) NSArray<NSNumber *> *lastWindowOrder;
@property(nonatomic) NSTimeInterval settleUntil;
@property(nonatomic) BOOL panelsHiddenForTransition;
@property(nonatomic) BOOL missionControlActive;
@property(nonatomic) BOOL enabled;
- (void)refresh;
@end

static CVReturn WindowTintDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                              const CVTimeStamp *now,
                                              const CVTimeStamp *outputTime,
                                              CVOptionFlags flagsIn,
                                              CVOptionFlags *flagsOut,
                                              void *context) {
    WindowTintController *controller = (__bridge WindowTintController *)context;
    @synchronized (controller) {
        if (controller.refreshScheduled) return kCVReturnSuccess;
        controller.refreshScheduled = YES;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (controller) { controller.refreshScheduled = NO; }
        [controller refresh];
    });
    return kCVReturnSuccess;
}

@implementation WindowTintController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.styles = @{
        @"com.openai.codex": @{ @"name": @"CODEX / CHATGPT", @"color": [NSColor colorWithRed:0.07 green:0.62 blue:0.49 alpha:1] },
        @"com.tencent.workbuddy.mac": @{ @"name": @"WORKBUDDY", @"color": [NSColor colorWithRed:0.26 green:0.43 blue:0.96 alpha:1] },
        @"com.anthropic.claudefordesktop": @{ @"name": @"CLAUDE", @"color": [NSColor colorWithRed:0.85 green:0.39 blue:0.16 alpha:1] },
        @"com.bot.neotix.doubao": @{ @"name": @"豆包", @"color": [NSColor colorWithRed:0.10 green:0.40 blue:0.94 alpha:1] },
        @"com.bytedance.macos.feishu": @{ @"name": @"飞书", @"color": [NSColor colorWithRed:0.12 green:0.63 blue:0.96 alpha:1] },
        @"com.google.Chrome": @{ @"name": @"GOOGLE CHROME", @"color": [NSColor colorWithRed:0.91 green:0.23 blue:0.20 alpha:1] },
        @"com.tencent.xinWeChat": @{ @"name": @"微信", @"color": [NSColor colorWithRed:0.06 green:0.64 blue:0.29 alpha:1] },
        @"com.apple.finder": @{ @"name": @"访达", @"color": [NSColor colorWithRed:0.37 green:0.45 blue:0.91 alpha:1] },
        @"com.kingsoft.wpsoffice.mac": @{ @"name": @"WPS OFFICE", @"color": [NSColor colorWithRed:0.90 green:0.19 blue:0.19 alpha:1] }
    };
    self.enabled = YES;
    self.panels = [NSMutableDictionary new];
    self.lastFrames = [NSMutableDictionary new];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [self setupMenu];
    if (CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink) == kCVReturnSuccess) {
        CVDisplayLinkSetOutputCallback(_displayLink, WindowTintDisplayLinkCallback, (__bridge void *)self);
        CVDisplayLinkStart(_displayLink);
    } else {
        self.timer = [NSTimer timerWithTimeInterval:(1.0 / 120.0) target:self selector:@selector(refresh) userInfo:nil repeats:YES];
        self.timer.tolerance = 0;
        [NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    NSNotificationCenter *workspaceNotifications = NSWorkspace.sharedWorkspace.notificationCenter;
    [workspaceNotifications addObserver:self selector:@selector(workspaceTransition:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [workspaceNotifications addObserver:self selector:@selector(workspaceTransition:) name:NSWorkspaceActiveSpaceDidChangeNotification object:nil];
    [self refresh];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (_displayLink) {
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
        _displayLink = NULL;
    }
}

- (void)setupMenu {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"rectangle.inset.filled" accessibilityDescription:@"WindowTint"];
    NSMenu *menu = [NSMenu new];
    NSMenuItem *toggle = [[NSMenuItem alloc] initWithTitle:@"关闭窗口边框" action:@selector(toggle:) keyEquivalent:@""];
    toggle.target = self;
    [menu addItem:toggle];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出 WindowTint" action:@selector(quit:) keyEquivalent:@"q"];
    quit.target = self;
    [menu addItem:quit];
    self.statusItem.menu = menu;
}

- (void)toggle:(NSMenuItem *)item {
    self.enabled = !self.enabled;
    item.title = self.enabled ? @"关闭窗口边框" : @"开启窗口边框";
    if (!self.enabled) [self hideAllPanels];
}
- (void)quit:(id)sender { [NSApp terminate:nil]; }

- (void)refresh {
    if (!self.enabled) return;
    NSMutableArray<NSDictionary *> *candidates = [NSMutableArray new];
    NSMutableDictionary<NSNumber *, NSValue *> *nextFrames = [NSMutableDictionary new];
    NSMutableArray<NSNumber *> *nextWindowOrder = [NSMutableArray new];
    NSUInteger shrinkingWindowCount = 0;
    NSUInteger expandingWindowCount = 0;
    CGFloat largestFrameDelta = 0;
    CGWindowListOption options = kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements;
    NSArray<NSDictionary *> *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(options, kCGNullWindowID));
    for (NSDictionary *window in windows) {
        NSNumber *ownerPID = window[(__bridge NSString *)kCGWindowOwnerPID];
        NSNumber *layer = window[(__bridge NSString *)kCGWindowLayer];
        NSNumber *number = window[(__bridge NSString *)kCGWindowNumber];
        NSNumber *alpha = window[(__bridge NSString *)kCGWindowAlpha];
        NSDictionary *dictionary = window[(__bridge NSString *)kCGWindowBounds];
        CGRect bounds;
        if (ownerPID.intValue == getpid() || layer.intValue != 0 || alpha.doubleValue == 0 ||
            !number || !CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)dictionary, &bounds) ||
            bounds.size.width <= 100 || bounds.size.height <= 100) continue;

        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:ownerPID.intValue];
        if (!app || app.activationPolicy == NSApplicationActivationPolicyProhibited ||
            [app.bundleIdentifier isEqualToString:@"com.windowtint.app"] ||
            [app.localizedName isEqualToString:@"WindowTint"]) continue;
        NSRect frame = NSInsetRect([self appKitFrameForCGFrame:bounds], -6, -6);
        NSValue *frameValue = [NSValue valueWithRect:frame];
        NSValue *previousFrame = self.lastFrames[number];
        if (previousFrame) {
            CGFloat frameDelta = [self frameDeltaFrom:frame to:previousFrame.rectValue];
            if (frame.size.width < previousFrame.rectValue.size.width - 8 && frame.size.height < previousFrame.rectValue.size.height - 8) shrinkingWindowCount++;
            if (frame.size.width > previousFrame.rectValue.size.width + 8 && frame.size.height > previousFrame.rectValue.size.height + 8) expandingWindowCount++;
            largestFrameDelta = MAX(largestFrameDelta, frameDelta);
        }
        nextFrames[number] = frameValue;
        [nextWindowOrder addObject:number];
        [candidates addObject:@{ @"number": number, @"app": app, @"frame": frameValue }];
    }
    self.lastFrames = nextFrames;

    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (shrinkingWindowCount >= 2) {
        [self setMissionControlActive:YES];
        self.settleUntil = 0;
    }
    if (self.missionControlActive && expandingWindowCount >= 1 && largestFrameDelta > 24) {
        [self beginExitTransition];
    }
    if (now < self.settleUntil) {
        [self hideAllPanels];
        self.panelsHiddenForTransition = YES;
        return;
    }
    if (!self.missionControlActive) {
        [self hideAllPanels];
        self.panelsHiddenForTransition = YES;
        return;
    }

    BOOL needsOrdering = self.panelsHiddenForTransition || ![nextWindowOrder isEqualToArray:self.lastWindowOrder];
    self.panelsHiddenForTransition = NO;
    self.lastWindowOrder = nextWindowOrder.copy;
    NSMutableSet<NSNumber *> *visibleWindows = [NSMutableSet setWithArray:nextWindowOrder];
    for (NSDictionary *candidate in candidates) {
        NSNumber *number = candidate[@"number"];
        NSRunningApplication *app = candidate[@"app"];
        NSRect frame = [candidate[@"frame"] rectValue];
        OverlayPanel *panel = self.panels[number];
        BOOL isNewPanel = !panel;
        if (!panel) {
            panel = [self newOverlayPanel];
            self.panels[number] = panel;
        }
        if (!NSEqualRects(panel.frame, frame)) [panel setFrame:frame display:NO animate:NO];
        if (isNewPanel) {
            NSDictionary *style = [self styleForApplication:app];
            BorderView *view = (BorderView *)panel.contentView;
            view.tint = style[@"color"];
            view.label = style[@"name"];
            view.showsLabel = self.missionControlActive;
        }
        if (needsOrdering || isNewPanel) [panel orderWindow:NSWindowAbove relativeTo:number.integerValue];
    }
    for (NSNumber *number in self.panels.allKeys.copy) {
        if (![visibleWindows containsObject:number]) {
            [self.panels[number] orderOut:nil];
            [self.panels removeObjectForKey:number];
        }
    }
}

- (CGFloat)frameDeltaFrom:(NSRect)frame to:(NSRect)other {
    return MAX(MAX(fabs(frame.origin.x - other.origin.x), fabs(frame.origin.y - other.origin.y)),
               MAX(fabs(frame.size.width - other.size.width), fabs(frame.size.height - other.size.height)));
}

- (void)workspaceTransition:(NSNotification *)notification {
    if (!self.enabled) return;
    [self beginExitTransition];
}

- (void)beginExitTransition {
    [self setMissionControlActive:NO];
    self.settleUntil = NSProcessInfo.processInfo.systemUptime + 0.20;
    self.panelsHiddenForTransition = YES;
    [self hideAllPanels];
}

- (void)setMissionControlActive:(BOOL)active {
    if (_missionControlActive == active) return;
    _missionControlActive = active;
    for (OverlayPanel *panel in self.panels.allValues) ((BorderView *)panel.contentView).showsLabel = active;
}

- (OverlayPanel *)newOverlayPanel {
    OverlayPanel *panel = [[OverlayPanel alloc] initWithContentRect:NSZeroRect
                                                           styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel)
                                                             backing:NSBackingStoreBuffered
                                                               defer:NO];
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = NO;
    panel.ignoresMouseEvents = YES;
    panel.animationBehavior = NSWindowAnimationBehaviorNone;
    panel.level = NSNormalWindowLevel;
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorIgnoresCycle;
    panel.contentView = [[BorderView alloc] initWithFrame:NSZeroRect];
    return panel;
}

- (NSDictionary *)styleForApplication:(NSRunningApplication *)app {
    NSDictionary *known = self.styles[app.bundleIdentifier ?: @""];
    if (known) return known;
    NSArray<NSColor *> *palette = @[
        [NSColor colorWithRed:0.63 green:0.37 blue:0.92 alpha:1],
        [NSColor colorWithRed:0.93 green:0.48 blue:0.16 alpha:1],
        [NSColor colorWithRed:0.08 green:0.61 blue:0.72 alpha:1],
        [NSColor colorWithRed:0.87 green:0.27 blue:0.54 alpha:1]
    ];
    NSString *identifier = app.bundleIdentifier ?: app.localizedName ?: @"APP";
    NSUInteger hash = 2166136261u;
    for (const unsigned char *byte = (const unsigned char *)identifier.UTF8String; *byte; byte++) hash = (hash ^ *byte) * 16777619u;
    return @{ @"name": app.localizedName ?: @"APP", @"color": palette[hash % palette.count] };
}

- (void)hideAllPanels {
    for (OverlayPanel *panel in self.panels.allValues) [panel orderOut:nil];
}

- (NSRect)appKitFrameForCGFrame:(CGRect)cgFrame {
    NSRect desktop = NSZeroRect;
    for (NSScreen *screen in NSScreen.screens) desktop = NSUnionRect(desktop, screen.frame);
    return NSMakeRect(cgFrame.origin.x, NSMaxY(desktop) - cgFrame.origin.y - cgFrame.size.height, cgFrame.size.width, cgFrame.size.height);
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        WindowTintController *controller = [WindowTintController new];
        application.delegate = controller;
        [application run];
    }
    return 0;
}
