/*
 * Copyright (C) 2004 Apple Computer, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

#import "KWQClipboard.h"
#import "KWQAssertions.h"
#import "KWQFoundationExtras.h"
#import "KWQKHTMLPart.h"
#import "KWQStringList.h"
#import "WebCoreGraphicsBridge.h"

#import <AppKit/AppKit.h>

using DOM::DOMString;

KWQClipboard::KWQClipboard(bool forDragging, NSPasteboard *pasteboard, AccessPolicy policy, KWQKHTMLPart *part)
  : m_pasteboard(KWQRetain(pasteboard)), m_forDragging(forDragging),
    m_dragImageElement(0), m_policy(policy), m_dragStarted(false), m_part(part)
{
    m_changeCount = [m_pasteboard changeCount];
}

KWQClipboard::~KWQClipboard()
{
    KWQRelease(m_pasteboard);
}

bool KWQClipboard::isForDragging() const
{
    return m_forDragging;
}

void KWQClipboard::setAccessPolicy(AccessPolicy policy)
{
    // once you go numb, can never go back
    ASSERT(m_policy != Numb || policy == Numb);
    m_policy = policy;
}

KWQClipboard::AccessPolicy KWQClipboard::accessPolicy() const
{
    return m_policy;
}

// FIXME hardwired for now, will use UTI
static NSString *cocoaTypeFromMIMEType(const DOMString &type) {
    QString qType = type.string();

    // two special cases for IE compatibility
    if (qType == "Text") {
        return NSStringPboardType;
    } else if (qType == "URL") {
        return NSURLPboardType;
    } 
    
    // Cut off any trailing charset - JS String are Unicode, which encapsulates this issue
    int semicolon = qType.find(';');
    if (semicolon >= 0) {
        qType = qType.left(semicolon+1);
    }
    qType = qType.stripWhiteSpace();

    if (!qType.compare("text/plain")) {
        return NSStringPboardType;
    } else if (!qType.compare("text/html")) {
        return NSHTMLPboardType;
    } else if (!qType.compare("text/rtf")) {
        return NSRTFPboardType;
    } else if (!qType.compare("text/uri-list")) {
        return NSURLPboardType;     // note fallback to NSFilenamesPboardType in caller
    } else {
        // FIXME - Better fallback for application/Foo might be to take Foo
        return qType.getNSString();
    }
}

static QString MIMETypeFromCocoaType(NSString *type)
{
    if ([type isEqualToString:NSStringPboardType]) {
        return QString("text/plain");
    } else if ([type isEqualToString:NSURLPboardType]
               || [type isEqualToString:NSFilenamesPboardType]) {
        return QString("text/uri-list");
    } else if ([type isEqualToString:NSHTMLPboardType]) {
        return QString("text/html");
    } else if ([type isEqualToString:NSRTFPboardType]) {
        return QString("text/rtf");
    } else {
        // FIXME - Better fallback for Foo might be application/Foo
        // FIXME - Ignore way old _NSAsciiPboardType, used by 3.3 apps
        return QString::fromNSString(type);
    }    
}

void KWQClipboard::clearData(const DOMString &type)
{
    if (m_policy != Writable) {
        return;
    }
    // note NSPasteboard enforces changeCount itself on writing - can't write if not the owner

    NSString *cocoaType = cocoaTypeFromMIMEType(type);
    if (cocoaType) {
        [m_pasteboard setString:@"" forType:cocoaType];
    }
}

void KWQClipboard::clearAllData()
{
    if (m_policy != Writable) {
        return;
    }
    // note NSPasteboard enforces changeCount itself on writing - can't write if not the owner

    [m_pasteboard declareTypes:[NSArray array] owner:nil];
}

DOMString KWQClipboard::getData(const DOMString &type, bool &success) const
{
    success = false;
    if (m_policy != Readable) {
        return DOMString();
    }
    
    NSString *cocoaType = cocoaTypeFromMIMEType(type);
    NSString *cocoaValue = nil;
    NSArray *availableTypes = [m_pasteboard types];

    // Fetch the data in different ways for the different Cocoa types
    if (cocoaType == NSURLPboardType) {
        NSURL *url = nil;
        // must check this or we get a printf from CF when there's no data of this type
        if ([availableTypes containsObject:NSURLPboardType]) {
            url = [NSURL URLFromPasteboard:m_pasteboard];
        }
        if (url) {
            cocoaValue = [url absoluteString];
        } else {
            // Try Filenames type (in addition to URL type) when client requests text/uri-list
            cocoaType = NSFilenamesPboardType;
            cocoaValue = nil;
        }
    }

    if (cocoaType == NSFilenamesPboardType) {
        NSArray *fileList = nil;
        // must check this or we get a printf from CF when there's no data of this type
        if ([availableTypes containsObject:NSFilenamesPboardType]) {
            fileList = [m_pasteboard propertyListForType:cocoaType];
        }
        if (fileList && [fileList count] > 0) {
            NSMutableString *urls = [NSMutableString string];
            unsigned i;
            for (i = 0; i < [fileList count]; i++) {
                if (i > 0) {
                    [urls appendString:@"\n"];
                }
                NSURL *url = [NSURL fileURLWithPath:[fileList objectAtIndex:i]];
                [urls appendString:[url absoluteString]];
            }
            cocoaValue = urls;
        } else {
            cocoaValue = nil;
        }
    } else if (cocoaType && !cocoaValue) {        
        cocoaValue = [m_pasteboard stringForType:cocoaType];
    }

    // Enforce changeCount ourselves for security.  We check after reading instead of before to be
    // sure it doesn't change between our testing the change count and accessing the data.
    if (cocoaValue && m_changeCount == [m_pasteboard changeCount]) {
        success = true;
        return DOMString(QString::fromNSString(cocoaValue));
    } else {
        return DOMString();
    }
}

bool KWQClipboard::setData(const DOMString &type, const DOMString &data)
{
    if (m_policy != Writable) {
        return false;
    }
    // note NSPasteboard enforces changeCount itself on writing - can't write if not the owner

    NSString *cocoaType = cocoaTypeFromMIMEType(type);
    NSString *cocoaData = data.string().getNSString();
    if (cocoaType == NSURLPboardType) {
        [m_pasteboard addTypes:[NSArray arrayWithObject:NSURLPboardType] owner:nil];
        NSURL *url = [[NSURL alloc] initWithString:cocoaData];
        [url writeToPasteboard:m_pasteboard];
        
        if ([url isFileURL]) {
            [m_pasteboard addTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
            NSArray *fileList = [NSArray arrayWithObject:[url path]];
            [m_pasteboard setPropertyList:fileList forType:NSFilenamesPboardType];
        }

        [url release];
        return true;
    } else if (cocoaType) {
        // everything else we know of goes on the pboard as a string
        [m_pasteboard addTypes:[NSArray arrayWithObject:cocoaType] owner:nil];
        return [m_pasteboard setString:cocoaData forType:cocoaType];
    } else {
        return false;
    }
}

QStringList KWQClipboard::types() const
{
    if (m_policy != Readable && m_policy != TypesReadable) {
        return QStringList();
    }

    NSArray *types = [m_pasteboard types];

    // Enforce changeCount ourselves for security.  We check after reading instead of before to be
    // sure it doesn't change between our testing the change count and accessing the data.
    if (m_changeCount != [m_pasteboard changeCount]) {
        return QStringList();
    }

    QStringList result;
    if (types) {
        unsigned count = [types count];
        unsigned i;
        for (i = 0; i < count; i++) {
            QString qstr = MIMETypeFromCocoaType([types objectAtIndex:i]);
            if (!result.contains(qstr)) {
                result.append(qstr);
            }
        }
    }
    return result;
}

// The rest of these getters don't really have any impact on security, so for now make no checks

QPoint KWQClipboard::dragLocation() const
{
    return m_dragLoc;
}

QPixmap KWQClipboard::dragImage() const
{
    return m_dragImage;
}

void KWQClipboard::setDragImage(const QPixmap &pm, const QPoint &loc)
{
    setDragImage(pm, DOM::Node(0), loc);
}

const DOM::Node KWQClipboard::dragImageElement()
{
    return m_dragImageElement;
}

void KWQClipboard::setDragImageElement(const DOM::Node &node, const QPoint &loc)
{
    setDragImage(QPixmap(), node, loc);
}

void KWQClipboard::setDragImage(const QPixmap &pm, const DOM::Node &node, const QPoint &loc)
{
    if (m_policy == ImageWritable || m_policy == Writable) {
        m_dragImage = pm;
        m_dragLoc = loc;
        m_dragImageElement = node;
        
        if (m_dragStarted && m_changeCount == [m_pasteboard changeCount]) {
            NSPoint cocoaLoc;
            NSImage *cocoaImage = dragNSImage(&cocoaLoc);
            if (cocoaImage) {
                [[WebCoreGraphicsBridge sharedBridge] setDraggingImage:cocoaImage at:cocoaLoc];
            }
        }
        // Else either 1) we haven't started dragging yet, so we rely on the part to install this drag image
        // as part of getting the drag kicked off, or 2) Someone kept a ref to the clipboard and is trying to
        // set the image way too late.
    }
}

NSImage *KWQClipboard::dragNSImage(NSPoint *loc)
{
    NSImage *result = nil;
    if (!m_dragImageElement.isNull()) {
        if (m_part) {
            NSRect imageRect;
            NSRect elementRect;
            result = m_part->snapshotDragImage(m_dragImageElement, &imageRect, &elementRect);
            if (loc) {
                // Client specifies point relative to element, not the whole image, which may include child
                // layers spread out all over the place.
                loc->x = elementRect.origin.x - imageRect.origin.x + m_dragLoc.x();
                loc->y = elementRect.origin.y - imageRect.origin.y + m_dragLoc.y();
                loc->y = imageRect.size.height - loc->y;
            }
        }
    } else {
        result = m_dragImage.image();
        if (loc) {
            *loc = NSPoint(m_dragLoc);
            loc->y = [result size].height - loc->y;
        }
    }
    return result;
}

DOM::DOMString KWQClipboard::dropEffect() const
{
    return m_dropEffect;
}

void KWQClipboard::setDropEffect(const DOM::DOMString &s)
{
    if (m_policy == Writable) {
        m_dropEffect = s;
    }
}

DOM::DOMString KWQClipboard::effectAllowed() const
{
    return m_effectAllowed;
}

void KWQClipboard::setEffectAllowed(const DOM::DOMString &s)
{
    if (m_policy == Writable) {
        m_effectAllowed = s;
    }
}

// These "conversion" methods are called by the bridge and part, and never make sense to JS, so we don't
// worry about security for these.  The don't allow access to the pasteboard anyway.

static NSDragOperation cocoaOpFromIEOp(const DOMString &op) {
    // yep, it's really just this fixed set
    if (op == "none") {
        return NSDragOperationNone;
    } else if (op == "copy") {
        return NSDragOperationCopy;
    } else if (op == "link") {
        return NSDragOperationLink;
    } else if (op == "move") {
        return NSDragOperationGeneric;
    } else if (op == "copyLink") {
        return NSDragOperationCopy | NSDragOperationLink;
    } else if (op == "copyMove") {
        return NSDragOperationCopy | NSDragOperationGeneric | NSDragOperationMove;
    } else if (op == "linkMove") {
        return NSDragOperationLink | NSDragOperationGeneric | NSDragOperationMove;
    } else if (op == "all") {
        return NSDragOperationEvery;
    } else {
        return NSDragOperationPrivate;  // really a marker for "no conversion"
    }
}

static const DOMString IEOpFromCocoaOp(NSDragOperation op) {
    bool moveSet = ((NSDragOperationGeneric | NSDragOperationMove) & op) != 0;
    
    if ((moveSet && (op & NSDragOperationCopy) && (op & NSDragOperationLink))
        || (op == NSDragOperationEvery)) {
        return "all";
    } else if (moveSet && (op & NSDragOperationCopy)) {
        return "copyMove";
    } else if (moveSet && (op & NSDragOperationLink)) {
        return "linkMove";
    } else if ((op & NSDragOperationCopy) && (op & NSDragOperationLink)) {
        return "copyLink";
    } else if (moveSet) {
        return "move";
    } else if (op & NSDragOperationCopy) {
        return "copy";
    } else if (op & NSDragOperationLink) {
        return "link";
    } else {
        return "none";
    }
}

bool KWQClipboard::sourceOperation(NSDragOperation *op) const
{
    if (m_effectAllowed.isNull()) {
        return false;
    } else {
        *op = cocoaOpFromIEOp(m_effectAllowed);
        return true;
    }
}

bool KWQClipboard::destinationOperation(NSDragOperation *op) const
{
    if (m_dropEffect.isNull()) {
        return false;
    } else {
        *op = cocoaOpFromIEOp(m_dropEffect);
        return true;
    }
}

void KWQClipboard::setSourceOperation(NSDragOperation op)
{
    m_effectAllowed = IEOpFromCocoaOp(op);
}

void KWQClipboard::setDestinationOperation(NSDragOperation op)
{
    m_dropEffect = IEOpFromCocoaOp(op);
}
