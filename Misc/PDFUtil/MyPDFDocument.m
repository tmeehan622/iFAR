/* PDFKitViewer - MyPDFDocument.m
 *
 * Author: John Calhoun
 * Created 2004
 * 
 * Copyright (c) 2004 Apple Computer, Inc.
 * All rights reserved.
 */

/* IMPORTANT: This Apple software is supplied to you by Apple Computer,
 Inc. ("Apple") in consideration of your agreement to the following terms,
 and your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms.  If you do not agree with
 these terms, please do not use, install, modify or redistribute this Apple
 software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following text
 and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
 ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
 LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE. */

#import "MyPDFDocument.h"
#import "AppDelegate.h"
#import <Quartz/Quartz.h>

@implementation MyPDFDocument
// ======================================================================================================== MyPDFDocument
// ----------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	self = [super init];
	if (self)
	{
		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.
		
	}
	
	return self;
}

// -------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
 	
	// Clean up.
	[_searchResults release];
	
	// Super.
	[super dealloc];
}

// -------------------------------------------------------------------------------------------------------- windowNibName

- (NSString *) windowNibName
{
	// Override returning the nib file name of the document
	return @"MyDocument";
}

// ------------------------------------------------------------------------------------------- windowControllerDidLoadNib

- (void) windowControllerDidLoadNib: (NSWindowController *) controller
{
	NSSize		windowSize;
	
	// Super.
	[super windowControllerDidLoadNib: controller];
	
	// Load PDF.
	if ([self fileName])
	{
		_pdfDoc = [[[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: [self fileName]]] autorelease];
		[_pdfView setDocument: _pdfDoc];
	}
	
	// Page changed notification.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pageChanged:) 
			name: PDFViewPageChangedNotification object: _pdfView];
	
	// Find notifications.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startFind:) 
			name: PDFDocumentDidBeginFindNotification object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(findProgress:) 
			name: PDFDocumentDidEndPageFindNotification object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endFind:) 
			name: PDFDocumentDidEndFindNotification object: [_pdfView document]];
	
	// Set self to be delegate (find).
	[[_pdfView document] setDelegate: self];
	
	// Get outline.
	_outline = [[[_pdfView document] outlineRoot] retain];
	if (_outline)
	{
		// Remove text that says, "No outline."
		[_noOutlineText removeFromSuperview];
		_noOutlineText = NULL;
		
		// Force it to load up.
		[_outlineView reloadData];
	}
	else
	{
		// Remove outline view (leaving instead text that says, "No outline.").
		[[_outlineView enclosingScrollView] removeFromSuperview];
		_outlineView = NULL;
	}
	
	// Open drawer.
	[_drawer open];
	
	// Size the window.
	windowSize = [_pdfView rowSizeForPage: [_pdfView currentPage]];
	if ((([_pdfView displayMode] & 0x01) == 0x01) && ([[_pdfView document] pageCount] > 1))
		windowSize.width += [NSScroller scrollerWidth];
	[[controller window] setContentSize: windowSize];
}

// --------------------------------------------------------------------------------------------- dataRepresentationOfType

- (NSData *) dataRepresentationOfType: (NSString *) aType
{
	// Insert code here to write your document from the given data.  You can also choose to override 
	// -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
	return nil;
}

// ---------------------------------------------------------------------------------------- loadDataRepresentation:ofType

- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType
{
	// Insert code here to read your document from the given data.  You can also choose to override 
	// -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
	return YES;
}

#pragma mark -
// --------------------------------------------------------------------------------------------------------- toggleDrawer

- (IBAction) toggleDrawer: (id) sender
{
	[_drawer toggle: self];
}

// ------------------------------------------------------------------------------------------- takeDestinationFromOutline

- (IBAction) takeDestinationFromOutline: (id) sender
{
	// Get the destination associated with the search result list.  Tell the PDFView to go there.
	[_pdfView goToDestination: [[sender itemAtRow: [sender selectedRow]] destination]];
}

// ---------------------------------------------------------------------------------------------------- displaySinglePage

- (IBAction) displaySinglePage: (id) sender
{
	// Display single page mode.
	if ([_pdfView displayMode] > kPDFDisplaySinglePageContinuous)
		[_pdfView setDisplayMode: [_pdfView displayMode] - 2];
}

// --------------------------------------------------------------------------------------------------------- displayTwoUp

- (IBAction) displayTwoUp: (id) sender
{
	// Display two-up.
	if ([_pdfView displayMode] < kPDFDisplayTwoUp)
		[_pdfView setDisplayMode: [_pdfView displayMode] + 2];
}

