// -*-c++-*-
// Time-stamp: <2003-12-11 09:10:43 dhruva>
//-----------------------------------------------------------------------------
// File : XMLParse.cpp
// Desc : Class implementation for scenario file parsing
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-23-2003  Cre                                                          pie
//-----------------------------------------------------------------------------
#define __XMLPARSE_SRC

#include "cramp.h"
#include "TestCaseInfo.h"
#include "XMLParse.h"

#include <list>
#include <string>

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

typedef enum{
  ID=0,
  IDREF,
  NAME,
  RELEASE,
  MAXRUNTIME,
  PROFILING,
  BLOCK,
  REINITIALIZEDATA,
  STOPONFIRSTFAILURE,
  EXECPATH,
  NUMRUNS,
  EXEPROC,
  MONPROC,
  MONINTERVAL
}AttributeEnum;

// Internal map between value and attribute
typedef struct{
  int index;
  char *attrvalue;
}MyElement;

// Map between major type and attributes
typedef struct{
  int type;
  const char *attr;
  AttributeEnum attrenum;
}ElemAttr;

ElemAttr g_ElemAttrMap[]={
  SCENARIO, "ID"                  ,   ID                  ,
  SCENARIO, "NAME"                ,   NAME                ,
  SCENARIO, "BLOCK"               ,   BLOCK               ,
  SCENARIO, "RELEASE"             ,   RELEASE             ,
  SCENARIO, "MAXRUNTIME"          ,   MAXRUNTIME          ,
  SCENARIO, "PROFILING"           ,   PROFILING           ,
  SCENARIO, "MONINTERVAL"         ,   MONINTERVAL         ,
  GROUP   , "ID"                  ,   ID                  ,
  GROUP   , "IDREF"               ,   IDREF               ,
  GROUP   , "NAME"                ,   NAME                ,
  GROUP   , "BLOCK"               ,   BLOCK               ,
  GROUP   , "MAXRUNTIME"          ,   MAXRUNTIME          ,
  GROUP   , "REINITIALIZEDATA"    ,   REINITIALIZEDATA    ,
  GROUP   , "STOPONFIRSTFAILURE"  ,   STOPONFIRSTFAILURE  ,
  GROUP   , "PROFILING"           ,   PROFILING           ,
  TESTCASE, "ID"                  ,   ID                  ,
  TESTCASE, "IDREF"               ,   IDREF               ,
  TESTCASE, "EXECPATH"            ,   EXECPATH            ,
  TESTCASE, "NUMRUNS"             ,   NUMRUNS             ,
  TESTCASE, "NAME"                ,   NAME                ,
  TESTCASE, "PROFILING"           ,   PROFILING           ,
  TESTCASE, "MAXRUNTIME"          ,   MAXRUNTIME          ,
  TESTCASE, "BLOCK"               ,   BLOCK               ,
  TESTCASE, "EXEPROC"             ,   EXEPROC             ,
  TESTCASE, "MONPROC"             ,   MONPROC             ,
  0,0};

//-----------------------------------------------------------------------------
// XMLParse
//-----------------------------------------------------------------------------
XMLParse::XMLParse(const char *iXMLFileName){
  _pXMLFileName=iXMLFileName;
  _pRoot=0;
  _pCurrentParent=0;
}

//-----------------------------------------------------------------------------
// ~XMLParse
//-----------------------------------------------------------------------------
XMLParse::~XMLParse(){
  _pXMLFileName="";
  _pRoot=0;
}

//-----------------------------------------------------------------------------
// ParseXMLFile
//-----------------------------------------------------------------------------
bool
XMLParse::ParseXMLFile(void){
  bool ret=false;
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
    DEBUGCHK(parser);

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
    DEBUGCHK(!fin.fail());

    const char *xmlFile=0;
    xmlFile=_pXMLFileName;

    // Pass xml file to parser
    DOMDocument *doc=0;
    doc=parser->parseURI(xmlFile);
    DEBUGCHK(doc);

    // Find root element
    DOMElement *rootElem=0;
    rootElem=doc->getDocumentElement();
    DEBUGCHK(rootElem);

    char *rootelemname=XMLString::transcode(rootElem->getTagName());
    DEBUGCHK(!stricmp(rootelemname,"SCENARIO"));
    if(rootelemname)
      XMLString::release(&rootelemname);

    // SCENARIO
    DOMNode *rootnode=rootElem;
    if(!ScanXMLFile(rootnode,SCENARIO)){
      if(_pRoot)
        TestCaseInfo::DeleteScenario(_pRoot);
      break;
    }
    ret=true;
  }while(0);

  // Terminate the XML parsing
  XMLPlatformUtils::Terminate();

  return(ret);
}

//-----------------------------------------------------------------------------
// ScanXMLFile
//-----------------------------------------------------------------------------
bool
XMLParse::ScanXMLFile(DOMNode *parentchnode,int type){
  // SCENARIO
  if(SCENARIO==type)
    if(!ScanForAttributes(parentchnode,SCENARIO))
      return(false);

  // Get all nodes
  DOMNodeList *childlist=parentchnode->getChildNodes();
  if(!childlist)
    return(false);

  int childsize=childlist->getLength();
  if(!childsize)
    return(false);

  char  *textName="#text";
  char  *groupName="GROUP";
  char  *testcaseName="TESTCASE";
  DOMNode *nextnode=0;

  for(int ss=0;ss<childsize;ss++){
    DOMNode *parentchnode=0;
    parentchnode=childlist->item(ss);
    if(!parentchnode)
      continue;

    char *parentchname=0;
    parentchname=XMLString::transcode(parentchnode->getNodeName());

    // #TEXT
    if(!stricmp(parentchname,textName))
      continue;

    // GROUP
    if(!stricmp(parentchname,groupName)){
      if(!ScanForAttributes(parentchnode,GROUP))
        return(false);
      if(!ScanXMLFile(parentchnode,GROUP))
        return(false);
    }else if(!stricmp(parentchname,testcaseName)){
      // TESTCASE
      if(!ScanForAttributes(parentchnode,TESTCASE))
        return(false);
    }
    XMLString::release(&parentchname);
  }
  return(true);
}

