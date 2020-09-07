//Lightmann
//Made during COVID-19
//MsgSwap

#import "Headers.h"
#import "MsgSwapController.h"


//initialize my controller
%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;

    [MsgSwapController sharedInstance];
    
}
%end


//initialize plugin manager
%hook CKBalloonPluginManager
+ (instancetype)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}
%end


//set cell plugin  
%hook CKTranscriptCollectionViewController
-(void)_updateTraitsIfNecessary{
	%orig;

	[[((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer].cell setPlugin:((CKBalloonPluginManager*)[%c(CKBalloonPluginManager) sharedInstance]).visibleDrawerPlugins[0]];
}
%end


%hook CKMessageEntryView
//hide camera button since that's what's being replaced
-(void)setPhotoButton:(CKEntryViewButton *)arg1 {
	%orig;

	[arg1 setHidden:YES];
}

//Additional footer setup
-(void)setFrame:(CGRect)frame{
	%orig;

	MsgSwapFooter *footer = [((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer];

	footer.appStripLayout = self.appStrip.appStripLayout;
	footer.delegate = self;
	footer.dataSource = self.appStrip.dataSource;
	footer.cameraButton = self.photoButton;//for easier access w gesture below V

	//adds longpress gesture to activate cameraButton (that was replaced w photos cell)
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:footer action:@selector(clickCameraButton:)];
	longPress.minimumPressDuration = 0.35f;
	[footer addGestureRecognizer:longPress];

	[self.inputButtonContainerView addSubview:[((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer]];
}

//hides my cell when caret ">" is visible
-(void)updateTextViewsForShouldHideCaret:(BOOL)arg1 {
	%orig;

	if(self.arrowButton.alpha == 1){
		[((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer].hidden = YES;
	}
	if(self.arrowButton.alpha == 0){
		[((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer].hidden = NO;
	}
}

%end

//prevents cell from moving up when entryview expands/shrinks (after a newline is created/deleted)
%hook CKMessageEntryContentView
-(void)layoutSubviews{
	%orig;
	
	CGRect frame = [((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer].frame;
	[((MsgSwapController*)[%c(MsgSwapController) sharedInstance]) footer].frame = CGRectMake(frame.origin.x, (self.frame.size.height-35), frame.size.width, frame.size.height);
}
%end