// ---------------------------------------------------------------------------------------------------------- pageChanged

- (void) pageChanged: (NSNotification *) notification
{
	unsigned int	newPageIndex;
	int				numRows;
	int				i;
	int				newlySelectedRow;
	
	// Skip out if there is no outline.
	if ([[_pdfView document] outlineRoot] == NULL)
		return;
	
	// What is the new page number (zero-based).
	newPageIndex = [[_pdfView document] indexForPage: [_pdfView currentPage]];
	
	// Walk outline view looking for best firstpage number match.
	newlySelectedRow = -1;
	numRows = [_outlineView numberOfRows];
	for (i = 0; i < numRows; i++)
	{
		PDFOutline	*outlineItem;
		
		// Get the destination of the given row....
		outlineItem = (PDFOutline *)[_outlineView itemAtRow: i];
		
		if ([[_pdfView document] indexForPage: [[outlineItem destination] page]] == newPageIndex)
		{
			newlySelectedRow = i;
			[_outlineView selectRow: newlySelectedRow byExtendingSelection: NO];
			break;
		}
		else if ([[_pdfView document] indexForPage: [[outlineItem destination] page]] > newPageIndex)
		{
			newlySelectedRow = i - 1;
			[_outlineView selectRow: newlySelectedRow byExtendingSelection: NO];
			break;
		}
	}
	
	// Auto-scroll.
	if (newlySelectedRow != -1)
		[_outlineView scrollRowToVisible: newlySelectedRow];
}

#pragma mark -
// --------------------------------------------------------------------------------------------------------------- doFind

- (void) doFind: (id) sender
{
	if ([[_pdfView document] isFinding])
		[[_pdfView document] cancelFindString];
	
	// Lazily allocate _searchResults.
	if (_searchResults == NULL)
		_searchResults = [[NSMutableArray arrayWithCapacity: 10] retain];
	
	[[_pdfView document] beginFindString: [sender stringValue] withOptions: NSCaseInsensitiveSearch];
}

// ------------------------------------------------------------------------------------------------------------ startFind

- (void) startFind: (NSNotification *) notification
{
	// Empty arrays.
	[_searchResults removeAllObjects];
	
	[_searchTable reloadData];
	[_searchProgress startAnimation: self];
}

// --------------------------------------------------------------------------------------------------------- findProgress

- (void) findProgress: (NSNotification *) notification
{
	double		pageIndex;
	
	pageIndex = [[[notification userInfo] objectForKey: @"PDFDocumentPageIndex"] doubleValue];
	[_searchProgress setDoubleValue: pageIndex / [[_pdfView document] pageCount]];
}

// ------------------------------------------------------------------------------------------------------- didMatchString
// Called when an instance was located. Delegates can instantiate.

- (void) didMatchString: (PDFSelection *) instance
{
	// Add page label to our array.
	[_searchResults addObject: [instance copy]];
	
	// Force a reload.
	[_searchTable reloadData];
}

// -------------------------------------------------------------------------------------------------------------- endFind

- (void) endFind: (NSNotification *) notification
{
	[_searchProgress stopAnimation: self];
	[_searchProgress setDoubleValue: 0];
}

#pragma mark ------ NSTableView delegate methods
// ---------------------------------------------------------------------------------------------- numberOfRowsInTableView

// The table view is used to hold search results.  Column 1 lists the page number for the search result, 
// column two the section in the PDF (x-ref with the PDF outline) where the result appears.

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	return ([_searchResults count]);
}

// ------------------------------------------------------------------------------ tableView:objectValueForTableColumn:row

- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) theColumn
		row: (int) rowIndex
{
	if ([[theColumn identifier] isEqualToString: @"page"])
		return ([[[[_searchResults objectAtIndex: rowIndex] pages] objectAtIndex: 0] label]);
	else if ([[theColumn identifier] isEqualToString: @"section"])
		return ([[[_pdfView document] outlineItemForSelection: [_searchResults objectAtIndex: rowIndex]] label]);
	else
		return NULL;
}

// ------------------------------------------------------------------------------------------ tableViewSelectionDidChange

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	int			rowIndex;
	
	// What was selected.  Skip out if the row has not changed.
	rowIndex = [(NSTableView *)[notification object] selectedRow];
	if (rowIndex >= 0)
	{
		[_pdfView setCurrentSelection: [_searchResults objectAtIndex: rowIndex]];
		[_pdfView centerSelectionInVisibleArea: self];
	}
}

#pragma mark ------ NSOutlineView delegate methods
// ----------------------------------------------------------------------------------- outlineView:numberOfChildrenOfItem

