//  BDSKDocumentController.m

//  Created by Christiaan Hofman on 5/31/06.
/*
 This software is Copyright (c) 2006
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKDocumentController.h"
#import "BibPrefController.h"
#import <OmniBase/OmniBase.h>
#import <AGRegex/AGRegex.h>
#import "BDSKStringEncodingManager.h"
#import "BibAppController.h"
#import "BibDocument.h"
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "BDSKShellTask.h"
#import "NSArray_BDSKExtensions.h"
#import "BDAlias.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "BDSKAlert.h"


@implementation BDSKDocumentController

- (id)init
{
    if(self = [super init]){
        // @@ NSDocumentController autosave is 10.4 only
		if([self respondsToSelector:@selector(setAutosavingDelay:)] && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldAutosaveDocumentKey])
		    [self setAutosavingDelay:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKAutosaveTimeIntervalKey]];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)awakeFromNib{
    [openUsingFilterAccessoryView retain];
	[openTextEncodingPopupButton removeAllItems];
	[openTextEncodingPopupButton addItemsWithTitles:[[BDSKStringEncodingManager sharedEncodingManager] availableEncodingDisplayedNames]];
}

- (void)addDocument:(id)aDocument{
    [super addDocument:aDocument];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerAddDocumentNotification object:aDocument];
}

- (void)removeDocument:(id)aDocument{
    [aDocument retain];
    [super removeDocument:aDocument];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerRemoveDocumentNotification object:aDocument];
    [aDocument release];
}

- (void)noteNewRecentDocument:(NSDocument *)aDocument{
    
    if(! [aDocument isKindOfClass:[BibDocument class]]){
        // we don't worry about string encodings for BibLibrary files.
        return;
    }
    
    NSStringEncoding encoding = [(BibDocument *)aDocument documentStringEncoding];
    
    if(encoding == NSASCIIStringEncoding || encoding == [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]){
        // NSLog(@"adding to recents list");
        [super noteNewRecentDocument:aDocument]; // only add it to the list of recent documents if it can be opened without manually selecting an encoding
    }
}

- (id)openUntitledBibTeXDocumentWithString:(NSString *)fileString encoding:(NSStringEncoding)encoding error:(NSError **)outError{
    // @@ we could also use [[NSApp delegate] temporaryFilePath:[filePath lastPathComponent] createDirectory:NO];
    // or [[NSFileManager defaultManager] uniqueFilePath:[filePath lastPathComponent] createDirectory:NO];
    // or move aside the original file
    NSString *tmpFilePath = [[[NSApp delegate] temporaryFilePath:nil createDirectory:NO] stringByAppendingPathExtension:@"bib"];
    NSData *data = [fileString dataUsingEncoding:encoding];
    if([data writeToFile:tmpFilePath atomically:YES] == NO)
        NSLog(@"Unable to write data to file %@; continuing anyway.", tmpFilePath);
    
    // make a fresh document, and don't display it until we can set its name.
    BibDocument *doc = [self openUntitledDocumentOfType:BDSKBibTeXDocumentType display:NO];
    [doc setFileName:tmpFilePath]; // required for error handling; mark it dirty, so it's obviously modified
    [doc setFileType:BDSKBibTeXDocumentType];  // this looks redundant, but it's necessary to enable saving the file (at least on AppKit == 10.3)
    BOOL success = [doc readFromURL:[NSURL fileURLWithPath:tmpFilePath] ofType:BDSKBibTeXDocumentType encoding:encoding error:outError];
    
    if (success == NO) {
        [self removeDocument:doc];
        doc = nil;
    } else {
        [doc setFileName:nil];
        [doc showWindows];
        // mark as dirty, since we've changed the cite keys
        [doc updateChangeCount:NSChangeDone];
    }
    
    return doc;
}

- (IBAction)openDocumentUsingFilter:(id)sender
{
    int result;
    NSString *fileToOpen = nil;
    NSString *shellCommand = nil;
    NSString *filterOutput = nil;
    NSString *fileInputString = nil;
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];

    NSString *defaultEncName = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]];
    [openTextEncodingPopupButton selectItemWithTitle:defaultEncName];
    [openTextEncodingAccessoryView setFrameOrigin:NSZeroPoint];
    [openUsingFilterAccessoryView addSubview:openTextEncodingAccessoryView];
    [oPanel setAccessoryView:openUsingFilterAccessoryView];

    NSSet *uniqueCommandHistory = [NSSet setWithArray:[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKFilterFieldHistoryKey]];
    NSMutableArray *commandHistory = [NSMutableArray arrayWithArray:[uniqueCommandHistory allObjects]];
        
    unsigned MAX_HISTORY = 7;
    if([commandHistory count] > MAX_HISTORY)
        [commandHistory removeObjectsInRange:NSMakeRange(MAX_HISTORY, [commandHistory count] - MAX_HISTORY)];
    [openUsingFilterComboBox addItemsWithObjectValues:commandHistory];
    
    if([commandHistory count]){
        [openUsingFilterComboBox selectItemAtIndex:0];
        [openUsingFilterComboBox setObjectValue:[openUsingFilterComboBox objectValueOfSelectedItem]];
    }
    result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:nil];
    if (result == NSOKButton) {
        fileToOpen = [oPanel filename];
        shellCommand = [openUsingFilterComboBox stringValue];
        
        unsigned commandIndex = [commandHistory indexOfObject:shellCommand];
        if(commandIndex != NSNotFound && commandIndex != 0)
            [commandHistory removeObject:shellCommand];
        [commandHistory insertObject:shellCommand atIndex:0];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:commandHistory forKey:BDSKFilterFieldHistoryKey];

        NSData *fileInputData = [[NSData alloc] initWithContentsOfFile:fileToOpen];

        NSStringEncoding encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[openTextEncodingPopupButton titleOfSelectedItem]];
        fileInputString = [[NSString alloc] initWithData:fileInputData encoding:encoding];
        [fileInputData release];
        
        if ([NSString isEmptyString:fileInputString]){
            NSRunAlertPanel(NSLocalizedString(@"Unable To Open With Filter",@""),
                                    NSLocalizedString(@"The file could not be read correctly. Please try again, possibly using a different character encoding such as UTF-8.",@""),
                                    NSLocalizedString(@"OK",@""),
                                    nil, nil, nil, nil);
        } else {
			filterOutput = [[BDSKShellTask shellTask] runShellCommand:shellCommand
													  withInputString:fileInputString];
            
            if ([NSString isEmptyString:filterOutput]){
                NSRunAlertPanel(NSLocalizedString(@"Unable To Open With Filter",@""),
                                        NSLocalizedString(@"Unable to read the file correctly. Please ensure that the shell command specified for filtering is correct by testing it in Terminal.app.",@""),
                                        NSLocalizedString(@"OK",@""),
                                        nil, nil, nil, nil);
            } else {
                // the original file could be any format, but the ouput is supposed to be bibtex
                fileToOpen = [[fileToOpen stringByDeletingPathExtension] stringByAppendingPathExtension:@"bib"];
                [self openUntitledBibTeXDocumentWithString:filterOutput encoding:NSUTF8StringEncoding error:NULL];
            }
		}
        [fileInputString release];
    }
}

- (void)openDocumentCreatingPhonyCiteKeys:(BOOL)phony{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAccessoryView:openTextEncodingAccessoryView];
    NSString *defaultEncName = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]];
    [openTextEncodingPopupButton selectItemWithTitle:defaultEncName];
		
	NSArray *types = (phony ? [NSArray arrayWithObject:@"bib"] : [NSArray arrayWithObjects:@"bib", @"fcgi", @"ris", nil]);
	
	int result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:types];
	if (result == NSOKButton) {
        id document = nil;
        NSString *fileToOpen = [oPanel filename];
        NSString *docType = [self typeFromFileExtension:[fileToOpen pathExtension]];
        NSStringEncoding encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[openTextEncodingPopupButton titleOfSelectedItem]];

        if(phony){
            document = [self openBibTeXFileUsingPhonyCiteKeys:fileToOpen withEncoding:encoding];
        }else{
            document = [self openFile:fileToOpen ofType:docType withEncoding:encoding];		
        }
        [document showWindows];
        // @@ If the document is created as untitled and then loaded, the smart groups don't get updated at load; if you use Open Recent or the Finder, they are updated correctly (those call through to openDocumentWithContentsOfURL:display:error:, which may do something different with updating).
        if([document respondsToSelector:@selector(updateAllSmartGroups)])
           [document performSelector:@selector(updateAllSmartGroups)];
	}
	
}

- (IBAction)openDocument:(id)sender{
    [self openDocumentCreatingPhonyCiteKeys:NO];
}

- (IBAction)openDocumentUsingPhonyCiteKeys:(id)sender{
    [self openDocumentCreatingPhonyCiteKeys:YES];
}

- (id)openFile:(NSString *)filePath ofType:(NSString *)docType withEncoding:(NSStringEncoding)encoding{
	
	BibDocument *doc = nil;
	BOOL success;
    
    // make a fresh document, and don't display it until we can set its name.
    doc = [self openUntitledDocumentOfType:docType display:NO];
    [doc setFileName:filePath]; // this effectively makes it not an untitled document anymore.
    [doc setFileType:docType];  // this looks redundant, but it's necessary to enable saving the file (at least on AppKit == 10.3)
    success = [doc readFromURL:[NSURL fileURLWithPath:filePath] ofType:docType encoding:encoding error:NULL];
    if (success == NO) {
        [self removeDocument:doc];
        doc = nil;
    }
    return doc;
}

- (id)openBibTeXFileUsingPhonyCiteKeys:(NSString *)filePath withEncoding:(NSStringEncoding)encoding{
	NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSString *stringFromFile = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];

    // ^(@[[:alpha:]]+{),?$ will grab either "@type{,eol" or "@type{eol", which is what we get
    // from Bookends and EndNote, respectively.
    AGRegex *theRegex = [AGRegex regexWithPattern:@"^(@[[:alpha:]]+[ \t]*{)[ \t]*,?$" options:AGRegexCaseInsensitive];

    // replace with "@type{FixMe,eol" (add the comma in, since we remove it if present)
    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    
    // do not use NSCharacterSets with OFStringScanners!
    OFCharacterSet *newlineOFCharset = [[[OFCharacterSet alloc] initWithCharacterSet:newlineCharacterSet] autorelease];
    
    OFStringScanner *scanner = [[[OFStringScanner alloc] initWithString:stringFromFile] autorelease];
    NSMutableString *mutableFileString = [NSMutableString stringWithCapacity:[stringFromFile length]];
    NSString *tmp = nil;
    int scanLocation = 0;
    
    // we scan up to an (newline@) sequence, then to a newline; we then replace only in that line using theRegex, which is much more efficient than using AGRegex to find/replace in the entire string
    do {
        
        // append the previous part to the mutable string
        tmp = [scanner readFullTokenWithDelimiterCharacter:'@'];
        if(tmp) [mutableFileString appendString:tmp];
        
        scanLocation = scannerScanLocation(scanner);
        if(scanLocation == 0 || [newlineCharacterSet characterIsMember:[stringFromFile characterAtIndex:scanLocation - 1]]){
            
            tmp = [scanner readFullTokenWithDelimiterOFCharacterSet:newlineOFCharset];
            
            // if we read something between the @ and newline, see if we can do the regex find/replace
            if(tmp){
                // this should be a noop if the pattern isn't matched
                tmp = [theRegex replaceWithString:@"$1FixMe," inString:tmp];
                [mutableFileString appendString:tmp]; // guaranteed non-nil result from AGRegex
            }
        } else
            scannerReadCharacter(scanner);
                        
    } while(scannerHasData(scanner));
    
	BibDocument *doc = [self openUntitledBibTeXDocumentWithString:mutableFileString encoding:encoding error:NULL];
    
    if ([[doc publications] count]){
        [doc setSelectedSearchFieldKey:BDSKCiteKeyString];
        [doc setFilterField:@"FixMe"];
        BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Temporary Cite Keys", @"Temporary Cite Keys") 
                                             defaultButton:NSLocalizedString(@"Generate", @"generate cite keys") 
                                           alternateButton:NSLocalizedString(@"Don't Generate", @"don't generate cite keys") 
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"This document was opened using temporary cite keys for the publications shown.  In order to use your file with BibTeX, you must generate valid cite keys for all of the items in this file.  Do you want me to do this now?", @"") ];

        int rv = [alert runSheetModalForWindow:[doc windowForSheet]
                                 modalDelegate:nil
                                didEndSelector:NULL
                            didDismissSelector:NULL
                                   contextInfo:nil];
        if (rv == NSAlertDefaultReturn) {
            [doc selectAllPublications:nil];
            [doc setFilterField:@""];
            [doc generateCiteKey:nil];
        }
    }
    
    return doc;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError{
            
    NSString *theUTI = [[NSWorkspace sharedWorkspace] UTIForURL:absoluteURL];
    if(theUTI == nil || [theUTI isEqualToUTI:@"net.sourceforge.bibdesk.bdskcache"] == NO)
        return [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:absoluteURL];
    BDAlias *fileAlias = [BDAlias aliasWithData:[dictionary valueForKey:@"FileAlias"]];
    NSString *fullPath = [fileAlias fullPath];
    
    if(fullPath == nil) // if the alias didn't work, let's see if we have a filepath key...
        fullPath = [dictionary valueForKey:@"net_sourceforge_bibdesk_owningfilepath"];
    
    if(fullPath == nil){
        if(outError != nil) 
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to find the file associated with this item.", @""), NSLocalizedDescriptionKey, nil]];
        return nil;
    }
        
    NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
    
    NSError *error = nil; // this is a garbage pointer if the document is already open
    BibDocument *document = [super openDocumentWithContentsOfURL:fileURL display:YES error:&error];
    
    if(document == nil)
        NSLog(@"document at URL %@ failed to open for reason: %@", fileURL, [error localizedFailureReason]);
    else
        if(![document highlightItemForPartialItem:dictionary])
            NSBeep();
    
    return document;
}

@end

#pragma mark -

@interface NSSavePanel (AppleBugPrivate)
- (BOOL)_canShowGoto;
@end

@interface BDSKPosingSavePanel : NSSavePanel @end

@implementation BDSKPosingSavePanel

+ (void)load
{
    [self poseAsClass:NSClassFromString(@"NSSavePanel")];
}

// hack around an acknowledged Apple bug (http://www.cocoabuilder.com/archive/message/cocoa/2006/4/14/161080) that causes the goto panel to be displayed when trying to enter a leading / in "Open Using Filter" accessory view (our bug #1480815)
- (BOOL)_canShowGoto;
{
    id firstResponder = [self firstResponder];
    // this is likely a field editor, but we have to make sure
    if([firstResponder isKindOfClass:[NSText class]] && [firstResponder isFieldEditor]){
        // if it's our custom view, the control will be a combo box (delegate of the field editor)
        NSView *accessoryView = [self accessoryView];
        if (accessoryView != nil && [accessoryView ancestorSharedWithView:[firstResponder delegate]] == accessoryView)
            return NO;
    }
    return [super _canShowGoto];
}

@end
