// -*-c++-*-
// Time-stamp: <2003-10-07 12:57:44 dhruva>
//-----------------------------------------------------------------------------
// File : XMLParse.cpp
// Desc : Class implementation for scenario file parsing
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-23-2003  Cre                                                          pie
//-----------------------------------------------------------------------------
#include "cramp.h"
#include "TestCaseInfo.h"
#include "XMLParse.h"

#include <list>
#include <string>

// #include <string.h>
#include <stdlib.h>
#include <fstream.h>

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
  _pXMLFileName=iXMLFileName;
  _pParent=0;
}

//-----------------------------------------------------------------------------
// ~XMLParse
//-----------------------------------------------------------------------------
XMLParse::~XMLParse(){
  _pXMLFileName="";
  _pParent=0;
}

//-----------------------------------------------------------------------------
// ParseXMLFile
//-----------------------------------------------------------------------------
bool
XMLParse::ParseXMLFile(void){
  bool ret=false;

  cout <<endl;

  // Initialize the XML4C2 system.
  try{
    XMLPlatformUtils::Initialize();
  }

  catch(const XMLException& toCatch){
    char *pMsg=XMLString::transcode(toCatch.getMessage());
    cout << "Error during Xerces-c Initialization.\n"
         << "  Exception message:"
         << pMsg;
    XMLString::release(&pMsg);
    return(ret);
  }

  do{

    // Watch for special case help request
    if(_pXMLFileName==""){
      cout << "\nUsage:\n"
        "    CreateDOMDocument\n\n"
        "This program creates a new DOM document from scratch in memory.\n"
        "It then prints the count of elements in the tree.\n"
           <<  endl;
      break;
    }

    // Instantiate the DOM parser.
    static const XMLCh gLS[]={chLatin_L,chLatin_S,chNull};
    //static const XMLCh gLS[3];
    DOMImplementation *impl=0;
    impl=DOMImplementationRegistry::getDOMImplementation(gLS);
    if(!impl)
      break;

    DOMBuilder *parser=0;
    parser=((DOMImplementationLS *)impl)->createDOMBuilder(
      DOMImplementationLS::MODE_SYNCHRONOUS,0);
    if(!parser)
      break;

    bool doNamespaces=false;
    bool doSchema=false;
    bool schemaFullChecking=false;

    parser->setFeature(XMLUni::fgDOMNamespaces,doNamespaces);
    parser->setFeature(XMLUni::fgXercesSchema,doSchema);
    parser->setFeature(XMLUni::fgXercesSchemaFullChecking,schemaFullChecking);

    // the input is a list file
    ifstream fin;
    int argInd=0;
    fin.open(_pXMLFileName);

    if(fin.fail()) {
      cout << "Cannot open the list file: " << _pXMLFileName << endl;
      break;
    }else{
      cout <<"My file is :: " << _pXMLFileName << endl;
    }
    cout <<endl;

    const char *xmlFile=0;
    xmlFile=_pXMLFileName;

    // Pass xml file to parser
    DOMDocument *doc=0;
    doc=parser->parseURI(xmlFile);
    if(!doc)
      break;

    // int tt=0;
    // for(;g_ElemAttrMap[tt].elem;tt++){
    //   printf("%d>Element:%s Attribute:%s\n",tt+1,g_ElemAttrMap[tt].elem,
    //          g_ElemAttrMap[tt].attr);
    // }
    // return(ret);

    // Find root element
    DOMElement *rootElem=0;
    rootElem=doc->getDocumentElement();
    if(!rootElem)
      break;

    char *rootelemname=XMLString::transcode(rootElem->getTagName());
    cout << "Root Element Name Is ::" << rootelemname << endl;
    if(XMLString::compareString(rootelemname,"SCENARIO"))
      break;
    XMLString::release(&rootelemname);

    // SCENARIO
    DOMNode *rootnode=rootElem;
    ScanXMLFile(rootnode,SCENARIO);
    ret=true;
  }while(0);

  // Terminate the XML parsing
  XMLPlatformUtils::Terminate();

  return(ret);
}

