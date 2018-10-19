#import "RNReactNativeMessageUi.h"

#if __has_include("RCTConvert.h")
#import "RCTConvert.h"
#else
#import <React/RCTConvert.h>
#endif

#if __has_include("RCTLog.h")
#import "RCTLog.h"
#else
#import <React/RCTLog.h>
#endif

#if __has_include("RCTUtils.h")
#import "RCTUtils.h"
#else
#import <React/RCTUtils.h>
#endif

#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#if __has_include("RCTEventDispatcher.h")
#import "RCTEventDispatcher.h"
#else
#import <React/RCTEventDispatcher.h>
#endif

#if __has_include("RCTUIManager.h")
#import "RCTUIManager.h"
#else
#import <React/RCTUIManager.h>
#endif

@import MessageUI;

static NSString *const RNReactNativeMessageUiErrorDomain = @"RNReactNativeMessageUiErrorDomain";

typedef NS_ENUM(NSInteger, RNReactNativeMessageUiError) {
    RNReactNativeMessageUiErrorUnknown = 0,
    RNReactNativeMessageUiErrorCanNotSendText,
    RNReactNativeMessageUiErrorCanNotSentEmail,
    RNReactNativeMessageUiErrorActionUnavailableInAppExtension
};

#pragma mark - Class Definition

@interface RNReactNativeMessageUi ()<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
// Use NSMapTable, as MFMessageComposeViewController do not implement <NSCopying>
// which is required for NSDictionary keys
@property (nonatomic, strong, nonnull) NSMapTable *callbacks;
@end

@implementation RNReactNativeMessageUi

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

#pragma mark - Initializers and Dealocator

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(messageComposeTextMessageAvailabilityReceived:)
         name:MFMessageComposeViewControllerTextMessageAvailabilityDidChangeNotification
         object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:MFMessageComposeViewControllerTextMessageAvailabilityDidChangeNotification
     object:nil];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (NSDictionary *)constantsToExport
{
    return @{@"MessageUIManagerErrorDomain"             : RNReactNativeMessageUiErrorDomain,
             @"MessageUIManagerErrorUnknown"            : @(RNReactNativeMessageUiErrorUnknown),
             @"MessageUIManagerErrorCanNotSendText"     : @(RNReactNativeMessageUiErrorCanNotSendText),
             @"MessageUIManagerErrorCanNotSentEmail"    : @(RNReactNativeMessageUiErrorCanNotSentEmail),
             @"MessageUIManagerErrorActionUnavailableInAppExtension" : @(RNReactNativeMessageUiErrorActionUnavailableInAppExtension),
             @"MessageComposeResultCancelled"   : @(MessageComposeResultCancelled),
             @"MessageComposeResultSent"        : @(MessageComposeResultSent),
             @"MessageComposeResultFailed"      : @(MessageComposeResultFailed),
             @"MailComposeResultCancelled"      : @(MFMailComposeResultCancelled),
             @"MailComposeResultSaved"          : @(MFMailComposeResultSaved),
             @"MailComposeResultSent"           : @(MFMailComposeResultSent),
             @"MailComposeResultFailed"         : @(MFMailComposeResultFailed),
             @"MailComposeErrorCodeSaveFailed"  : @(MFMailComposeErrorCodeSaveFailed),
             @"MailComposeErrorCodeSendFailed"  : @(MFMailComposeErrorCodeSendFailed)};
}

#pragma mark - Accessors Methods

- (NSMapTable *)callbacks
{
    if (!_callbacks) {
        _callbacks = [NSMapTable strongToStrongObjectsMapTable];
    }
    return _callbacks;
}

#pragma mark - Public Methods
/// Returns YES if the device can send text messages or NO if it cannot.
RCT_EXPORT_METHOD(canSendText:(RCTResponseSenderBlock)callback)
{
    callback(@[@([MFMessageComposeViewController canSendText])]);
}

/// Returns YES if the device can send attachments in MMS or iMessage messages, or NO otherwise.
RCT_EXPORT_METHOD(canSendAttachments:(RCTResponseSenderBlock)callback)
{
    callback(@[@([MFMessageComposeViewController canSendAttachments])]);
}

/// Returns YES if the device can include subject lines in messages, or NO otherwise.
RCT_EXPORT_METHOD(canSendSubject:(RCTResponseSenderBlock)callback)
{
    callback(@[@([MFMessageComposeViewController canSendSubject])]);
}

/// Returns YES if a file with the specified UTI can be attached to the message, or NO otherwise.
/// @param uti The UTI (Uniform Type Identifier) in question.
RCT_EXPORT_METHOD(isSupportedAttachmentUTI:(NSString *)uti callback:(RCTResponseSenderBlock)callback)
{
    callback(@[@([MFMessageComposeViewController isSupportedAttachmentUTI:uti])]);
}

/// Returns YES if the user has set up the device for sending email, or NO otherwise.
RCT_EXPORT_METHOD(canSendMail:(RCTResponseSenderBlock)callback)
{
    callback(@[@([MFMailComposeViewController canSendMail])]);
}

