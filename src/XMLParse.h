// -*-c++-*-
// Time-stamp: <2003-09-30 17:09:48 dhruva>
//-----------------------------------------------------------------------------
// File : XMLParse.h
// Desc : Header file for scenario file parsing
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          pie
//-----------------------------------------------------------------------------
#pragma once
#include <xercesc/dom/DOMErrorHandler.hpp>
#include <xercesc/util/XMLString.hpp>
#include <xercesc/dom/DOMNodeList.hpp>
#include <xercesc/dom/DOMNamedNodeMap.hpp>
#include <iostream.h>
#include "TestCaseInfo.h"

XERCES_CPP_NAMESPACE_USE

class XMLParse{
public :
  XMLParse( const char * iXMLFileName );
  virtual ~XMLParse();

  bool ParseXMLFile(void);
	TestCaseInfo *GetScenario(void);

private :
  const char      *_pXMLFileName;
	TestCaseInfo    *_pParent;

	void ScanXMLFile( DOMNode * parentchnode, int type );
	void ScanForAttributes(DOMNode *rootnode, int type );
};
