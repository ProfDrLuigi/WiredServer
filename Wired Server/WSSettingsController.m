//
//  UPreferences.m
//  DicomX
//
//  Created by nark on 20/03/11.
//  Copyright 2011 Read-Write. All rights reserved.
//

#import "WSSettingsController.h"
#import "WPAccountManager.h"
#import "WPConfigManager.h"
#import "WPExportManager.h"
#import "WPLogManager.h"
#import "WPPortChecker.h"
#import "WPSettings.h"
#import "WPWiredManager.h"



@interface WSSettingsController (Private)

- (void)_updateInstallationStatus;
- (void)_updateRunningStatus;
- (void)_updateSettings;
- (void)_updatePortStatus;
- (BOOL)_hasBeenUpdated;

- (BOOL)_install;
- (BOOL)_uninstall;
- (BOOL)_update;

- (void)_exportToFile:(NSString *)file;
- (void)_importFromFile:(NSString *)file;

- (NSView *)_viewForTag:(NSInteger)tag;
- (NSRect)_newFrameForNewContentView:(NSView *)view;

- (NSString *)_stringForPruneEventsType:(WPPruneEventsType)type;
- (WPPruneEventsType)_pruneEventsTypeForString:(NSString *)string;

@end


NSString * const WPHelperBundleID = @"fr.read-write.Wired-Server-Helper";


@implementation WSSettingsController


#pragma mark -
#pragma mark Class Methods

+ (NSString *)nibName
{
    return @"Settings";
}


#pragma mark -
#pragma mark Properties

@synthesize toolbar                     = _toolbar;
@synthesize generalPreferenceView       = _generalPreferenceView;
@synthesize networkPreferenceView       = _networkPreferenceView;
@synthesize filesPreferenceView			= _filesPreferenceView;
@synthesize advancedPreferenceView      = _advancedPreferenceView;
@synthesize logsPreferenceView          = _logsPreferenceView;
@synthesize updatePreferenceView        = _updatePreferenceView;

@synthesize versionTextField            = _versionTextField;
@synthesize installButton               = _installButton;
@synthesize installProgressIndicator    = _installProgressIndicator;

@synthesize statusImageView             = _statusImageView;
@synthesize statusTextField             = _statusTextField;
@synthesize startButton                 = _startButton;
@synthesize startProgressIndicator      = _startProgressIndicator;

@synthesize launchAutomaticallyButton   = _launchAutomaticallyButton;
@synthesize enableStatusMenuyButton     = _enableStatusMenuyButton;

@synthesize logTableView                = _logTableView;
@synthesize logTableColumn              = _logTableColumn;
@synthesize openLogButton               = _openLogButton;

@synthesize filesPopUpButton            = _filesPopUpButton;
@synthesize filesMenuItem               = _filesMenuItem;
@synthesize filesIndexButton			= _filesIndexButton;
@synthesize filesIndexTimeTextField		= _filesIndexTimeTextField;

@synthesize portTextField               = _portTextField;
@synthesize hostTextField               = _hostTextField;
@synthesize portStatusImageView         = _portStatusImageView;
@synthesize portStatusTextField         = _portStatusTextField;
@synthesize checkPortAgainButton        = _checkPortAgainButton;

@synthesize accountStatusTextField      = _accountStatusTextField;
@synthesize accountStatusImageView      = _accountStatusImageView;
@synthesize setPasswordButton           = _setPasswordButton;
@synthesize createAdminButton           = _createAdminButton;
@synthesize setPasswordForAdminButton   = _setPasswordForAdminButton;
@synthesize createNewAdminUserButton    = _createNewAdminUserButton;

@synthesize pruneEventsPopUpButton		= _pruneEventsPopUpButton;
@synthesize snapshotEnableButton		= _snapshotEnableButton;
@synthesize snapshotTextField           = _snapshotTextField;

@synthesize exportSettingsButton        = _exportSettingsButton;
@synthesize importSettingsButton        = _importSettingsButton;

@synthesize passwordPanel               = _passwordPanel;
@synthesize newyPasswordTextField       = _newPasswordTextField;
@synthesize verifyPasswordTextField     = _verifyPasswordTextField;
@synthesize passwordMismatchTextField   = _passwordMismatchTextField;

@synthesize revealButton                = _revealButton;

@synthesize accountManager              = _accountManager;
@synthesize configManager               = _configManager;
@synthesize exportManager               = _exportManager;
@synthesize logManager                  = _logManager;
@synthesize wiredManager                = _wiredManager;

@synthesize portChecker                 = _portChecker;
@synthesize portCheckerStatus           = _portCheckerStatus;
@synthesize portCheckerPort             = _portCheckerPort;

@synthesize currentViewTag              = _currentViewTag;

@synthesize greenDropImage              = _greenDropImage;
@synthesize redDropImage                = _redDropImage;
@synthesize grayDropImage               = _grayDropImage;

@synthesize dateFormatter               = _dateFormatter;

