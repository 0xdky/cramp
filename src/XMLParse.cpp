// -*-c++-*-
// Time-stamp: <2003-10-01 18:53:52 dhruva>
//-----------------------------------------------------------------------------
// File : XMLParse.cpp
// Desc : Class implementation for scenario file parsing
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-23-2003  Cre                                                          pie
//-----------------------------------------------------------------------------
#include "TestCaseInfo.h"

#include <list>
#include <string>

#include <xercesc/util/PlatformUtils.hpp>
#include <xercesc/parsers/AbstractDOMParser.hpp>
#include <xercesc/dom/DOMImplementation.hpp>
#include <xercesc/dom/DOMImplementationLS.hpp>
#include <xercesc/dom/DOMImplementationRegistry.hpp>
#include <xercesc/dom/DOMBuilder.hpp>
#include <xercesc/dom/DOMException.hpp>
#include <xercesc/dom/DOMDocument.hpp>
#include <xercesc/dom/DOMNodeList.hpp>
#include <xercesc/dom/DOMError.hpp>
#include <xercesc/dom/DOMLocator.hpp>
#include "XMLParse.h"
#include <string.h>
#include <stdlib.h>
#include <fstream.h>

#include <xercesc/util/PlatformUtils.hpp>
#include <xercesc/util/XMLString.hpp>
#include <xercesc/dom/DOM.hpp>
#include <iostream.h>

#define SCENARIO 1
#define GROUP 2
#define TESTCASE 3

typedef struct{
  char *attrname;
  char *attrvalue;
}MyElement;

typedef struct{
  const char *elem;
  const char *attr;
}ElemAttr;

ElemAttr g_ElemAttrMap[]={
  "SCENARIO", "ID",                     //0
  "SCENARIO", "NAME",                   //1
  "SCENARIO", "RELEASE",                //2
  "SCENARIO", "CREATEDBY",              //3
  "SCENARIO", "DATE",                   //4
  "SCENARIO", "TIME",                   //5
  "SCENARIO", "MAXRUNTIME",             //6
  "SCENARIO", "PROFILING",              //7
  "GROUP"   , "ID",                     //8
  "GROUP"   , "NAME",                   //9
  "GROUP"   , "BLOCK",                  //10
  "GROUP"   , "REINITIALIZEDATA",       //11
  "GROUP"   , "STOPONFIRSTFAILURE",     //12
  "GROUP"   , "PROFILING",              //13
  "TESTCASE", "ID",                     //14
  "TESTCASE", "EXECPATH",               //15
  "TESTCASE", "NUMRUNS",                //16
  "TESTCASE", "NAME",                   //17
  "TESTCASE", "PROFILING",              //18
  0,0};

//-----------------------------------------------------------------------------
// XMLParse
//-----------------------------------------------------------------------------
XMLParse::XMLParse(const char *iXMLFileName){
  _pXMLFileName = iXMLFileName;
  _pParent=0;
}

//-----------------------------------------------------------------------------
// ~XMLParse
//-----------------------------------------------------------------------------
XMLParse::~XMLParse(){
  _pXMLFileName = "";
  _pParent=0;
}

