// -*-c++-*-
// Time-stamp: <2003-09-30 17:16:54 dhruva>
//-----------------------------------------------------------------------------
// File  : XMLtest.cpp
// Desc  : Test case for XML parsing of scenario file
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          pie
//-----------------------------------------------------------------------------
#include "XMLParse.h"
#include "TestCaseInfo.h"

int
main(int argc,char *argv[])
{
	if(!argc||1==argc){
    cerr<<"Missing scenario file..."<<endl;
    return(1);
  }
  
  XMLParse *pXML=0;
  
  pXML = new XMLParse( argv[1] );
  cout << "Parsing of XML is Start" << endl;
  bool XMLSuccessed = pXML->ParseXMLFile();
  if(true==XMLSuccessed){
    cout << "Parsing of XML is Successed" << endl;
  }else{
    cout << "Parsing of XML is Failed" << endl;
  }
  delete pXML;
  pXML = NULL;
  return(0);
}