//-----------------------------------------------------------------------------
// ScanForAttributes
//-----------------------------------------------------------------------------
bool
XMLParse::ScanForAttributes(DOMNode *rootnode,
                            int type){
  if(!rootnode)
    return(false);

  int SecSize=0;
  DOMNamedNodeMap *pSceAttlist=0;

  pSceAttlist=rootnode->getAttributes();
  if(!pSceAttlist)
    return(false);

  SecSize=pSceAttlist->getLength();
  if(!SecSize)
    return(false);

  std::list<MyElement> myelement;
  TestCaseInfo *pChild=0;
  bool created=false;
  char *pIDval=0;

  for(int ss=0;ss<SecSize;ss++){
    MyElement object;
    object.index=-1;

    DOMNode *newAtt=pSceAttlist->item(ss);
    char *attriName=XMLString::transcode(newAtt->getNodeName());
    char *attriValue=XMLString::transcode(newAtt->getNodeValue());
    bool valid=false;

    for(int zz=0;!valid&&g_ElemAttrMap[zz].attr;zz++){
      if(type==g_ElemAttrMap[zz].type)
        if(!stricmp(g_ElemAttrMap[zz].attr,
                    attriName)){
          object.index=zz;
          object.attrvalue=attriValue;
          myelement.push_back(object);
          valid=true;
          if(!stricmp(attriName,"ID")){
            pIDval=new char[strlen(attriValue)+1];
            strcpy(pIDval,attriValue);
          }
        }
      if(!valid)
        continue;
    }
    XMLString::release(&attriName);
  }

  // ID has to be used at creation time! Do it first
  switch(type){
    case SCENARIO:
      // Create scenario group
      try{
        pChild=TestCaseInfo::CreateScenario(pIDval);
        _pRoot=pChild;
        _pCurrentParent=_pRoot;
        created=true;
      }
      catch(CRAMPException excep){
        return(false);
      }
      break;
    case GROUP:
      // Create group
      pChild=_pCurrentParent->AddGroup(pIDval);
      if(pChild)
        _pCurrentParent=pChild;
      created=true;
      break;
    case TESTCASE:
      // Create testcase
      pChild=_pCurrentParent->AddTestCase(pIDval);
      created=true;
      break;
    default:
      break;
  }
  if(pIDval)
    delete [] pIDval;
  pIDval=0;

  DEBUGCHK(pChild);

  bool ret=false;
  do{
    if(!pChild)
      break;

    // Add more attributes
    std::list<MyElement>::iterator from=myelement.begin();
    for(;from!=myelement.end();++from){
      switch(g_ElemAttrMap[(*from).index].attrenum){
        case ID:
          break;
        case IDREF:
          try{
            pChild->SetIDREF((*from).attrvalue);
          }
          catch(CRAMPException excep){
            TestCaseInfo::DeleteScenario(_pRoot);
            _pRoot=0;
            return(false);
          }
          break;
        case NAME:
          pChild->TestCaseName((*from).attrvalue);
          break;
        case RELEASE:
          break;
        case MAXRUNTIME:
        {
          SIZE_T time=atol((*from).attrvalue);
          pChild->MaxTimeLimit(time);
          break;
        }
        case MONINTERVAL:
        {
          SIZE_T time=atol((*from).attrvalue);
          pChild->MonitorInterval(time);
          break;
        }
        case PROFILING:
          break;
        case BLOCK:
          pChild->BlockStatus((stricmp((*from).attrvalue,"FALSE")&&
                               (!stricmp((*from).attrvalue,"TRUE")
                                ||strcmp((*from).attrvalue,"0"))));
          break;
        case REINITIALIZEDATA:
          break;
        case STOPONFIRSTFAILURE:
          break;
        case EXECPATH:
          pChild->TestCaseExec((*from).attrvalue);
          break;
        case MONPROC:
          pChild->MonProcStatus((stricmp((*from).attrvalue,"FALSE")&&
                                 (!stricmp((*from).attrvalue,"TRUE")
                                  ||strcmp((*from).attrvalue,"0"))));
          break;
        case EXEPROC:
          pChild->ExeProcStatus((stricmp((*from).attrvalue,"FALSE")&&
                                 (!stricmp((*from).attrvalue,"TRUE")
                                  ||strcmp((*from).attrvalue,"0"))));
          break;
        case NUMRUNS:
        {
          SIZE_T time=atol((*from).attrvalue);
          pChild->NumberOfRuns(time);
          break;
        }
        default:
          break;
      }
      XMLString::release(&(*from).attrvalue);
    }
    pChild=0;
    myelement.clear();
    ret=true;
  }while(0);

  return(ret);
}

//-----------------------------------------------------------------------------
// GetScenario
//-----------------------------------------------------------------------------
TestCaseInfo
*XMLParse::GetScenario(void){
  return(_pRoot);
}