//-----------------------------------------------------------------------------
// ParseXMLFile
//-----------------------------------------------------------------------------
bool
XMLParse::ParseXMLFile(void){
  cout <<endl;

  // Initialize the XML4C2 system.
  try
  {
    XMLPlatformUtils::Initialize();
  }

  catch(const XMLException& toCatch)
  {
    char *pMsg = XMLString::transcode(toCatch.getMessage());
    cout << "Error during Xerces-c Initialization.\n"
         << "  Exception message:"
         << pMsg;
    XMLString::release(&pMsg);
    return (false);
  }

  // Watch for special case help request
  if( _pXMLFileName == "" )
  {
    cout << "\nUsage:\n"
      "    CreateDOMDocument\n\n"
      "This program creates a new DOM document from scratch in memory.\n"
      "It then prints the count of elements in the tree.\n"
         <<  endl;

    XMLPlatformUtils::Terminate();
    return (false);
  }

  // Instantiate the DOM parser.
  static const XMLCh gLS[] = { chLatin_L, chLatin_S, chNull };
  //static const XMLCh gLS[3];
  DOMImplementation *impl=DOMImplementationRegistry::getDOMImplementation(gLS);
  DOMBuilder        *parser = ((DOMImplementationLS*)impl)
    ->createDOMBuilder(DOMImplementationLS::MODE_SYNCHRONOUS, 0);

  bool  doNamespaces       = false;
  bool  doSchema           = false;
  bool  schemaFullChecking = false;

  parser->setFeature(XMLUni::fgDOMNamespaces, doNamespaces);
  parser->setFeature(XMLUni::fgXercesSchema, doSchema);
  parser->setFeature(XMLUni::fgXercesSchemaFullChecking, schemaFullChecking);

  // the input is a list file
  ifstream fin;
  int argInd = 0;
  fin.open(_pXMLFileName);

  if (fin.fail()) {
    cout <<"Cannot open the list file: " << _pXMLFileName << endl;
    return (false);
  }
  else
  {
    cout <<"My file is :: " << _pXMLFileName << endl;
  }

  cout <<endl;

  const char*   xmlFile = 0;
  xmlFile = _pXMLFileName;

  //pass xml file to parser
  DOMDocument *doc = 0;
  doc = parser->parseURI(xmlFile);

  /*int tt=0;
    for(;g_ElemAttrMap[tt].elem;tt++){
    printf("%d>Element:%s Attribute:%s\n",tt+1,g_ElemAttrMap[tt].elem,
    g_ElemAttrMap[tt].attr);
    }
	return (true);*/

  //find root element
  const char *scenarioname = "Scenario";
  DOMElement* rootElem = doc->getDocumentElement();
  char *rootelemname = XMLString::transcode( rootElem->getTagName() );
  cout << "Root Element Name Is ::" << rootelemname << endl;
  XMLString::release(&rootelemname);

  // SCENARIO
  DOMNode *rootnode = rootElem;
  char  *tmpName = "OM";
  ScanXMLFile( rootnode, SCENARIO );

  //terminate the XML parsing
  XMLPlatformUtils::Terminate();

  return (true);
}

//-----------------------------------------------------------------------------
// ScanXMLFile
//-----------------------------------------------------------------------------
void
XMLParse::ScanXMLFile( DOMNode * parentchnode,
                       int type ){

  if( SCENARIO == type )//SCENARIO
  {
    //cout << "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&" << endl;
    ScanForAttributes( parentchnode, SCENARIO );
  }

  //get all nodes
  DOMNodeList *childlist = parentchnode->getChildNodes();
  int childsize = childlist->getLength();
  //cout << "Total Child Is :: " << childsize << endl;
  if( 0 == childsize )
    return;

  char  *textName = "#text";
  char  *groupName = "GROUP";
  char  *testcaseName = "TESTCASE";
  DOMNode *nextnode = NULL;

  for( int ss = 0; ss < childsize; ss++ )
  {
    DOMNode  *parentchnode = childlist->item(ss);

    char *parentchname = XMLString::transcode(parentchnode->getNodeName());

    // #text
    if(0 == XMLString::compareString( parentchname, textName ))
    {
      continue;
    }
    else
    {
      // GROUP
      if( 0 == XMLString::compareString( parentchname, groupName ) )
      {
        ScanForAttributes( parentchnode, GROUP );
        ScanXMLFile( parentchnode, GROUP );
      }
      else if( 0 == XMLString::compareString( parentchname, testcaseName ) )
      {
        // TESTCASE
        ScanForAttributes( parentchnode, TESTCASE );
      }
    }
    XMLString::release(&parentchname);
  }

  return;
}

//-----------------------------------------------------------------------------
// ReturnSubString
//-----------------------------------------------------------------------------
char
*XMLParse::ReturnSubString(char *mainString){
  cout << "Entering TestCase" << endl;

  char* subString = "test";
  unsigned int length = XMLString::stringLen( mainString );

  if( length >= 8 )//exclusively for TestCase string
  {
    cout << "Entering subString :: " << length << " :: " << mainString << endl;
    XMLString::subString( subString, mainString, 0, 8 );
    if( subString == "TestCase" )
    {
      cout << "Leaving TestCase" << endl;
      return( subString );
    }
  }

  return( mainString );
}

