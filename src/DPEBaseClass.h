// -*-c++-*-
//----------------------------------------------------------------------------
// File : DPEBaseClass.h
// Desc : Header file defining the base class for all DPE test cases
// Usage: Include this header file and derive all test cases from the base
//        class. Link with the DPEBaseClass.obj
//----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                    user
// 10-06-2003  Cre                                                         sjm
// 10-07-2003  Modify and add proper comments				   sjm
//----------------------------------------------------------------------------
#pragma once
// has to be defined for using COM
#define _WIN32_WINNT 0x0500

#include <Windows.h>
#include <OAIdl.h>
#include <ATLBASE.h>
#include <objbase.h>
#include <atlbase.h>
#include <atlconv.h>
#include <iostream.h>

#include "basedataobj.h"
#include "EPIPDClient.h"
#include "IPDClient.h"
#include "ErgoplanDOImpl.h"
#include "objectquery.h"
#include "configfactory.h"
#include "configfactorycache.h"
#include "epconfigfactorymain.h"

/**
 *
 * <b>Role</b>: Defines main() function inside.
 * Use this macro in source file to generate individual test case.
 * If connection to Server is established then an object is created
 * for DerClass and InvokeTestCase method is called. 
 * @param DerClass
 *     Class name to create the object.
 */
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
    HRESULT hRes = TCObject->InvokeTestCase();\
    if( hRes == S_OK )\
    {\
	cout<<"\nTestCase Complete.";\
    }\
    else\
    {\
	cout<<"\nTestCase Incomplete.";\
    }\
    cout<<"\nClosing connection to IPDServer...\n";\
    delete TCObject;\
    TCObject = NULL; \
    return( hRes );\
}

//----------------------------------------------------------------------------
// Exception class  
//----------------------------------------------------------------------------
class ServerNotInitialised
{
public:
    ServerNotInitialised()
    {
	cout<<"\nError: Server Not Initialised\n";
    }
};

/**
 * Base class for every DPE test case.
 * <b>Role</b>: To establish connection with DPE server at the start of each
 * test case and disconnect it at the end. 
 * <p>
 * If the connection with server is not established it throws an exception.
 * It provides methods to retrieve IPDClient, project root, archiv root, 
 * simple query, config factory cache, config factory and clientid. 
 */ 
class DPEBaseClass
{
public:
    /**
     * Constructor
     */ 
    DPEBaseClass();
    
    /**
     * Destructor
     */ 
    ~DPEBaseClass();
    
    /**
     * Function to check HRESULT on S_*** and write result on console.
     * @param hRes
     *     HRESULT value to check
     * @param pAction
     *     String holding name of action for diagnostics 
     *     or NULL for suppressing diagnostic message
     * @ return
     *     int SUCCEEDED( hRes )
     */ 
    int PrintSuccess( HRESULT hRes, const TCHAR* pAction );
    
    /**
     * Function to print type and name of a BaseDataObject to console.
     * @param pBDO
     *     Pointer to IEP_BaseDataObject interface
     * @param pszName
     *     String holding the class name of the object
     * @return
     */ 
    void PrintBDObjectInfo(IEP_BaseDataObject *pBDO, const TCHAR *pszName);
    
    /**
     * Function to return IPDClient pointer
     * @param
     * @return IEPIPDClient
     *     Pointer to IPDClient
     */
    IEPIPDClient *GetIPDClient();
    
    /**
     * Function to return ClientId
     * @param
     * @return long
     *     ClientId
     */     
    long GetClientId();
    
    /**
     * Function to return project root
     * @param
     * @return IEP_BaseDataObject
     *     Pointer to IEP_BaseDataObject
     */
    IEP_BaseDataObject *GetProjectRoot();
    
    /**
     * Function to return archiv root
     * @param
     * @return IEP_BaseDataObject
     *     Pointer to IEP_BaseDataObject
     */
    IEP_BaseDataObject *GetArchivRoot();
    
    /**
     * Function to return config factory cache 
     * @param
     * @return IEPConfigFactoryCache
     *     Pointer to IEPConfigFactoryCache 
     */
    IEPConfigFactoryCache *GetConfigFactoryCache();
    
    /**
     * Function to return config factory
     * @param
     * @return IEPConfigFactory 
     *     Pointer to IEPConfigFactory
     */
    IEPConfigFactory *GetConfigFactory();

    /**
     * Function to return existing project by its name
     * @param bstrProjectName
     *     Name of the project 
     * @param pErgoProject
     *     Handle to IEP_BaseDataObject interface
     * @return 
     *     HRESULT value
     * <br><b>Legal values</b>
     * <ul>
     * <li>S_OK if the operation succeeds</li>
     * <li>E_FAIL otherwise</li>
     * </ul>
     */
    HRESULT GetProject( CComBSTR bstrProjectName, 
		        IEP_BaseDataObject **pErgoProject );

private:
    CComPtr<IEPIPDClient> pIPDClient;
    CComPtr<IEP_BaseDataObject> pProjectRoot;
    CComPtr<IEP_BaseDataObject> pArchivRoot;
    CComPtr<IEP_SimpleQuery> pSimpleQuery;
    CComPtr<IEPConfigFactoryCache> pConfigFactoryCache;
    CComPtr<IEPConfigFactory> pConfigFactory;
    long lClientId;
    HRESULT hRes;
    int RetVal;
    void Connect();
};
