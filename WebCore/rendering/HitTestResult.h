/*
 * This file is part of the HTML rendering engine for KDE.
 *
 * Copyright (C) 2006 Apple Computer, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
*/
#ifndef HitTestResult_h_
#define HitTestResult_h_

#include "IntPoint.h"
#include <wtf/RefPtr.h>

namespace WebCore {

class Element;
class Frame;
class IntRect;
class Node;
class PlatformScrollbar;
class String;

class HitTestResult {
public:
    HitTestResult(const IntPoint&);
    HitTestResult(const HitTestResult&);
    ~HitTestResult();
    HitTestResult& operator=(const HitTestResult&);

    Node* innerNode() const { return m_innerNode.get(); }
    Node* innerNonSharedNode() const { return m_innerNonSharedNode.get(); }
    IntPoint point() const { return m_point; }
    Element* URLElement() const { return m_innerURLElement.get(); }
    PlatformScrollbar* scrollbar() const { return m_scrollbar.get(); }

    void setInnerNode(Node*);
    void setInnerNonSharedNode(Node*);
    void setPoint(const IntPoint& p) { m_point = p; }
    void setURLElement(Element*);
    void setScrollbar(PlatformScrollbar*);

    Frame* targetFrame() const;
    IntRect boundingBox() const;
    bool isSelected() const;
    String title() const;

private:
    RefPtr<Node> m_innerNode;
    RefPtr<Node> m_innerNonSharedNode;
    IntPoint m_point;
    RefPtr<Element> m_innerURLElement;
    RefPtr<PlatformScrollbar> m_scrollbar;
};

} // namespace WebCore

#endif // HitTestResult_h_