//-----------------------------------------------------------------------------
// ScanElementForAttribute
//-----------------------------------------------------------------------------
void
XMLParse::ScanElementForAttribute(DOMNamedNodeMap *pAttlist,
                                  int size){
  if( 0 == size )
    return;
  if( NULL == pAttlist )
    return;

  cout << "  { ATTRIBUE }  " << endl;

  for( int ss = 0; ss < size; ss++ )
  {
    DOMNode  *newAtt = pAttlist->item(ss);
    char* attributeName = XMLString::transcode( newAtt->getNodeName() );
    char* attributeValue = XMLString::transcode( newAtt->getNodeValue() );

    cout << "Name :: " << attributeName << endl;
    cout << "Value :: " << attributeValue << endl;

    XMLString::release(&attributeName);
    XMLString::release(&attributeValue);
  }

  return;
}

//-----------------------------------------------------------------------------
// ScanForAttributes
//-----------------------------------------------------------------------------
void
XMLParse::ScanForAttributes(DOMNode *rootnode,
                            int type ){

  if( NULL == rootnode )
    return;
  DOMNamedNodeMap  *pSceAttlist = NULL;
  int SecSize = 0;
  pSceAttlist  = rootnode->getAttributes();
  SecSize = pSceAttlist->getLength();
  //cout << "Total Attribute :: " << SecSize << endl;
  if( 0 == SecSize )
    return;

  if( 0 == SecSize )
    return;
  if( NULL == pSceAttlist )
    return;

  std::list<MyElement> myelement;
  TestCaseInfo * pChild = 0;

  bool blockfound = false;
  bool blockvalue = true;

  for( int ss = 0; ss < SecSize; ss++ )
  {
    MyElement object;

    DOMNode  *newAtt = pSceAttlist->item(ss);
    char* attriName = XMLString::transcode( newAtt->getNodeName() );
    char* attriValue = XMLString::transcode( newAtt->getNodeValue() );

    //check for block value
    if( 0 == XMLString::compareString( g_ElemAttrMap[10].attr,
                                       attriName ) )//BLOCK
    {
      blockfound = true;
      char *truevalue = "FALSE";
      if( 0 == XMLString::compareString(attriValue, truevalue) )
      {
        blockvalue = false;
      }
    }

    if( 0 == XMLString::compareString( g_ElemAttrMap[0].attr,
                                       attriName ) )//ID
    {
      switch( type )
      {
        case SCENARIO:
          // Create scenario group
          _pParent=TestCaseInfo::CreateScenario(attriValue, true);
          break;
        case GROUP:
          // Create group
          if(blockfound==true)
            pChild =_pParent->AddGroup(attriValue, blockvalue);
          break;
        case TESTCASE:
          // Create testcase
          if(blockfound==true)
            pChild =_pParent->AddTestCase(attriValue, blockvalue);
          break;
        default:
          break;
      }
    }

    object.attrname  = attriName;
    object.attrvalue = attriValue;
    myelement.push_back(object);
  }

  //add more attributes
  for( std::list<MyElement>::iterator from=myelement.begin();
       from!=myelement.end();
       ++from
       )
  {
    switch( type )
    {
      case SCENARIO:
        if( 0 == XMLString::compareString( g_ElemAttrMap[6].attr,
                                           (*from).attrname ) )//MAXRUNTIME
        {
          int time = atoi((*from).attrvalue);
          if( NULL != _pParent )
            _pParent->MaxTimeLimit(time);
        }
        break;
      case GROUP:
        break;
      case TESTCASE:
        //set testcase name
        if( 0 == XMLString::compareString( g_ElemAttrMap[17].attr,
                                           (*from).attrname ) )//NAME
        {
          if( NULL != pChild )
            pChild->TestCaseName((*from).attrvalue);
        }
        //set testcase exe
        if( 0 == XMLString::compareString( g_ElemAttrMap[15].attr,
                                           (*from).attrname ) )//EXECPATH
        {
          if( NULL != pChild )
            pChild->TestCaseExec((*from).attrvalue);
        }
        break;
      default:
        break;
    }

    XMLString::release(&(*from).attrname);
    XMLString::release(&(*from).attrvalue);
  }

  return;
}

//-----------------------------------------------------------------------------
// GetScenario
//-----------------------------------------------------------------------------
TestCaseInfo *
XMLParse::GetScenario(void){
  return( _pParent );
}
