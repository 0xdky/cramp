// -*-c++-*-
//----------------------------------------------------------------------------
// File : DPEBaseClass.h
// Desc : Header file defining the base class for all DPE test cases
// Usage: Include this header file and derive all test cases from the base
//        class. Link with the DPEBaseClass.obj
//----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                    user
// 10-06-2003  Cre                                                         sjm
//----------------------------------------------------------------------------
#pragma once
// has to be defined for using COM
#define _WIN32_WINNT 0x0500

#include <Windows.h>
#include <OAIdl.h>
#include <ATLBASE.h>

#include <iostream.h>
#include "EPIPDClient.h"
#include "BaseDataObj.h"
// #include "ErgoplanDOImpl.h"

//
//Defination of MAIN macro
//has main() defined inside
//
#define MAIN(DerClass) \
	int main() \
{ \
    USES_CONVERSION;  \
    DerClass *TCObject = NULL;\
    try\
    {\
	TCObject = new DerClass();\
    }\
    catch( ServerNotInitialised )\
    {\
	return( -1 );\
    }\
    cout<<"\nConnection Established!!\n";\
    cout<<"\nInvoking TestCase...\n";\
    TCObject->InvokeTestCase();\
    cout<<"\nTestCase Complete.\nClosing connection to IPDServer...\n";\
    delete TCObject;\
    TCObject = NULL; \
    return( 0 );\
}

//
//Exception Class
//
class ServerNotInitialised
{
    public:
	ServerNotInitialised()
	{
	    cout<<"\nError: Server Not Initialised\n";
	}
};

//
//Base Class
//
class DPEBaseClass
{
    private:
	CComPtr<IEPIPDClient> pIPDClient;
        CComPtr<IEP_BaseDataObject> pProjectRoot; 
	long lClientId;
	HRESULT hRes;
	int RetVal;
	void Connect();

    public:
	DPEBaseClass();
	~DPEBaseClass();
	int PrintSuccess( HRESULT hRes, const TCHAR* pAction );
	void PrintBDObjectInfo(IEP_BaseDataObject *pBDO, const TCHAR *pszName);
	IEPIPDClient* GetIPDClient();
	long GetClientId();
	IEP_BaseDataObject* GetProjectRoot();
};
