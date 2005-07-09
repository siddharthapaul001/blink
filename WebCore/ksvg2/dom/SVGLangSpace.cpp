/*
    Copyright (C) 2004 Nikolas Zimmermann <wildfox@kde.org>
				  2004 Rob Buis <buis@kde.org>

    This file is part of the KDE project

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the died warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    Boston, MA 02111-1307, USA.
*/

#include <kdom/kdom.h>
#include <kdom/ecma/Ecma.h>
#include <kdom/DOMString.h>
#include <kdom/DOMException.h>
#include <kdom/impl/DOMImplementationImpl.h>

#include "SVGLangSpace.h"
#include "SVGException.h"
#include "SVGExceptionImpl.h"
#include "SVGLangSpaceImpl.h"

#include "SVGConstants.h"
#include "SVGLangSpace.lut.h"
using namespace KSVG;

/*
@begin SVGLangSpace::s_hashTable 3
 xmllang	SVGLangSpaceConstants::Xmllang	DontDelete
 xmlspace	SVGLangSpaceConstants::Xmlspace	DontDelete
@end
*/

Value SVGLangSpace::getValueProperty(ExecState *exec, int token) const
{
	KDOM_ENTER_SAFE

	switch(token)
	{
		case SVGLangSpaceConstants::Xmllang:
			return KDOM::getDOMString(xmlLang());
		case SVGLangSpaceConstants::Xmlspace:
			return KDOM::getDOMString(xmlSpace());
		default:
			kdWarning() << "Unhandled token in " << k_funcinfo << " : " << token << endl;
	}

	KDOM_LEAVE_SAFE(SVGException)
	return Undefined();
}

void SVGLangSpace::putValueProperty(ExecState *exec, int token, const Value &value, int)
{
	KDOM_ENTER_SAFE

	KDOM::DOMString stringValue = KDOM::toDOMString(exec, value);

	switch(token)
	{
		case SVGLangSpaceConstants::Xmllang:
		{
			setXmlLang(stringValue);
			break;
		}
		case SVGLangSpaceConstants::Xmlspace:
		{
			setXmlSpace(stringValue);
			break;
		}
		default:
			kdWarning() << "Unhandled token in " << k_funcinfo << " : " << token << endl;
	}

	KDOM_LEAVE_SAFE(SVGException)
}

SVGLangSpace::SVGLangSpace() : impl(0)
{
}

SVGLangSpace::SVGLangSpace(SVGLangSpaceImpl *i) : impl(i)
{
}

SVGLangSpace::SVGLangSpace(const SVGLangSpace &other) : impl(0)
{
	(*this) = other;
}

SVGLangSpace::~SVGLangSpace()
{
}

SVGLangSpace &SVGLangSpace::operator=(const SVGLangSpace &other)
{
	if(impl != other.impl)
		impl = other.impl;

	return *this;
}

SVGLangSpace &SVGLangSpace::operator=(SVGLangSpaceImpl *other)
{
	if(impl != other)
		impl = other;

	return *this;
}

KDOM::DOMString SVGLangSpace::xmlLang() const
{
	if(!impl)
		return KDOM::DOMString();

	return KDOM::DOMString(impl->xmlLang());
}

void SVGLangSpace::setXmlLang(const KDOM::DOMString &xmlLang)
{
	if(impl)
		impl->setXmlLang(xmlLang.implementation());
}

KDOM::DOMString SVGLangSpace::xmlSpace() const
{
	if(!impl)
		return KDOM::DOMString();

	return KDOM::DOMString(impl->xmlSpace());
}

void SVGLangSpace::setXmlSpace(const KDOM::DOMString &xmlSpace)
{
	if(impl)
		impl->setXmlSpace(xmlSpace.implementation());
}

// vim:ts=4:noet
