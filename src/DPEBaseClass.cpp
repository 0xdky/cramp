#include "DPEBaseClass.h"
#include <objbase.h>
#include <atlbase.h>
#include <atlconv.h>
#include <iostream.h>

#include "ErgoPlanDOImpl.h"

//
//Returns IPDClient object
//
IEPIPDClient
*DPEBaseClass::GetIPDClient()
{
    return( pIPDClient );
}

//
//Returns the Client ID
//
long DPEBaseClass::GetClientId()
{
    return( lClientId );
}

//
//Returns Project Root
//
IEP_BaseDataObject* DPEBaseClass::GetProjectRoot()
{
    pProjectRoot = NULL;
    hRes = pIPDClient->GetServerCOMObject( lClientId,
					    __uuidof(DOProjectRoot), 
					    __uuidof(IEP_BaseDataObject),
					    (void **) &pProjectRoot);
    PrintSuccess(hRes,"GetServerCOMObject (ProjectRoot)");
    return( pProjectRoot );
}
    

//
//Connect to server
//
void 
DPEBaseClass::Connect()
{
    USES_CONVERSION;
    
    //
    //Initialise Security
    //
    hRes = CoInitializeSecurity(NULL, -1, NULL, NULL,
			        RPC_C_AUTHN_LEVEL_CONNECT, 
			        RPC_C_IMP_LEVEL_IMPERSONATE, 
			        NULL, EOAC_NONE, NULL);
        
    if(!PrintSuccess (hRes,"CoInitializeSecurity")) 
    {
        throw ServerNotInitialised();
    }
    
    //
    //Create IPDClient object
    //
    pIPDClient = NULL;
    hRes = CoCreateInstance( __uuidof(EPIPDClient), // Class ID
			    NULL, CLSCTX_ALL,	    // INPROC_SERVER, 
			    __uuidof(IEPIPDClient), // Interface ID (RefIID)
			    (void **) &pIPDClient); // Interface pointer address
	
    if(!PrintSuccess (hRes,"Creation of IPDClient")) 
    {
        throw ServerNotInitialised();
    }

    //
    //Set Login Data
    //
    hRes = pIPDClient->SetLoginInfo( CComBSTR(L"admin"), //Username
    	    CComBSTR(L"admin") ); //Password
    RetVal = PrintSuccess (hRes,"SetLoginInfo of IPDClient"); 

    //
    //Retrieve client ID from IPDClient
    //
    hRes = pIPDClient->GetNewClientId( &lClientId );
    if(!PrintSuccess (hRes,"GetNewClientId of IPDClient")) 
    {
        throw ServerNotInitialised();
    } 
}

DPEBaseClass::DPEBaseClass()
{
    USES_CONVERSION; 
    cout<<"\nEstablishing Connection to IPDServer via local IPDClient...\n\n";

    if(SUCCEEDED(CoInitializeEx(NULL, COINIT_MULTITHREADED)))
    {
	Connect();
    } 
    else
    {
        throw ServerNotInitialised();
    }
}

//----------------------------------------------------------------------------
// ~DPEBaseClass
//----------------------------------------------------------------------------
DPEBaseClass::~DPEBaseClass()
{
    USES_CONVERSION; 
    //Unregister from IPDClient
    hRes = pIPDClient->UnregisterClientId( lClientId );
    RetVal = PrintSuccess( hRes, "\nUnregisterClientId" );
    CoUninitialize(); 
    cout<<"Connection Closed!!\n";
}

//
//Prints the status with 
//
int DPEBaseClass::PrintSuccess(HRESULT hRes, const TCHAR* pAction)
{
    USES_CONVERSION; 
    if(pAction)
    {
    	if (SUCCEEDED(hRes))		// Action has either...
	    cout << pAction << " succeeded." << endl;
	else 
	    cout << pAction << " failed." << endl;	
    }
    return( SUCCEEDED(hRes) ); 
}

//
//Print object info
//
void DPEBaseClass::PrintBDObjectInfo(IEP_BaseDataObject *pBDO, 
				    const TCHAR *pszName) 
{
    USES_CONVERSION;

    if(pszName == NULL)	
    	return;

    BSTR bstrType;
    HRESULT hRes = pBDO->GetTableName(&bstrType);	
					// ask object for type name
    cout << "\nType of object \"" << pszName <<"\": " << W2CA(bstrType) 
         << endl;

    CComVariant varName;

    hRes = pBDO->GetAttribute( CComBSTR(L"name"), &varName);	
				// ask object for attribute "name"
    cout << "Attribut \"name\" of object \"" << pszName << "\": " 
		    << W2CA(varName.bstrVal) << "\n" << endl;
}