// The outline view is for the PDF outline.  Not all PDF's have an outline.

- (int) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
	if (item == NULL)
	{
		if (_outline)
			return [_outline numberOfChildren];
		else
			return 0;
	}
	else
		return [(PDFOutline *)item numberOfChildren];
}

// --------------------------------------------------------------------------------------------- outlineView:child:ofItem

- (id) outlineView: (NSOutlineView *) outlineView child: (int) index ofItem: (id) item
{
	if (item == NULL)
	{
		if (_outline)
			return [[_outline childAtIndex: index] retain];
		else
			return NULL;
	}
	else
		return [[(PDFOutline *)item childAtIndex: index] retain];
}

// ----------------------------------------------------------------------------------------- outlineView:isItemExpandable

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
	if (item == NULL)
	{
		if (_outline)
			return ([_outline numberOfChildren] > 0);
		else
			return NO;
	}
	else
		return ([(PDFOutline *)item numberOfChildren] > 0);
}

// ------------------------------------------------------------------------- outlineView:objectValueForTableColumn:byItem

- (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) tableColumn 
		byItem: (id) item
{
    return [(PDFOutline *)item label];
}

#if 0
- (void) traverseOutline:(PDFOutline*)outline intoArray:(NSMutableArray*) r
{
	PDFDestination*	destination = [outline destination];
	NSString*		sourceLabel = [outline label];
	NSString*		destinationLabel = [[destination page] label];
	
	if(sourceLabel && destinationLabel)
		[r addObject:[NSDictionary dictionaryWithObjectsAndKeys:sourceLabel, @"source", destinationLabel, @"destination", nil]];
	int	childCount = [outline numberOfChildren];
	int	i;
	for(i=0;i<childCount;i++)
		[self traverseOutline:[outline childAtIndex:i] intoArray:r];
	
} // traverseOutline

#else
- (NSDictionary*) traverseOutline:(PDFOutline*)outline
{
	PDFDestination*	destination = [outline destination];
	NSString*		sourceLabel = [outline label];
	NSString*		destinationLabel = [[destination page] label];
	
	NSMutableDictionary*	d = [NSMutableDictionary dictionary];
	if(sourceLabel && destinationLabel)
	{
		[d setObject:sourceLabel forKey:@"title"];
		[d setObject:destinationLabel forKey:@"page"];
	}

	NSMutableArray*	children = [NSMutableArray array];
	int	childCount = [outline numberOfChildren];
	int	i;
	for(i=0;i<childCount;i++)
		[children addObject:[self traverseOutline:[outline childAtIndex:i]]];
	if([children count])
		[d setObject:children forKey:@"children"];
	
	return d;
} // traverseOutline

#endif


- (void) makeOutlineIndex:(NSString*)outputPath
{
	NSDictionary*	outlineDict = [self traverseOutline:_outline];
	[outlineDict writeToFile:outputPath atomically:YES];
} // makeOutlineIndex


- (NSArray*) traverseOutlineForHtml:(PDFOutline*)outline
{
	PDFDestination*	destination = [outline destination];
	NSString*		sourceLabel = [outline label];
	NSString*		destinationLabel = [[destination page] label];
	
	NSMutableDictionary*	d = nil;
	if(sourceLabel && destinationLabel && [sourceLabel hasPrefix:@"Subpart"])
	{
		NSString*	subpart = @"";
		
		NSScanner *theScanner = [NSScanner scannerWithString:sourceLabel];
		[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]  intoString:NULL];
		[theScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" -"]  intoString:&subpart];

		if(subpart && [subpart length])
		{
			d = [NSMutableDictionary dictionary];
			[d setObject:subpart forKey:@"source"];
			[d setObject:destinationLabel forKey:@"start"];
		}
	}
	
	NSArray*	children = [NSArray array];
	if(d)
		children = [NSArray arrayWithObject:d];
	
	int	childCount = [outline numberOfChildren];
	int	i;
	for(i=0;i<childCount;i++)
		children = [children arrayByAddingObjectsFromArray:[self traverseOutlineForHtml:[outline childAtIndex:i]]];
	
	return children;
} // traverseOutlineForHtml

- (void) makeOutlineIndexForHtml:(NSString*)outputPath
{
	NSArray*	outlineArray = [self traverseOutlineForHtml:_outline];
	NSDictionary*	outlineDict = [NSDictionary dictionaryWithObject:outlineArray forKey:@"items"];
	[outlineDict writeToFile:outputPath atomically:YES];
} // makeOutlineIndexForHtml