@synthesize logLines                    = _logLines;
@synthesize logRows                     = _logRows;
@synthesize logAttributes               = _logAttributes;



#pragma mark -
#pragma mark Lifecycle Methods

- (id)init {
    self = [super initWithWindowNibName:[[self class] nibName] owner:self];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_accountManager release];
    [_configManager release];
    [_exportManager release];
    [_logManager release];
    [_wiredManager release];
    [_portChecker release];
    
    [_greenDropImage release];
    [_redDropImage release];
    [_grayDropImage release];
    
    [_dateFormatter release];
    
    [_logLines release];
    [_logRows release];
    [_logAttributes release];
    
    [_queue release];
    
    [super dealloc];
}





#pragma mark -
#pragma mark Instance Methods

- (void)windowDidLoad {
    [super windowDidLoad];
    
    WPError		*error;
    NSURL       *url;
	   
    // check packaged and installed version to update wired if needed
	if(![[WPSettings settings] boolForKey:WPUninstalled]) {
		if(![[_wiredManager installedVersion] isEqualToString:[_wiredManager packagedVersion]]) {
			if([_wiredManager isInstalled] && [self _update]) {
				if([_wiredManager isRunning]) {
					if(![_wiredManager restartWithError:&error])
						[[error alert] beginSheetModalForWindow:[_startButton window]];
				}
			}
		}
	}
    
    url = [[NSBundle mainBundle] URLForResource:@"Wired Server Helper" withExtension:@"app"];
    
    if([[WISettings settings] boolForKey:WPEnableMenuItem]) {
        if(![WIStatusMenuManager isHelperRunning:WPHelperBundleID]) {
            [WIStatusMenuManager startHelper:url];
        }
    }
    
    // update components
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updateSettings];
	[self _updatePortStatus];

	
	[_logManager startReadingFromLog];
}

- (void)awakeFromNib {
	[self.window setContentSize:[self.generalPreferenceView frame].size];
	[[self.window contentView] addSubview:self.generalPreferenceView];
	[self.toolbar setSelectedItemIdentifier:@"General"];
	[self.window center];
	    
    _wiredManager	= [[WPWiredManager alloc] init];
	_accountManager	= [[WPAccountManager alloc] initWithDatabasePath:[_wiredManager pathForFile:@"database.sqlite3"]];
	_configManager	= [[WPConfigManager alloc] initWithConfigPath:[_wiredManager pathForFile:@"etc/wired.conf"]];
	_exportManager	= [[WPExportManager alloc] initWithWiredManager:_wiredManager];
	_logManager		= [[WPLogManager alloc] initWithLogPath:[_wiredManager pathForFile:@"wired.log"]];
	

	_portChecker	= [[WPPortChecker alloc] init];
	[_portChecker setDelegate:self];
    
    _greenDropImage	= [NSImage imageNamed:NSImageNameStatusAvailable];
	
    _redDropImage	= [NSImage imageNamed:NSImageNameStatusUnavailable];
    _grayDropImage = [NSImage imageNamed:NSImageNameStatusNone];
    
    [_filesPopUpButton selectItemAtIndex:1];
    [self loadInfo];
    
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterNormalNaturalLanguageStyle];
	
	_logLines = [[NSMutableArray alloc] init];
	_logRows = [[NSMutableArray alloc] init];
	
	_logAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [NSFont fontWithName:@"Monaco" size:9.0f],
                      NSFontAttributeName,
                      NULL];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(wiredStatusDidChange:)
     name:WPWiredStatusDidChangeNotification];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(logManagerDidReadLines:)
     name:WPLogManagerDidReadLinesNotification];
}


#pragma mark -

- (void)wiredStatusDidChange:(NSNotification *)notification {
	[self _updateSettings];
	[self _updateRunningStatus];
    
	if([_wiredManager isRunning]) {
        if ([[_hostTextField stringValue] length]==0){
            [self loadInfo];
        }
        [_hostTextField setEnabled:NO];
		_portCheckerStatus = WPPortCheckerUnknown;
        [_portChecker checkStatusForPort:[_portTextField intValue]];
	}
    
	[_startButton setEnabled:YES];
	[_startProgressIndicator stopAnimation:self];
    
	[self _updatePortStatus];
}

- (void)saveInfo {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if ([[_hostTextField stringValue] length] == 0) {
        [_hostTextField setStringValue:@"127.0.0.1"];
    }
    
    [prefs setObject:[_hostTextField stringValue]  forKey:@"Host"];
    [prefs synchronize];
}

- (void)loadInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"Host"] length]!=0)
        [_hostTextField setStringValue:[defaults stringForKey:@"Host"]];
    else
        [_hostTextField setStringValue:@"127.0.0.1"];
}