//-----------------------------------------------------------------------------
// ScanXMLFile
//-----------------------------------------------------------------------------
void
XMLParse::ScanXMLFile(DOMNode *parentchnode,int type){

  // SCENARIO
  if(SCENARIO==type)
    ScanForAttributes(parentchnode,SCENARIO);

  // Get all nodes
  DOMNodeList *childlist=parentchnode->getChildNodes();
  if(!childlist)
    return;

  int childsize=childlist->getLength();
  if(!childsize)
    return;

  char  *textName="#text";
  char  *groupName="GROUP";
  char  *testcaseName="TESTCASE";
  DOMNode *nextnode=0;

  for(int ss=0;ss<childsize;ss++){
    DOMNode *parentchnode=0;
    parentchnode=childlist->item(ss);
    if(!parentchnode)
      continue;

    char *parentchname=XMLString::transcode(parentchnode->getNodeName());

    // #text
    if(!XMLString::compareString(parentchname,textName))
      continue;

    // GROUP
    if(!XMLString::compareString(parentchname,groupName)){
      ScanForAttributes(parentchnode,GROUP);
      ScanXMLFile(parentchnode,GROUP);
    }else if(!XMLString::compareString(parentchname,testcaseName)){
      // TESTCASE
      ScanForAttributes(parentchnode,TESTCASE);
    }
    XMLString::release(&parentchname);
  }
  return;
}

//-----------------------------------------------------------------------------
// ScanForAttributes
//-----------------------------------------------------------------------------
void
XMLParse::ScanForAttributes(DOMNode *rootnode,
                            int type){

  if(!rootnode)
    return;

  int SecSize=0;
  DOMNamedNodeMap *pSceAttlist=0;

  pSceAttlist=rootnode->getAttributes();
  if(!pSceAttlist)
    return;

  SecSize=pSceAttlist->getLength();
  if(!SecSize)
    return;

  std::list<MyElement> myelement;
  TestCaseInfo *pChild=0;

  bool blockfound=false;
  bool blockvalue=true;

  for(int ss=0;ss<SecSize;ss++){
    MyElement object;

    DOMNode  *newAtt=pSceAttlist->item(ss);
    char *attriName=XMLString::transcode(newAtt->getNodeName() );
    char *attriValue=XMLString::transcode(newAtt->getNodeValue());

    // BLOCK
    if(!XMLString::compareString(g_ElemAttrMap[10].attr,
                                 attriName)){
      blockfound=true;
      char *truevalue="FALSE";
      if(!XMLString::compareString(attriValue,truevalue))
        blockvalue = false;
    }

    // ID
    if(!XMLString::compareString(g_ElemAttrMap[0].attr,
                                 attriName)){
      switch(type){
        case SCENARIO:
          // Create scenario group
          _pParent=TestCaseInfo::CreateScenario(attriValue,true);
          break;
        case GROUP:
          // Create group
          if(blockfound==true)
            pChild =_pParent->AddGroup(attriValue,blockvalue);
          break;
        case TESTCASE:
          // Create testcase
          if(blockfound==true)
            pChild =_pParent->AddTestCase(attriValue,blockvalue);
          break;
        default:
          break;
      }
    }

    object.attrname  = attriName;
    object.attrvalue = attriValue;
    myelement.push_back(object);
  }

  // Add more attributes
  std::list<MyElement>::iterator from=myelement.begin();
  for(;from!=myelement.end();++from){
    switch(type){
      case SCENARIO:
        // MAXRUNTIME
        if(!XMLString::compareString(g_ElemAttrMap[6].attr,
                                     (*from).attrname)){
          int time=atoi((*from).attrvalue);
          if(_pParent)
            _pParent->MaxTimeLimit(time);
        }
        break;
      case GROUP:
        break;
      case TESTCASE:
        if(!pChild)
          break;
        if(!XMLString::compareString(g_ElemAttrMap[17].attr,
                                     (*from).attrname)){
          // NAME
          pChild->TestCaseName((*from).attrvalue);
        }else if(!XMLString::compareString(g_ElemAttrMap[15].attr,
                                           (*from).attrname)){
          // EXECPATH
          pChild->TestCaseExec((*from).attrvalue);
        }else if(!XMLString::compareString(g_ElemAttrMap[16].attr,
                                           (*from).attrname)){
          // NUMRUNS
          int time=atoi((*from).attrvalue);
          pChild->NumberOfRuns(time);
        }
        break;
      default:
        break;
    }
    XMLString::release(&(*from).attrname);
    XMLString::release(&(*from).attrvalue);
  }
  myelement.clear();

  return;
}

//-----------------------------------------------------------------------------
// GetScenario
//-----------------------------------------------------------------------------
TestCaseInfo
*XMLParse::GetScenario(void){
  return(_pParent);
}