- (IBAction) separatePages:(id)sender
{
	NSArray*				junkWords = [[@"a, all, am, an, and, any, as, at, b, be, by, c, d, e, for, from, g, h, how, i, i'm, i.e., in, is, isn't, it, it's, its, j, k, l, m, n, o, of, on, or, p, q, r, s, t, that, that's, the, this, to, u, v, w, was, wasn't, what, what's, when, where, who, who's, will, with, x, y, z" componentsSeparatedByString:@", "] retain]; 
	
	NSString*				documentPath = [[[self fileURL] path] stringByDeletingPathExtension];
	NSString*				thumbsPath = [documentPath stringByAppendingString:@" Thumbs"];
	NSString*				rtfPath = [documentPath stringByAppendingString:@" RTF"];
	
	NSMutableArray*			fontStyles = [NSMutableArray array];
	NSMutableDictionary*	pageMap = [NSMutableDictionary dictionary];
	
	documentPath = [documentPath stringByAppendingString:@" Pages"];

// Make the needed folders first
	NSString*				outputPrefix = [documentPath stringByAppendingPathComponent:[documentPath lastPathComponent]];
	NSMutableDictionary*	wordDictionary = [[NSMutableDictionary dictionary] retain];
	
	BOOL existingFolder;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:documentPath isDirectory:&existingFolder];
	if(!exists)
		[[NSFileManager defaultManager] createDirectoryAtPath:documentPath attributes:nil];
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath:thumbsPath isDirectory:&existingFolder];
	if(!exists)
		[[NSFileManager defaultManager] createDirectoryAtPath:thumbsPath attributes:nil];
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath:rtfPath isDirectory:&existingFolder];
	if(!exists)
		[[NSFileManager defaultManager] createDirectoryAtPath:rtfPath attributes:nil];

