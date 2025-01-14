// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SVGRootPainter_h
#define SVGRootPainter_h

namespace blink {

struct PaintInfo;
class LayoutPoint;
class RenderSVGRoot;

class SVGRootPainter {
public:
    SVGRootPainter(RenderSVGRoot& renderSVGRoot) : m_renderSVGRoot(renderSVGRoot) { }

    void paint(const PaintInfo&, const LayoutPoint&);

private:
    RenderSVGRoot& m_renderSVGRoot;
};

} // namespace blink

#endif // SVGRootPainter_h