- (void)logManagerDidReadLines:(NSNotification *)notification {
	NSEnumerator	*enumerator;
	NSString		*line;
	NSSize			size;
	NSUInteger		rows;
	
	enumerator = [[notification object] objectEnumerator];
	
	while((line = [enumerator nextObject])) {
		rows = 1;
		size = [line sizeWithAttributes:_logAttributes];
		
		while(size.width > [_logTableColumn width]) {
			size.width -=  [_logTableColumn width];
			rows++;
		}
		
		[_logLines addObject:line];
		[_logRows addObject:[NSNumber numberWithUnsignedInteger:rows]];
	}
	
	[_logTableView reloadData];
	[_logTableView scrollRowToVisible:[_logLines count] - 1];
}

- (void)portChecker:(WPPortChecker *)portChecker didReceiveStatus:(WPPortCheckerStatus)status forPort:(NSUInteger)port {
	_portCheckerStatus	= status;
	_portCheckerPort	= port;
	
	[self _updatePortStatus];
}

#pragma mark -
#pragma mark Toolbar Methods

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [[toolbar items] valueForKey:@"itemIdentifier"];
}





#pragma mark -
#pragma mark IBAction Methods

- (IBAction)switchView:(id)sender {
	
	NSInteger tag = [sender tag];
	
	NSView *view = [self _viewForTag:tag];
	NSView *previousView = [self _viewForTag:self.currentViewTag];
	self.currentViewTag = tag;
	NSRect newFrame = [self _newFrameForNewContentView:view];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.1];
	
    if ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagShift)
	    [[NSAnimationContext currentContext] setDuration:1.0];
	
	[[[self.window contentView] animator] replaceSubview:previousView with:view];
	[[self.window animator] setFrame:newFrame display:YES];
	
	[NSAnimationContext endGrouping];
	
    
	if(tag == 1 && self.portCheckerStatus == WPPortCheckerUnknown)
		[self checkPortAgain:self];

}


#pragma mark -

- (IBAction)install:(id)sender {
	[self _install];
}


- (IBAction)uninstall:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Are you sure you want to uninstall Wired Server?", @"Uninstall dialog title")];
    [alert setInformativeText:NSLocalizedString(@"All your settings, accounts and other server data will be lost.", @"Uninstall dialog description")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Uninstall dialog button title")];
    [alert addButtonWithTitle:NSLocalizedString(@"Uninstall", @"Uninstall dialog button title")];
    NSInteger returnCode = [alert runModal];
    
    if (returnCode == NSAlertFirstButtonReturn) {
        return;
    } else {
        [self performSelector:@selector(_uninstall) afterDelay:0.1];
    }
}


- (IBAction)releaseNotes:(id)sender {
	NSString		*path;
	
	path = [[self bundle] pathForResource:@"wiredserverrnote" ofType:@"html"];
	
	[[WIReleaseNotesController releaseNotesController]
     setReleaseNotesWithHTML:[NSData dataWithContentsOfFile:path]];
	[[WIReleaseNotesController releaseNotesController] showWindow:self];
}


#pragma mark -

- (IBAction)start:(id)sender {
	WPError		*error;
	
	[_startButton setEnabled:NO];
	[_startProgressIndicator startAnimation:self];
	
	if(![_wiredManager startWithError:&error]) {
		[[error alert] beginSheetModalForWindow:[_startButton window]];
        
		[_startButton setEnabled:YES];
		[_startProgressIndicator stopAnimation:self];
	}
}



- (IBAction)stop:(id)sender {
	WPError		*error;
	
	[_startButton setEnabled:NO];
	[_startProgressIndicator startAnimation:self];
	
	if(![_wiredManager stopWithError:&error]) {
		[[error alert] beginSheetModalForWindow:[_startButton window]];
		
		[_startButton setEnabled:YES];
		[_startProgressIndicator stopAnimation:self];
	}
    
    [_hostTextField setEnabled:YES];
    [self saveInfo];
}

- (IBAction)launchAutomatically:(id)sender {
	[_wiredManager setLaunchesAutomatically:[_launchAutomaticallyButton state]];
}

- (IBAction)enableStatusMenuItem:(id)sender {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Wired Server Helper" withExtension:@"app"];
    BOOL menuItemEnabled = [_enableStatusMenuyButton state] == YES;
    
    if (!menuItemEnabled) {
        [WIStatusMenuManager setStartAtLogin:WPHelperBundleID enabled:NO];
        [WIStatusMenuManager stopHelper:url];
    }else {
        [WIStatusMenuManager startHelper:url];
        [WIStatusMenuManager setStartAtLogin:WPHelperBundleID enabled:YES];
        [_enableStatusMenuyButton setState:YES];
    }
    
    [[WISettings settings] setBool:menuItemEnabled forKey:WPEnableMenuItem];
}



#pragma mark -

- (IBAction)openLog:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[_wiredManager pathForFile:@"wired.log"]];
}



- (IBAction)crashReports:(id)sender {
	[[WICrashReportsController crashReportsController] setApplicationName:@"wired"];
	[[WICrashReportsController crashReportsController] showWindow:self];
}



#pragma mark -

