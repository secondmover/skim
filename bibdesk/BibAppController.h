//  BibAppController.h

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>

#import "BibPrefController.h";
#import "BibFinder.h";
#import "BDSKFormCellFormatter.h";
#import "BDSKShellTask.h";
#import <OmniAppKit/OAScriptMenuItem.h>
#import <ILCrashReporter/ILCrashReporter.h>



/*!
    @class BibAppController
    @abstract The application delegate.
    @discussion This (intended as a singleton) object handles various tasks that require global knowledge, such
 as showing & hiding the finder & preferences window, and the preview. <br>
 This class also performs the complete citation service.
*/


@interface BibAppController : NSDocumentController {
    BOOL showingPreviewPanel;
    BibFinder *_finder;

    // error-handling stuff:
    IBOutlet NSPanel* errorPanel;
    IBOutlet NSTableView *errorTableView;
    NSMutableArray *_errors;
    IBOutlet NSTextView *sourceEditTextView;
    IBOutlet NSWindow *sourceEditWindow;
    NSString *currentFileName;
    
    // global auto-completion dictionary:
    NSMutableDictionary *_autoCompletionDict;
    NSMutableDictionary *_formatters;
    NSCharacterSet *_autocompletePunctuationCharacterSet;
	
	// for cite key generation
	NSArray *requiredFieldsForCiteKey;
	
    // ----------------------------------------------------------------------------------------
    // stuff for the accessory view for openUsingFilter
    IBOutlet NSView* openUsingFilterAccessoryView;
    IBOutlet NSTextField* openUsingFilterTextField;
	
	// stuff for the accessory view for open text encoding 
	IBOutlet NSView *openTextEncodingAccessoryView;
	IBOutlet NSButton *openTextEncodingPopupButton;
    
    IBOutlet NSTextView* readmeTextView;
    IBOutlet NSWindow* readmeWindow;
	
	IBOutlet NSMenuItem * displayMenuItem;
	
	IBOutlet NSMenuItem* showHidePreviewMenuItem;
	IBOutlet NSMenuItem* showHideCustomCiteStringsMenuItem;
	IBOutlet NSMenuItem* showHideErrorsMenuItem;

}

/* Accessor methods for the displayMenuItem */
- (NSMenuItem*) displayMenuItem;
- (void) setDisplayMenuItem:(NSMenuItem*) item;
	

#pragma mark Overridden NSDocumentController methods

- (IBAction)openDocument:(id)sender;


/*!
    @method openUsingFilter
    @abstract Lets user specify a command-line to read from stdin and give us stdout.
    @discussion ĒdiscussionČ
    
*/
- (IBAction)openUsingFilter:(id)sender;

/*!
    @method openFile:withEncoding:
    @abstract Imports a bibtex file with a specific encoding.  Useful if there are non-ASCII characters in the file.
    @discussion
 */
- (void)openFile:(NSString *)filePath withEncoding:(NSStringEncoding)encoding;


- (NSArray *)requiredFieldsForCiteKey;

/*!
@method addString:forCompletionEntry:
    @abstract 
    @discussion 
    
*/
- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry;
/*!
    @method     autoCompletePunctuationCharacterSet
    @abstract   Possible separators for punctuation marks recognized for autocompletion
    @discussion Typically comma, colon, and semicolon, at least in US English usage.
    @result     NSCharacterSet with the currenctly recognized separator characters; retained by the sender
*/
- (NSCharacterSet *)autoCompletePunctuationCharacterSet;
/*!
    @method formatterForEntry
    @abstract returns the singleton formatter for a particular entry
    @discussion ĒdiscussionČ
    
*/
- (NSFormatter *)formatterForEntry:(NSString *)entry;

/*!
    @method stringsForCompletionEntry
    @abstract returns all strings registered for a particular entry.
    @discussion ĒdiscussionČ
    
*/
- (NSArray *)stringsForCompletionEntry:(NSString *)entry;

- (IBAction)toggleShowingErrorPanel:(id)sender;
- (IBAction)hideErrorPanel:(id)sender;
- (IBAction)showErrorPanel:(id)sender;
- (void)removeErrorObjsForFileName:(NSString *)fileName;
- (void)updateErrorPanelUI;
- (IBAction)gotoError:(id)sender;
- (IBAction)gotoErrorObj:(id)errObj;
- (IBAction)openEditWindowWithFile:(NSString *)fileName;

- (IBAction)reopenDocument:(id)sender;

- (IBAction)visitWebSite:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)showFindPanel:(id)sender;

- (IBAction)toggleShowingPreviewPanel:(id)sender;
- (IBAction)showPreviewPanel:(id)sender;
- (IBAction)hidePreviewPanel:(id)sender;
- (BOOL) isShowingPreviewPanel;

- (void)showReadMeFile;

// ----------------------------------------------------------------------------------------
// A first attempt at a service.
// This allows you to type a substring of a title and hit a key to
//    have it complete into the appropriate citekey(s), with a comment containing the full title(s)
// Alternately, you can write key = text , and have it search for text in key.
// ----------------------------------------------------------------------------------------

// helper method
- (NSDictionary *)_constraintsFromString:(NSString *)string;

/*!
@method completeCitationFromSelection:userData:error
 @abstract The service method
 @discussion  Performs the service. <br>
 Called when user selects Complete Citation.  <br>
 You the programmer should never have to call this explicitly (There is a better way)
    @param pboard The pasteboard that we read from & write to for the service.
*/
- (void)completeCitationFromSelection:(NSPasteboard *)pboard
                             userData:(NSString *)userData
                                error:(NSString **)error;

- (void)completeCiteKeyFromSelection:(NSPasteboard *)pboard
                             userData:(NSString *)userData
                                error:(NSString **)error;

- (void)showPubWithKey:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error;

- (void)importDataFromSelection:(NSPasteboard *)pboard
		       userData:(NSString *)userData
			  error:(NSString **)error;

- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error;

@end
