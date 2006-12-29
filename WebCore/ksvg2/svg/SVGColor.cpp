/*
    Copyright (C) 2004, 2005 Nikolas Zimmermann <wildfox@kde.org>
                  2004, 2005, 2006 Rob Buis <buis@kde.org>

    This file is part of the KDE project

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    Boston, MA 02111-1307, USA.
*/

#include "config.h"
#ifdef SVG_SUPPORT
#include "SVGColor.h"

#include "SVGException.h"
#include "SVGParserUtilities.h"

namespace WebCore {

SVGColor::SVGColor()
    : CSSValue()
    , m_colorType(SVG_COLORTYPE_UNKNOWN)
{
}

SVGColor::SVGColor(const String& rgbColor)
    : CSSValue()
    , m_colorType(SVG_COLORTYPE_RGBCOLOR)
{
    setRGBColor(rgbColor);
}

SVGColor::SVGColor(unsigned short colorType)
    : CSSValue()
    , m_colorType(colorType)
{
}

SVGColor::SVGColor(const Color& c)
    : CSSValue()
    , m_color(c)
    , m_colorType(SVG_COLORTYPE_RGBCOLOR)
{
}


SVGColor::~SVGColor()
{
}

unsigned short SVGColor::colorType() const
{
    return m_colorType;
}

unsigned SVGColor::rgbColor() const
{
    return m_color.rgb();
}

#if 0
// FIXME: This shoudl be a hashtable generated by gperf!
static const Color cmap[] =
{
    Color(240, 248, 255),
    Color(250, 235, 215),
    Color(0, 255, 255),
    Color(127, 255, 212),
    Color(240, 255, 255),
    Color(245, 245, 220),
    Color(255, 228, 196),
    Color(0, 0, 0),
    Color(255, 235, 205),
    Color(0, 0, 255),
    Color(138, 43, 226),
    Color(165, 42, 42),
    Color(222, 184, 135),
    Color(95, 158, 160),
    Color(127, 255, 0),
    Color(210, 105, 30),
    Color(255, 127, 80),
    Color(100, 149, 237),
    Color(255, 248, 220),
    Color(220, 20, 60),
    Color(0, 255, 255),
    Color(0, 0, 139),
    Color(0, 139, 139),
    Color(184, 134, 11),
    Color(169, 169, 169),
    Color(169, 169, 169),
    Color(0, 100, 0),
    Color(189, 183, 107),
    Color(139, 0, 139),
    Color(85, 107, 47),
    Color(255, 140, 0),
    Color(153, 50, 204),
    Color(139, 0, 0),
    Color(233, 150, 122),
    Color(143, 188, 143),
    Color(72, 61, 139),
    Color(47, 79, 79),
    Color(47, 79, 79),
    Color(0, 206, 209),
    Color(148, 0, 211),
    Color(255, 20, 147),
    Color(0, 191, 255),
    Color(105, 105, 105),
    Color(105, 105, 105),
    Color(30, 144, 255),
    Color(178, 34, 34),
    Color(255, 250, 240),
    Color(34, 139, 34),
    Color(255, 0, 255),
    Color(220, 220, 220),
    Color(248, 248, 255),
    Color(255, 215, 0),
    Color(218, 165, 32),
    Color(128, 128, 128),
    Color(128, 128, 128),
    Color(0, 128, 0),
    Color(173, 255, 47),
    Color(240, 255, 240),
    Color(255, 105, 180),
    Color(205, 92, 92),
    Color(75, 0, 130),
    Color(255, 255, 240),
    Color(240, 230, 140),
    Color(230, 230, 250),
    Color(255, 240, 245),
    Color(124, 252, 0),
    Color(255, 250, 205),
    Color(173, 216, 230),
    Color(240, 128, 128),
    Color(224, 255, 255),
    Color(250, 250, 210),
    Color(211, 211, 211),
    Color(211, 211, 211),
    Color(144, 238, 144),
    Color(255, 182, 193),
    Color(255, 160, 122),
    Color(32, 178, 170),
    Color(135, 206, 250),
    Color(119, 136, 153),
    Color(119, 136, 153),
    Color(176, 196, 222),
    Color(255, 255, 224),
    Color(0, 255, 0),
    Color(50, 205, 50),
    Color(250, 240, 230),
    Color(255, 0, 255),
    Color(128, 0, 0),
    Color(102, 205, 170),
    Color(0, 0, 205),
    Color(186, 85, 211),
    Color(147, 112, 219),
    Color(60, 179, 113),
    Color(123, 104, 238),
    Color(0, 250, 154),
    Color(72, 209, 204),
    Color(199, 21, 133),
    Color(25, 25, 112),
    Color(245, 255, 250),
    Color(255, 228, 225),
    Color(255, 228, 181),
    Color(255, 222, 173),
    Color(0, 0, 128),
    Color(253, 245, 230),
    Color(128, 128, 0),
    Color(107, 142, 35),
    Color(255, 165, 0),
    Color(255, 69, 0),
    Color(218, 112, 214),
    Color(238, 232, 170),
    Color(152, 251, 152),
    Color(175, 238, 238),
    Color(219, 112, 147),
    Color(255, 239, 213),
    Color(255, 218, 185),
    Color(205, 133, 63),
    Color(255, 192, 203),
    Color(221, 160, 221),
    Color(176, 224, 230),
    Color(128, 0, 128),
    Color(255, 0, 0),
    Color(188, 143, 143),
    Color(65, 105, 225),
    Color(139, 69, 19),
    Color(250, 128, 114),
    Color(244, 164, 96),
    Color(46, 139, 87),
    Color(255, 245, 238),
    Color(160, 82, 45),
    Color(192, 192, 192),
    Color(135, 206, 235),
    Color(106, 90, 205),
    Color(112, 128, 144),
    Color(112, 128, 144),
    Color(255, 250, 250),
    Color(0, 255, 127),
    Color(70, 130, 180),
    Color(210, 180, 140),
    Color(0, 128, 128),
    Color(216, 191, 216),
    Color(255, 99, 71),
    Color(64, 224, 208),
    Color(238, 130, 238),
    Color(245, 222, 179),
    Color(255, 255, 255),
    Color(245, 245, 245),
    Color(255, 255, 0),
    Color(154, 205, 50)
};
#endif

void SVGColor::setRGBColor(const String& rgbColor, ExceptionCode& ec)
{
    ec = SVG_INVALID_VALUE_ERR;
    if (rgbColor.isNull())
        return;

    Color color;
    String parse = rgbColor.stripWhiteSpace();
    if (parse.startsWith("rgb(")) {
        double r = -1, g = -1, b = -1;
        const UChar* ptr = parse.characters() + 4;
        const UChar* end = parse.characters() + parse.length();
        skipOptionalSpaces(ptr, end);
        if (!parseNumber(ptr, end, r))
            return;
        if (*ptr == '%') {
            r = int((255.0 * r) / 100.0);
            ptr++;
        }
        if (!parseNumber(ptr, end, g))
            return;
        if (*ptr == '%') {
            g = int((255.0 * g) / 100.0);
            ptr++;
        }
        if (!parseNumber(ptr, end, b))
            return;
        if (*ptr == '%') {
            b = int((255.0 * b) / 100.0);
            ptr++;
        }

        if (*ptr != ')')
            return;
        ptr++;
        if (ptr != end)
            return;

        color = Color(int(r), int(g), int(b));
    } else {
        String colorName = parse.lower();
        color = Color(colorName);
    }
    if (color.isValid()) {
        ec = 0;
        m_color = color;
    }
}

void SVGColor::setRGBColorICCColor(const String& /* rgbColor */, const String& /* iccColor */, ExceptionCode& ec)
{
    // TODO: implement me!
}

void SVGColor::setColor(unsigned short colorType, const String& /* rgbColor */ , const String& /* iccColor */, ExceptionCode& ec)
{
    // TODO: implement me!
    m_colorType = colorType;
}

String SVGColor::cssText() const
{
    if (m_colorType == SVG_COLORTYPE_RGBCOLOR)
        return m_color.name();

    return String();
}

const Color& SVGColor::color() const
{
    return m_color;
}

}

// vim:ts=4:noet
#endif // SVG_SUPPORT