- (IBAction)other:(id)sender {
    NSOpenPanel *openPanel;
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setTitle:NSLocalizedString(@"Select Files", @"Files dialog title")];
    [openPanel setPrompt:NSLocalizedString(@"Select", @"Files dialog button title")];
    [openPanel beginSheetModalForWindow:[_filesPopUpButton window] completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            WIError  *error = nil;
            if([_configManager setString:[[openPanel URL]path] forConfigWithName:@"files" andWriteWithError:&error]) {
                [_wiredManager makeServerReloadConfig];
                [_wiredManager performSelector:@selector(makeServerIndexFiles) withObject:nil afterDelay:3.0f];
            } else {
                [[error alert] beginSheetModalForWindow:[_filesPopUpButton window]];
            }
            [self _updateSettings];
        }
    }];
}
#pragma mark -

- (IBAction)index:(id)sender {
	[_wiredManager makeServerIndexFiles];
}


#pragma mark -

- (IBAction)reveal:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[_wiredManager rootPath]];
}

#pragma mark -

- (IBAction)checkPortAgain:(id)sender {
    if([_wiredManager isRunning]) {
        _portCheckerStatus = WPPortCheckerUnknown;
        
        [_portChecker checkStatusForPort:[_portTextField intValue]];
    }
    
    [self _updatePortStatus];
}

#pragma mark -

- (IBAction)pruneEvents:(id)sender {
    WIError		*error = nil;
	NSString	*string;
    
	string = [self _stringForPruneEventsType:(WPPruneEventsType)[_pruneEventsPopUpButton selectedTag]];
	
	if(![_configManager setString:string forConfigWithName:@"events time" andWriteWithError:&error]) {
		[[error alert] beginSheetModalForWindow:[self.snapshotTextField window]];
	}
	
	[self _updateSettings];
	[_wiredManager makeServerReloadConfig];
}


- (IBAction)snapshotEnable:(id)sender {
    WIError		*error = nil;
	NSString	*string;
    
    string = ([_snapshotEnableButton state] == NSModalResponseOK) ? @"yes" : @"no";
	
	if(![_configManager setString:string forConfigWithName:@"snapshots" andWriteWithError:&error]) {
		[[error alert] beginSheetModalForWindow:[self.snapshotTextField window]];
	}
	
	[self _updateSettings];
	[_wiredManager makeServerReloadConfig];
}




#pragma mark -

- (IBAction)setPasswordForAdmin:(id)sender {
	[_newPasswordTextField setStringValue:@""];
	[_verifyPasswordTextField setStringValue:@""];
	[_passwordMismatchTextField setHidden:YES];
	[_passwordPanel makeFirstResponder:_newPasswordTextField];
    
    [NSApp beginSheet:_passwordPanel modalForWindow:[self window] didEndBlock:^(NSModalResponse returnCode){
        WPError *error;
        [_passwordPanel close];
        if(returnCode == NSModalResponseOK) {
            if(![_accountManager setPassword:[_newPasswordTextField stringValue]
                      forUserAccountWithName:@"admin"
                           andWriteWithError:&error]) {
                [[error alert] beginSheetModalForWindow:[_setPasswordForAdminButton window]];
            }
            [self _updateSettings];
        }
    }];
     
}


- (IBAction)createNewAdminUser:(id)sender {
	[_newPasswordTextField setStringValue:@""];
	[_verifyPasswordTextField setStringValue:@""];
	[_passwordMismatchTextField setHidden:YES];
	[_passwordPanel makeFirstResponder:_newPasswordTextField];
    
    [NSApp beginSheet:_passwordPanel modalForWindow:[_createNewAdminUserButton window] didEndBlock:^(NSModalResponse returnCode){
        WPError *error;
        [_passwordPanel close];
            if(returnCode == NSModalResponseOK) {
                if(![_accountManager createNewAdminUserAccountWithName:@"admin"
                                                              password:[_newPasswordTextField stringValue]
                                                     andWriteWithError:&error]) {
                    [[error alert] beginSheetModalForWindow:[_setPasswordForAdminButton window]];
                }
                [self _updateSettings];
            }
    }];
}


- (void)createNewAdminUserPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WPError		*error;
	[_passwordPanel close];
    
    if(returnCode == NSModalResponseOK) {
		if(![_accountManager createNewAdminUserAccountWithName:@"admin"
													  password:[_newPasswordTextField stringValue]
											 andWriteWithError:&error]) {
			[[error alert] beginSheetModalForWindow:[_setPasswordForAdminButton window]];
		}
		
		[self _updateSettings];
	}
}



- (IBAction)submitPasswordSheet:(id)sender {
	NSString		*newPassword, *verifyPassword;
	
	newPassword		= [_newPasswordTextField stringValue];
	verifyPassword	= [_verifyPasswordTextField stringValue];
	
	if([newPassword isEqualToString:verifyPassword]) {
		[self submitSheet:sender];
	} else {
		NSBeep();
		
		[_passwordMismatchTextField setHidden:NO];
	}
}


#pragma mark -

