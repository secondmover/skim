//  BibAppController.h

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import "BibPrefController.h";
#import "BDSKFormCellFormatter.h";
#import "BDSKShellTask.h";
#import <OmniAppKit/OAScriptMenuItem.h>
#import <ILCrashReporter/ILCrashReporter.h>
#import "NSMutableArray+ThreadSafety.h"
#import "NSMutableDictionary+ThreadSafety.h"
#import "BDSKStringEncodingManager.h"


/*!
    @class BibAppController
    @abstract The application delegate.
    @discussion This (intended as a singleton) object handles various tasks that require global knowledge, such
 as showing & hiding the finder & preferences window, and the preview. <br>
 This class also performs the complete citation service.
*/


@interface BibAppController : NSDocumentController {
    BOOL showingPreviewPanel;

    // error-handling stuff:
    IBOutlet NSPanel* errorPanel;
    IBOutlet NSTableView *errorTableView;
    NSMutableArray *errors;
    IBOutlet NSTextView *sourceEditTextView;
    IBOutlet NSWindow *sourceEditWindow;
    NSString *currentFileName;
    NSDocument *currentDocumentForErrors;
	
    // global auto-completion dictionary:
    NSLock *acLock;
    NSMutableDictionary *autoCompletionDict;
    NSMutableDictionary *formatters;
    NSCharacterSet *autocompletePunctuationCharacterSet;
	
	// auto generation format
	NSArray *requiredFieldsForCiteKey;
	NSArray *requiredFieldsForLocalUrl;
	
    // ----------------------------------------------------------------------------------------
    // stuff for the accessory view for openUsingFilter
    IBOutlet NSView* openUsingFilterAccessoryView;
    IBOutlet NSComboBox *openUsingFilterComboBox;
	
	// stuff for the accessory view for open text encoding 
	IBOutlet NSView *openTextEncodingAccessoryView;
	IBOutlet NSPopUpButton *openTextEncodingPopupButton;
    
    IBOutlet NSTextView* readmeTextView;
    IBOutlet NSWindow* readmeWindow;
	
	IBOutlet NSMenuItem * displayMenuItem;
	
	IBOutlet NSMenuItem* showHidePreviewMenuItem;
	IBOutlet NSMenuItem* showHideCustomCiteStringsMenuItem;
	IBOutlet NSMenuItem* showHideErrorsMenuItem;

}

/* Accessor methods for the displayMenuItem */
- (NSMenuItem*) displayMenuItem;
	
- (void)updateColumnsMenu;


#pragma mark Overridden NSDocumentController methods



/*!
    @method     newBDSKLibrary:
    @abstract   responds to the New Library menu command in File.
    @discussion (description)
    @param      sender (description)
    @result     (description)
*/
- (IBAction)newBDSKLibrary:(id)sender;

/*!
    @method     openDocument:
    @abstract   responds to the Open menu item in File
    @discussion (description)
    @param      sender (description)
    @result     (description)
*/
- (IBAction)openDocument:(id)sender;


/*!
    @method openUsingFilter
    @abstract Lets user specify a command-line to read from stdin and give us stdout.
    @discussion ĒdiscussionČ
    
*/
- (IBAction)openUsingFilter:(id)sender;

/*!
    @method openBibTeXFile:withEncoding:
    @abstract Imports a bibtex file with a specific encoding.  Useful if there are non-ASCII characters in the file.
    @discussion
 */
- (void)openBibTeXFile:(NSString *)filePath withEncoding:(NSStringEncoding)encoding;

/*!
    @method     openRISFile:withEncoding:
    @abstract   Creates a new document with given RIS file and string encoding.
    @discussion (comprehensive description)
    @param      filePath (description)
    @param      encoding (description)
*/
- (void)openRISFile:(NSString *)filePath withEncoding:(NSStringEncoding)encoding;

/*!
    @method     openBibTeXFileUsingPhonyCiteKeys:withEncoding:
    @abstract   Generates temporary cite keys in order to keep btparse from choking on files exported from Endnote or BookEnds.
    @discussion Uses a regular expression to find and replace empty cite keys, according to a fairly limited pattern.
                A new, untitled document is created, and a warning about the invalid temporary keys is shown after opening.
    @param      filePath The file to open
    @param      encoding File's character encoding
*/
- (void)openBibTeXFileUsingPhonyCiteKeys:(NSString *)filePath withEncoding:(NSStringEncoding)encoding;

- (NSArray *)requiredFieldsForCiteKey;
- (void)setRequiredFieldsForCiteKey:(NSArray *)newFields;
- (NSArray *)requiredFieldsForLocalUrl;
- (void)setRequiredFieldsForLocalUrl:(NSArray *)newFields;

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
- (void)removeErrorObjsForDocument:(NSDocument *)doc;
- (void)handoverErrorObjsForDocument:(NSDocument *)doc;
- (void)setDocumentForErrors:(NSDocument *)doc;
- (void)updateErrorPanelUI;
- (IBAction)gotoError:(id)sender;
- (void)gotoErrorObj:(id)errObj;
- (void)openEditWindowWithFile:(NSString *)fileName;
- (void)openEditWindowForDocument:(NSDocument *)doc;

- (IBAction)reopenDocument:(id)sender;

- (IBAction)visitWebSite:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

- (IBAction)showPreferencePanel:(id)sender;

- (IBAction)toggleShowingPreviewPanel:(id)sender;
- (IBAction)showPreviewPanel:(id)sender;
- (IBAction)hidePreviewPanel:(id)sender;
- (BOOL) isShowingPreviewPanel;

- (IBAction)showReadMeFile:(id)sender;
- (IBAction)showRelNotes:(id)sender;

// ----------------------------------------------------------------------------------------
// A first attempt at a service.
// This allows you to type a substring of a title and hit a key to
//    have it complete into the appropriate citekey(s), with a comment containing the full title(s)
// Alternately, you can write key = text , and have it search for text in key.
// ----------------------------------------------------------------------------------------

// helper method
- (NSDictionary *)constraintsFromString:(NSString *)string;

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

- (void)newRISDocumentFromSelection:(NSPasteboard *)pboard
		       userData:(NSString *)userData
			  error:(NSString **)error;

- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error;

/*!
    @method     itemsMatchingSearchConstraints:
    @abstract   Search across all open documents for items matching the given search constraints.  Returns a set of BibItems.
    @discussion Searches are performed by intersecting the search constraints, so all object/key pairs will be matched in any single item returned.
    @param      constraints Dictionary of the form @"objectToSearchFor" forKey:@"BibTeXFieldName".
    @result     NSSet of BibItems.
*/
- (NSSet *)itemsMatchingSearchConstraints:(NSDictionary *)constraints;
/*!
    @method     itemsMatchingCiteKey:
    @abstract   Search across all open documents for items with the given cite key.  Returns a set of BibItems.
    @discussion (comprehensive description)
    @param      citeKeyString (description)
    @result     (description)
*/
- (NSSet *)itemsMatchingCiteKey:(NSString *)citeKeyString;
@end

@interface NSFileManager (BibDeskAdditions)

- (NSString *)applicationSupportDirectory:(SInt16)domain;

@end