RCT_EXPORT_METHOD(showMessageComposeWithOptions:(NSDictionary *)options
                  callback:(RCTResponseSenderBlock)callback)
{
    if (![MFMessageComposeViewController canSendText]) {
        NSError *error = [NSError errorWithDomain:RNReactNativeMessageUiErrorDomain
                                             code:RNReactNativeMessageUiErrorCanNotSendText
                                         userInfo:nil];
        callback(@[error.localizedDescription]);
        return;
    }
    
    if (RCTRunningInAppExtension()) {
        RCTLogError(@"Unable to show message compose from app extension");
        NSError *error = [NSError errorWithDomain:RNReactNativeMessageUiErrorDomain
                                             code:RNReactNativeMessageUiErrorActionUnavailableInAppExtension
                                         userInfo:nil];
        callback(@[error.localizedDescription]);
        return;
    }
    
    // Find the topmost displayed view controller
    UIViewController *controller = RCTKeyWindow().rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    
    if (controller == nil) {
        RCTLogError(@"Tried to display message compose but there is no application window. options: %@", options);
        return;
    }
    
    NSString *body = [RCTConvert NSString:options[@"body"]];
    NSArray<NSString *> *recipients = [RCTConvert NSStringArray:options[@"recipients"]];
    BOOL disableUserAttachments = [RCTConvert BOOL:options[@"disableUserAttachments"]];
    
    // Create a new message compose instance
    MFMessageComposeViewController *messageComposeController = [MFMessageComposeViewController new];
    messageComposeController.messageComposeDelegate = self;
    
    // Configure the fields of the interface.
    [messageComposeController setBody:body];
    [messageComposeController setRecipients:recipients];
    if (disableUserAttachments) {
        [messageComposeController disableUserAttachments];
    }
    
    // Register callback
    [self.callbacks setObject:callback forKey:messageComposeController];
    
    // Present the view controller modally.
    [controller presentViewController:messageComposeController animated:YES completion:nil];
    
    // Apply desired tint color
    messageComposeController.view.tintColor = [RCTConvert UIColor:options[@"tintColor"]];
}

RCT_EXPORT_METHOD(showEmailComposeWithOptions:(NSDictionary *)options
                  callback:(RCTResponseSenderBlock)callback)
{
    if (![MFMailComposeViewController canSendMail]) {
        NSError *error = [NSError errorWithDomain:RNReactNativeMessageUiErrorDomain
                                             code:RNReactNativeMessageUiErrorCanNotSendText
                                         userInfo:nil];
        callback(@[error.localizedDescription]);
        return;
    }
    if (RCTRunningInAppExtension()) {
        RCTLogError(@"Unable to show mail composer from app extension");
        NSError *error = [NSError errorWithDomain:RNReactNativeMessageUiErrorDomain
                                             code:RNReactNativeMessageUiErrorActionUnavailableInAppExtension
                                         userInfo:nil];
        callback(@[error.localizedDescription]);
        return;
    }
    
    // find the topmost displayed view controller
    UIViewController *controller = RCTKeyWindow().rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    
    if (controller == nil) {
        RCTLogError(@"Tried to display mail composer but there is no application window. options: %@", options);
        return;
    }
    
    NSString *subject = [RCTConvert NSString:options[@"subject"]];
    NSString *body = [RCTConvert NSString:options[@"body"]];
    NSArray<NSString *> *toRecipients = [RCTConvert NSStringArray:options[@"toRecipients"]];
    NSArray<NSString *> *ccRecipients = [RCTConvert NSStringArray:options[@"ccRecipients"]];
    NSArray<NSString *> *bccRecipients = [RCTConvert NSStringArray:options[@"bccRecipients"]];
    
    // create a new mail composer instance
    MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
    composeVC.mailComposeDelegate = self;
    
    // Configure the fields of the interface.
    [composeVC setToRecipients:toRecipients];
    [composeVC setCcRecipients:ccRecipients];
    [composeVC setBccRecipients:bccRecipients];
    [composeVC setSubject:subject];
    [composeVC setMessageBody:body isHTML:NO];
    
    // Register callback
    [self.callbacks setObject:callback forKey:composeVC];
    
    // Present the view controller modally.
    [controller presentViewController:composeVC animated:YES completion:nil];
    
    // Apply desired tint color
    composeVC.view.tintColor = [RCTConvert UIColor:options[@"tintColor"]];
}

#pragma mark - MFMessageComposeViewControllerDelegate Methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    RCTResponseSenderBlock callback = [self.callbacks objectForKey:controller];
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (callback) {
        callback(@[[NSNull null],@(result)]);
        [self.callbacks removeObjectForKey:controller];
    } else {
        RCTLogWarn(@"No callback registered for messageComposeViewController:didFinishWithResult: %@", controller.title);
    }
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(nullable NSError *)error
{
    RCTResponseSenderBlock callback = [self.callbacks objectForKey:controller];
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (callback) {
        callback(@[error ? error.localizedDescription : [NSNull null], @(result)]);
        [self.callbacks removeObjectForKey:controller];
    } else {
        RCTLogWarn(@"No callback registered for mailComposeController:didFinishWithResult:error: %@", controller.title);
    }
}

#pragma mark - NSNotification Handlers

- (void)messageComposeTextMessageAvailabilityReceived:(NSNotification *)notification
{
    NSNumber *availability = notification.userInfo[MFMessageComposeViewControllerTextMessageAvailabilityKey];
    [self.bridge.eventDispatcher sendAppEventWithName:@"TextMessageAvailability"
                                                 body:@{@"availability": availability}];
}

@end