- (IBAction)exportSettings:(id)sender {
	NSSavePanel		*savePanel;
	NSString		*file;
	
	file = [[_configManager stringForConfigWithName:@"name"] stringByAppendingPathExtension:@"WiredSettings"];
	
	savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredSettings"]];
    [savePanel setNameFieldStringValue:file];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setPrompt:NSLS(@"Export", @"Export panel button title")];
    
    [savePanel beginSheetModalForWindow:[_importSettingsButton window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK) {
            [self.window beginSheetModalForWindow:_activityWindow];
            
            [_activityProgressIndicator startAnimation:self];
            [_activityTextField setStringValue:@"Export Settings..."];
            
            NSString *path = [[savePanel URL] path];
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self _exportToFile:path];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSThread sleepForTimeInterval:1.0];
                    [_activityWindow orderOut:self];
                    [self.window endSheet:_activityWindow];
                });
            });
        }
    }];
}


- (IBAction)importSettings:(id)sender {
    WPError     *error = nil;
    NSOpenPanel *openPanel;
    NSAlert * alert = [[[NSAlert alloc] init] autorelease];
    
    if([_wiredManager isRunning]) {
        [alert setMessageText:@"Wired Server is running"];
        [alert setInformativeText:@"Your Wired Server is currently running and it's recommanded to stop it in order to perform the import operation. Stop and import ?"];
        [alert addButtonWithTitle:@"Stop and Import"];
        [alert addButtonWithTitle:@"Cancel"];
        NSInteger returnCode = [alert runModal];
        if (returnCode == NSAlertFirstButtonReturn) {
            [_wiredManager stopWithError:&error];
        } else {
            return;
        }
    }
    
    if(!error) {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseFiles:YES];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredSettings"]];
        [openPanel setPrompt:NSLS(@"Import", @"Import panel button title")];
        [openPanel beginSheetModalForWindow:[_importSettingsButton window] completionHandler:^(NSInteger result) {
            if(result == NSModalResponseOK) {
                [self.window beginSheetModalForWindow:_activityWindow];
                
                [_activityProgressIndicator startAnimation:self];
                [_activityTextField setStringValue:@"Import Settings..."];
                
                NSString *path = [[openPanel URL] path];
                
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    [self _importFromFile:path];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NSThread sleepForTimeInterval:1.0];
                        [_activityWindow orderOut:self];
                        [self.window endSheet:_activityWindow];
                    });
                });
            }
        }];
    } else {
        [NSApp presentError:(NSError *)error];
    }
}








#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_logLines count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [NSAttributedString attributedStringWithString:[_logLines objectAtIndex:row]
											   attributes:_logAttributes];
}



- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	if([_logRows count] < (NSUInteger) row)
		return 12.0;
	
	return [[_logRows objectAtIndex:row] unsignedIntegerValue] * 12.0;
}



#pragma mark -

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    WIError		*error = nil;
	NSString	*string;
    
    if([notification object] == _snapshotTextField) {
		string = [_snapshotTextField stringValue];
		
		if([_snapshotTextField intValue] > 60) {
			
			if(![_configManager setString:string forConfigWithName:@"snapshot time" andWriteWithError:&error])
				[[error alert] beginSheetModalForWindow:[self.snapshotTextField window]];
			
			[self _updateSettings];
			[_wiredManager makeServerReloadConfig];
		}
    } 
	else if([notification object] == _filesIndexTimeTextField) {
		string = [_filesIndexTimeTextField stringValue];
		
		if([_snapshotTextField intValue] > 60) {
			if(![_configManager setString:string forConfigWithName:@"index time" andWriteWithError:&error])
				[[error alert] beginSheetModalForWindow:[self.snapshotTextField window]];
			
			[self _updateSettings];
			[_wiredManager makeServerReloadConfig];
		}
	}
    

    /*
    else if([notification object] == _hostTextField) {
        string = [_hostTextField stringValue];
    
        if([[_hostTextField stringValue] length] == 0) {
            if(![_configManager setString:string forConfigWithName:@"host" andWriteWithError:&error])
                [[error alert] beginSheetModalForWindow:[_hostTextField window]];
         
            [self _updateSettings];
        }
    }
     */
    else if([notification object] == _portTextField) {
        string = [_portTextField stringValue];
                
        if([_portTextField intValue] >= 1024 && [_portTextField intValue] <= 65535) {
            if(![_configManager setString:string forConfigWithName:@"port" andWriteWithError:&error])
                [[error alert] beginSheetModalForWindow:[_portTextField window]];
            
            [self _updateSettings];
        }
    }
    
}



@end




#pragma mark -

@implementation WSSettingsController (Private)

- (void)_updateInstallationStatus {
	NSDictionary	*info, *localizedInfo;
	NSString		*version;
	
	version			= [_wiredManager installedVersion];
	info			= [[self bundle] infoDictionary];
	localizedInfo	= [[self bundle] localizedInfoDictionary];
	
	if(version) {
		[_versionTextField setStringValue:
         [NSSWF:NSLocalizedString(@"%@", @"Installation status (server version)"),
          version]];
        
	} else {
		[_versionTextField setStringValue:NSLocalizedString(@"Wired is not installed", @"Installation status")];
	}
	
	if([_wiredManager isInstalled]) {
		[_installButton setTitle:NSLocalizedString(@"Uninstall\u2026", @"Uninstall button title")];
		[_installButton setAction:@selector(uninstall:)];
	} else {
		[_installButton setTitle:NSLocalizedString(@"Install", @"Install button title")];
		[_installButton setAction:@selector(install:)];
	}
}