// Make the outline indexes
	[self makeOutlineIndexForHtml:[documentPath stringByAppendingFormat:@"/htmlIndex.plist"]];
	[self makeOutlineIndex:[documentPath stringByAppendingFormat:@"/outlineItems.plist"]];
	
	NSCharacterSet*		crappyChars = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] retain];
	int	pageCount = [_pdfDoc pageCount];
	int currentPage;
	for(currentPage = 0;currentPage < pageCount; currentPage++)
	{
		NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
		
		PDFPage*		thisPage = [_pdfDoc pageAtIndex:currentPage];
		NSString*		pageContents = [thisPage string];
		NSArray*		tmpWords = [pageContents componentsSeparatedByString:@" "];
		NSMutableSet*	words = [NSMutableSet set];
		NSArray*		textParts = [NSArray array];
		
		[pageMap setObject:[NSNumber numberWithInt:currentPage+1] forKey:[thisPage label]];
		
		for(NSString*word in tmpWords)
		{
			NSString*	tmpWord = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			tmpWord = [tmpWord stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
			NSRange	crapRange = [tmpWord rangeOfCharacterFromSet:crappyChars];
			
			if(crapRange.location == NSNotFound && [tmpWord length] && ![junkWords containsObject:tmpWord])
				[words addObject:[tmpWord lowercaseString]];
		}
		
		for(NSString*word in [words allObjects])
		{
			NSMutableArray*	pageSet = [wordDictionary objectForKey:word];
			if(pageSet == nil)
			{
				pageSet = [NSMutableArray array];
				[wordDictionary setObject:pageSet forKey:word];
			}

			[pageSet addObject:[NSNumber numberWithInt:currentPage]];
		}
			
		PDFDocument*	xportDoc = [[PDFDocument alloc] init];
		[xportDoc insertPage:thisPage atIndex:0];
#if 1
		BOOL ok = [xportDoc writeToFile:[documentPath stringByAppendingFormat:@"/page%d.pdf", currentPage+1]];

		NSSize thumbSize = {78, 100};
		[self saveThumbNail:xportDoc ofSize:thumbSize to:[thumbsPath stringByAppendingFormat:@"/thumb%d.jpg", currentPage+1]];
#endif
		NSAttributedString*	pageString = [thisPage attributedString];
		NSRange				r = {0, [pageString length]};
		NSData*	rtfd = [pageString RTFFromRange:r documentAttributes:nil];
		[rtfd writeToFile:[rtfPath stringByAppendingFormat:@"/page%d.rtf", currentPage+1] atomically:YES];
		int i;
		for(i=0;i<[pageString length]; )
		{
			NSRange			attrRange;
			NSDictionary*	charAttributes =[pageString attributesAtIndex:i effectiveRange:&attrRange];
			NSString*		chunk = [pageContents substringWithRange:attrRange];
			i += attrRange.length;
			
			NSFont*	thisFont = [charAttributes objectForKey:@"NSFont"];
			BOOL	found = NO;
			int		fIndex = 0;
			
			for(NSFont* f in fontStyles)
			{
				if([f isEqualTo: thisFont])
				{
					found = YES;
					break;
				}
				fIndex++;
			} 
			if(!found && thisFont)
				[fontStyles addObject: thisFont];
			else
				fIndex = -1;
			
			textParts = [textParts arrayByAddingObject:[NSDictionary dictionaryWithObjectsAndKeys:chunk, @"chunk", [NSNumber numberWithInt:fIndex], @"fIndex", nil]];
			NSDictionary* fontInfo = [[thisFont fontDescriptor] fontAttributes];
//			NSLog(@"%@", fontInfo);
		}
		NSString* pageHtml = @"<p>";
		for(NSDictionary*d in textParts)
		{
			int fIndex = [[d objectForKey:@"fIndex"] intValue];
			NSString* chunk = [d objectForKey:@"chunk"];
			
			if(fIndex >= 0)
			{
				NSFont*	myFont = [fontStyles objectAtIndex:fIndex];
				NSString*	thisSpan = [NSString stringWithFormat:@"<span class=\"textStyle%d\">%@</span>", fIndex, chunk];
				pageHtml = [pageHtml stringByAppendingString:thisSpan];
			}
			else if([chunk hasSuffix:@"\n"])
			{
				NSString*	thisSpan = [NSString stringWithFormat:@"</p><p>%@", chunk];
				pageHtml = [pageHtml stringByAppendingString:thisSpan];
				NSLog(@"'%@'", chunk);
			}
			else
			{
				pageHtml = [pageHtml stringByAppendingString:chunk];
			}
			
		} //  in text parts
		pageHtml = [pageHtml stringByAppendingString:@"</p>\n"];
		NSLog(pageHtml);
#if 1
		
#endif
		[xportDoc release];
		[pool release];
	}
	NSString*	indexFile = [documentPath stringByAppendingFormat:@"/index.plist"];
	
	NSLog(indexFile);
	BOOL ok = [wordDictionary writeToFile:indexFile atomically:YES];

	// now we need to update the outline for the total number of pages
	NSString*	outlineFile = [documentPath stringByAppendingFormat:@"/outlineItems.plist"];
	NSMutableDictionary* updatedOutline = [NSMutableDictionary dictionaryWithContentsOfFile:outlineFile];
	[updatedOutline setObject:[NSNumber numberWithInt:pageCount] forKey:@"total"];
	[updatedOutline setObject:pageMap forKey:@"pageMap"];
	[updatedOutline writeToFile:outlineFile atomically:YES];
	
#if 0
	NSLog(@"%@", wordDictionary);
	NSArray*	sortedKeys = [[[wordDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
	for(NSString*key in sortedKeys)
	{
	}

	[wordDictionary release];
#endif
} // liftAndSeparate

- (BOOL)saveThumbNail:(PDFDocument*)page ofSize:(NSSize)newSize to:(NSString*)path
{
	NSRect			newRect = NSMakeRect(0.0, 0.0, newSize.width, newSize.height);
	NSImage*		newImage = [[NSImage alloc] initWithSize:newSize];
	NSData*			pageData = [page dataRepresentation];
	NSPDFImageRep*	pdfImage = [NSPDFImageRep imageRepWithData:pageData]; 
	
	
	[newImage setCacheMode:NSImageCacheNever];
	[newImage addRepresentation:pdfImage];
	[newImage lockFocus];
	[pdfImage drawInRect:newRect];
	[newImage unlockFocus];
	[newImage lockFocus];
	NSBitmapImageRep* bippy = [[NSBitmapImageRep alloc] initWithFocusedViewRect:newRect];
	[newImage unlockFocus];
	
	NSDictionary*	repProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:0.9], NSImageCompressionFactor, nil];
	NSData*			jpegData = [(NSBitmapImageRep*)bippy representationUsingType:NSJPEGFileType properties:repProperties];
	
	[newImage autorelease];
	[bippy autorelease];
	return [jpegData writeToFile:path atomically:YES];
}


#if 0
- (NSImage *)imageWithSize:(NSSize)newSize
{
	NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
	NSRect oldRect = NSMakeRect(0.0, 0.0, [self size].width, [self size].height);
	NSRect newRect = NSMakeRect(0.0, 0.0, newSize.width, newSize.height);
	
	[newImage lockFocus];
	[self drawInRect:newRect fromRect:oldRect operation:NSCompositeCopy fraction:1.0];
	[newImage unlockFocus];
	return [newImage autorelease];
}
#endif

@end