- (void)_updateRunningStatus {
    NSString *status;
    NSDate *launchDate;
    
    launchDate = [self.wiredManager launchDate];
    
    if (![self.wiredManager isInstalled]) {
        status = NSLocalizedString(@"Wired Server not found", @"Server status");
    }
    else if (![self.wiredManager isRunning]) {
        status = NSLocalizedString(@"Wired Server is not running", @"Server status");
    }
    else {
        if (launchDate) {
            status = [NSString stringWithFormat:NSLocalizedString(@"Wired Server is running since %@", @"Server status"),
                      [self.dateFormatter stringFromDate:launchDate]];
        } else {
            status = NSLocalizedString(@"Wired Server is running", @"Server status");
        }
    }
    
    [self.statusTextField setStringValue:status];
    
    if (![self.wiredManager isInstalled]) {
        [self.statusImageView setImage:self.grayDropImage];
        
        [self.startButton setTitle:NSLocalizedString(@"Start", @"Start button")];
        [self.startButton setEnabled:NO];
    }
    else if (![self.wiredManager isRunning]) {
        [self.statusImageView setImage:self.redDropImage];
        
        [self.startButton setTitle:NSLocalizedString(@"Start", @"Start button")];
        [self.startButton setEnabled:YES];
        [self.startButton setAction:@selector(start:)];
    }
    else {
        [self.statusImageView setImage:self.greenDropImage];
        
        [self.startButton setTitle:NSLocalizedString(@"Stop", @"Stop button")];
        [self.startButton setEnabled:YES];
        [self.startButton setAction:@selector(stop:)];
        [self.hostTextField setEnabled:NO];
    }
    
    [self.launchAutomaticallyButton setState:[self.wiredManager launchesAutomatically]];
}


- (void)_updateSettings {
	NSImage			*image;
	NSString		*string, *password;
    NSURL           *url;
	BOOL			snapshotsEnabled;
	
	if([_wiredManager isInstalled]) {
		string = [_configManager stringForConfigWithName:@"files"];
		
		if(string) {
			image = [[NSWorkspace sharedWorkspace] iconForFile:string];
			
			[image setSize:NSMakeSize(16.0, 16.0)];
			
			[_filesMenuItem setTitle:[[NSFileManager defaultManager] displayNameAtPath:string]];
			[_filesMenuItem setImage:image];
			[_filesMenuItem setRepresentedObject:string];
		}
        
		string = [_configManager stringForConfigWithName:@"port"];
		if(string)
			[_portTextField setStringValue:string];
        
		
		switch([_accountManager hasUserAccountWithName:@"admin" password:&password]) {
			case WPAccountFailed:
                [_accountStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
				[_accountStatusTextField setStringValue:NSLocalizedString(@"Could not read accounts file", @"Account status")];
                
                [NSImage imageNamed:NSImageNameStatusNone];
                
				[_setPasswordForAdminButton setEnabled:NO];
				[_createNewAdminUserButton setEnabled:NO];
				break;
                
			case WPAccountOldStyle:
				[_accountStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
				[_accountStatusTextField setStringValue:NSLocalizedString(@"Accounts file is in a previous format, start to upgrade it", @"Account status")];
                
				[_setPasswordForAdminButton setEnabled:NO];
				[_createNewAdminUserButton setEnabled:NO];
				break;
                
			case WPAccountNotFound:
				[_accountStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
				[_accountStatusTextField setStringValue:NSLocalizedString(@"No account with name \u201cadmin\u201d found", @"Account status")];
                
                [_setPasswordButton setEnabled:NO];
				[_setPasswordForAdminButton setEnabled:YES];
				[_createNewAdminUserButton setEnabled:YES];
				break;
                
			case WPAccountOK:                
				if([password length] == 0 || [password isEqualToString:[@"" SHA1]]) {
					[_accountStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
					[_accountStatusTextField setStringValue:NSLocalizedString(@"Account with name \u201cadmin\u201d has no password set", @"Account status")];
				} else {
					[_accountStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
					[_accountStatusTextField setStringValue:NSLocalizedString(@"Account with name \u201cadmin\u201d has a password set", @"Account status")];
				}
                
                [_setPasswordButton setEnabled:YES];
				[_setPasswordForAdminButton setEnabled:YES];
				[_createNewAdminUserButton setEnabled:YES];
				break;
		}
		
		string = [_configManager stringForConfigWithName:@"events time"];
		[_pruneEventsPopUpButton selectItemWithTag:[self _pruneEventsTypeForString:string]];

        
		string = [_configManager stringForConfigWithName:@"snapshots"];
		snapshotsEnabled = ([string isEqualToString:@"yes"]) ? YES : NO;
		[_snapshotEnableButton setState:snapshotsEnabled];
		
		string = [_configManager stringForConfigWithName:@"snapshot time"];
		
		if([string intValue] > 60)
			[_snapshotTextField setStringValue:string];
		else
			[_snapshotTextField setStringValue:@"86400"];
		
		
		string = [_configManager stringForConfigWithName:@"index time"];
		
		if([string intValue] > 60)
			[_filesIndexTimeTextField setStringValue:string];
		else
			[_filesIndexTimeTextField setStringValue:@"3600"];
		
		[_startButton setEnabled:YES];
		[_launchAutomaticallyButton setEnabled:YES];
		//[_filesPopUpButton selectItemWithRepresentedObject:0];
		[_filesPopUpButton selectItemAtIndex:1];
        [_filesPopUpButton setEnabled:YES];
		[_filesIndexButton setEnabled:YES];
		[_filesIndexTimeTextField setEnabled:YES];
		[_portTextField setEnabled:YES];

		[_checkPortAgainButton setEnabled:YES];
		[_exportSettingsButton setEnabled:YES];
		[_importSettingsButton setEnabled:YES];
        [_revealButton setEnabled:YES];
		[_pruneEventsPopUpButton setEnabled:YES];
		[_snapshotEnableButton setEnabled:YES];
		[_snapshotTextField setEnabled:snapshotsEnabled];
        
	} else {
        
		[_accountStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
		[_accountStatusTextField setStringValue:NSLocalizedString(@"Wired is not installed", @"Account status")];
        
		[_startButton setEnabled:NO];
		[_launchAutomaticallyButton setEnabled:NO];
		[_filesPopUpButton setEnabled:NO];
		[_filesIndexButton setEnabled:NO];
		[_filesIndexTimeTextField setEnabled:NO];
		[_portTextField setEnabled:NO];

		[_checkPortAgainButton setEnabled:NO];
		[_setPasswordForAdminButton setEnabled:NO];
		[_createNewAdminUserButton setEnabled:NO];
		[_exportSettingsButton setEnabled:NO];
		[_importSettingsButton setEnabled:NO];
        [_revealButton setEnabled:NO];
		[_pruneEventsPopUpButton setEnabled:NO];
		[_snapshotEnableButton setEnabled:NO];
		[_snapshotTextField setEnabled:NO];
	}
    
    url = [[NSBundle mainBundle] URLForResource:@"Wired Server Helper" withExtension:@"app"];
    
    if([[WISettings settings] boolForKey:WPEnableMenuItem]) {
        [WIStatusMenuManager setStartAtLogin:WPHelperBundleID enabled:YES];
        [WIStatusMenuManager startHelper:url];
        [_enableStatusMenuyButton setState:YES];
    }else {
        [WIStatusMenuManager setStartAtLogin:WPHelperBundleID enabled:NO];
        [WIStatusMenuManager stopHelper:url];
        [_enableStatusMenuyButton setState:NO];
    }
    
}

- (void)_updatePortStatus
{    
	if(![_wiredManager isInstalled]) {
		[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
		[_portStatusTextField setStringValue:NSLocalizedString(@"Wired Server not found", @"Port status")];
	}
	else if(![_wiredManager isRunning]) {
		[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
		[_portStatusTextField setStringValue:NSLocalizedString(@"Wired Server is not running", @"Port status")];
	}
	else {
		switch(_portCheckerStatus) {
			case WPPortCheckerUnknown:
                [_portCheckProgressIndicator startAnimation:self];
				[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusNone]];
                [_portStatusTextField setStringValue:NSLocalizedString(@"Checking port status\u2026", @"Port status")];
				break;
                
			case WPPortCheckerOpen:
                [_portCheckProgressIndicator stopAnimation:self];
				[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
                [_portStatusTextField setStringValue:[NSSWF:NSLocalizedString(@"Port %lu is open", @"Port status"), (unsigned long)_portCheckerPort]];
				break;
				
			case WPPortCheckerClosed:
                [_portCheckProgressIndicator stopAnimation:self];
				[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
                [_portStatusTextField setStringValue:[NSSWF:NSLocalizedString(@"Port %lu is closed", @"Port status"), (unsigned long)_portCheckerPort]];
				break;
				
			case WPPortCheckerFiltered:
                [_portCheckProgressIndicator stopAnimation:self];
				[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
                [_portStatusTextField setStringValue:[NSSWF:NSLocalizedString(@"Port %lu is filtered", @"Port status"), (unsigned long)_portCheckerPort]];
				break;
				
			case WPPortCheckerFailed:
                [_portCheckProgressIndicator stopAnimation:self];
				[_portStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
				[_portStatusTextField setStringValue:NSLocalizedString(@"Port check failed", @"Port status")];
				break;
		}
	}
}

- (BOOL)_hasBeenUpdated {
    WPError		*error;
        
    if([[WPSettings settings] boolForKey:WPUpdated] == YES) {        
        if([_wiredManager isRunning])
            [_wiredManager stopWithError:&error];
        
        if([self _update]) 
            [self start:self];
        
        // reset updated settings
        [[WPSettings settings] setBool:NO forKey:WPUpdated];
        [[WPSettings settings] synchronize];
        
        return YES;
    }
    
    return NO;
}


#pragma mark -

- (BOOL)_install {
	WPError		*error;
	BOOL		result;
	
	[_installProgressIndicator startAnimation:self];
	
	if([self.wiredManager installWithError:&error]) {
		[self.logManager startReadingFromLog];
        
		[[WPSettings settings] removeObjectForKey:WPUninstalled];
		
		result = YES;
	} else {
		[[error alert] beginSheetModalForWindow:[_installButton window]];
		
		result = NO;
	}
	
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updatePortStatus];
	[self _updateSettings];
    
	[_installProgressIndicator stopAnimation:self];
	
	return result;
}

- (BOOL)_uninstall {
	WPError		*error;
	BOOL		result;
	
	[_installProgressIndicator startAnimation:self];
	
	if([_wiredManager uninstallWithError:&error]) {
		[_logManager stopReadingFromLog];
		
		[[WPSettings settings] removeObjectForKey:WPMigratedWired13];
		[[WPSettings settings] setBool:YES forKey:WPUninstalled];
		[[WPSettings settings] synchronize];
		
		result = YES;
	} else {
		[[error alert] beginSheetModalForWindow:[_installButton window]];
		
		result = NO;
	}
	
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updatePortStatus];
	[self _updateSettings];
    
	[_installProgressIndicator stopAnimation:self];
	
	return result;
}

- (BOOL)_update {
	WPError		*error;
	BOOL		result;
	
	[_installProgressIndicator startAnimation:self];
	
	if([_wiredManager updateWithError:&error]) {
		[_logManager startReadingFromLog];
        
		[[WPSettings settings] removeObjectForKey:WPUninstalled];
		
		result = YES;
	} else {
		[[error alert] beginSheetModalForWindow:[_installButton window]];
		
		result = NO;
	}
	
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updatePortStatus];
	[self _updateSettings];
    
	[_installProgressIndicator stopAnimation:self];
	
	return result;
}



- (void)_exportToFile:(NSString *)file {
	WPError		*error;
    
    NSLog(@"_exportToFile : %@", file);
	
	if(![_exportManager exportToFile:file error:&error])
		[[error alert] beginSheetModalForWindow:[_exportSettingsButton window]];
}



- (void)_importFromFile:(NSString *)file {
	WPError		*error;
	
	if([_exportManager importFromFile:file error:&error])
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _updateSettings];
        });
	else
        dispatch_async(dispatch_get_main_queue(), ^{
            [[error alert] beginSheetModalForWindow:[_importSettingsButton window]];
        });
}


#pragma mark -

- (NSString *)_stringForPruneEventsType:(WPPruneEventsType)type {
	
    NSString *string;
	
	switch (type) {
		case WPPruneEventsNone:		string = @"none";		break;
		case WPPruneEventsDaily:	string = @"daily";		break;
		case WPPruneEventsWeekly:	string = @"weekly";		break;
		case WPPruneEventsMonthly:	string = @"monthly";	break;
		case WPPruneEventsYearly:	string = @"yearly";		break;
		default:					string = @"none";		break;
	}
	
	return string;
}


- (WPPruneEventsType)_pruneEventsTypeForString:(NSString *)string {
	WPPruneEventsType type;
	
	if([string isEqualToString:@"none"]) {
		type = WPPruneEventsNone;
		
	} else if([string isEqualToString:@"daily"]) {
		type = WPPruneEventsDaily;
		
	} else if([string isEqualToString:@"weekly"]) {
		type = WPPruneEventsWeekly;
		
	} else if([string isEqualToString:@"monthly"]) {
		type = WPPruneEventsMonthly;
		
	} else if([string isEqualToString:@"yearly"]) {
		type = WPPruneEventsYearly;
		
	} else {
		type = WPPruneEventsNone;
	}
	
	return type;
}






#pragma mark -
#pragma mark Toolbar Methods

- (NSView *)_viewForTag:(NSInteger)tag {
    NSView *view = nil;
	switch(tag) {
		case 0: default:    view = self.generalPreferenceView; break;
		case 1:             view = self.networkPreferenceView; break;
		case 2:             view = self.filesPreferenceView; break;
		case 3:             view = self.advancedPreferenceView; break;
        case 4:             view = self.logsPreferenceView; break;
        case 5:             view = self.updatePreferenceView; break;
	}
	
    return view;
}

- (NSRect)_newFrameForNewContentView:(NSView *)view {
	
    NSRect newFrameRect = [self.window frameRectForContentRect:[view frame]];
    NSRect oldFrameRect = [self.window frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;    
    NSRect frame = [self.window frame];
    
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    
    return frame;
}

@end
