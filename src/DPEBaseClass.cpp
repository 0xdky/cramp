// -*-c++-*-
//----------------------------------------------------------------------------
// File : DPEBaseClass.cpp
// Desc : Implementation of DPEBaseClass
// Usage:
//----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                    user
// 10-06-2003  Cre                                                         sjm
// 10-07-2003  Modify and add proper comments				               sjm
//----------------------------------------------------------------------------
#define __DPEBASECLASS_SRC

#include "DPEBaseClass.h"

//----------------------------------------------------------------------------
// DPEBaseClass
//----------------------------------------------------------------------------
DPEBaseClass::DPEBaseClass()
{
  //_asm {int 3};
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
  pProjectRoot = NULL;
  pArchivRoot = NULL;
  pSimpleQuery = NULL;
  pConfigFactoryCache = NULL;
  pConfigFactory = NULL;
  //Unregister from IPDClient
  hRes = pIPDClient->UnregisterClientId( lClientId );
  RetVal = PrintSuccess( hRes, "\nUnregisterClientId" );
  pIPDClient = NULL;
  CoUninitialize();
  cout<<"Connection Closed!!\n";
}

//----------------------------------------------------------------------------
// Connect
//   Connect to server
//   Throws an exception if any problem is occured while establishing
//   connection.
//----------------------------------------------------------------------------
void
DPEBaseClass::Connect()
{
  USES_CONVERSION;

  //
  // Initialise security
  //
  hRes = CoInitializeSecurity( NULL, -1, NULL, NULL,
                               RPC_C_AUTHN_LEVEL_CONNECT,
                               RPC_C_IMP_LEVEL_IMPERSONATE,
                               NULL, EOAC_NONE, NULL );

  if(!PrintSuccess( hRes, "CoInitializeSecurity" ))
  {
    throw ServerNotInitialised();
  }

  //
  // Create IPDClient object
  //
  pIPDClient = NULL;
  hRes = CoCreateInstance( __uuidof(EPIPDClient), // Class ID
                           NULL, CLSCTX_ALL,	    // INPROC_SERVER,
                           __uuidof(IEPIPDClient), // Interface ID (RefIID)
                           (void **) &pIPDClient ); // Interface pointer address

  if(!PrintSuccess( hRes,"Creation of IPDClient" ))
  {
    throw ServerNotInitialised();
  }

  //
  // Set login data
  //
  hRes = pIPDClient->SetLoginInfo( CComBSTR( L"admin" ),  //Username
                                   CComBSTR( L"admin" )); //Password
  RetVal = PrintSuccess( hRes, "SetLoginInfo of IPDClient" );

  //
  // Retrieve client ID from IPDClient
  //
  hRes = pIPDClient->GetNewClientId( &lClientId );
  if(!PrintSuccess( hRes, "GetNewClientId of IPDClient" ))
  {
    throw ServerNotInitialised();
  }

  //
  // Set project root
  //
  pProjectRoot = NULL;
  hRes = pIPDClient->GetServerCOMObject( lClientId,
                                         __uuidof(DOProjectRoot),
                                         __uuidof(IEP_BaseDataObject),
                                         (void **) &pProjectRoot );
  if(!PrintSuccess( hRes, "Retrieved Project Root" ))
  {
    throw ServerNotInitialised();
  }

  //
  // Set archiv root
  //
  pArchivRoot = NULL;
  hRes = pIPDClient->GetServerCOMObject( lClientId,
                                         __uuidof(DOArchivRoot),
                                         __uuidof(IEP_BaseDataObject),
                                         (void **) &pArchivRoot );
  if(!PrintSuccess( hRes,"Retrieved Archiv Root" ))
  {
    throw ServerNotInitialised();
  }

  //
  // Get query machine
  //
  hRes = pIPDClient->GetServerCOMObject( lClientId,
                                         __uuidof(EP_QueryMachine),
                                         __uuidof(IEP_SimpleQuery),
                                         (void **) &pSimpleQuery );
  if(!PrintSuccess( hRes,"Get Simple Query" ))
  {
    throw ServerNotInitialised();
  }

  //
  // Get configfactory cache
  //
  IUnknown *pUnk = NULL;
  // Get EPConfigFactoryCache
  pIPDClient->GetConfigFactoryCache( &pUnk );
  pUnk->QueryInterface( __uuidof( IEPConfigFactoryCache ),
                        (void**) & pConfigFactoryCache );

  //
  // Get configFactory
  //
  pConfigFactoryCache->GetRealConfigFactory( &pConfigFactory );
}

//----------------------------------------------------------------------------
// GetIPDClient
//   Returns IPDClient object
//----------------------------------------------------------------------------
IEPIPDClient
*DPEBaseClass::GetIPDClient()
{
  return( pIPDClient );
}

//----------------------------------------------------------------------------
// GetClientId
//    Returns the client ID
//----------------------------------------------------------------------------
long
DPEBaseClass::GetClientId()
{
  return( lClientId );
}

//----------------------------------------------------------------------------
// GetProjectRoot
//   Returns project root
//----------------------------------------------------------------------------
IEP_BaseDataObject
*DPEBaseClass::GetProjectRoot()
{
  return pProjectRoot;
}

//----------------------------------------------------------------------------
// GetArchivRoot
//   Returns archiv root
//----------------------------------------------------------------------------
IEP_BaseDataObject
*DPEBaseClass::GetArchivRoot()
{
  return pArchivRoot;
}
//----------------------------------------------------------------------------
// GetConfigFactoryCache
//   Returns config factory cache
//----------------------------------------------------------------------------
IEPConfigFactoryCache
*DPEBaseClass::GetConfigFactoryCache()
{
  return pConfigFactoryCache;
}

//----------------------------------------------------------------------------
// PrintSuccess
//   Prints the status with
//----------------------------------------------------------------------------
int
DPEBaseClass::PrintSuccess( HRESULT hRes, const TCHAR* pAction )
{
  USES_CONVERSION;
  if( pAction )
  {
    if( SUCCEEDED(hRes) )		// Action has either...
      cout << pAction << " succeeded." << endl;
	else
      cout << pAction << " failed." << endl;
  }
  return( SUCCEEDED(hRes) );
}

//----------------------------------------------------------------------------
// PrintBDObjectInfo
//   Print object info
//----------------------------------------------------------------------------
void
DPEBaseClass::PrintBDObjectInfo( IEP_BaseDataObject *pBDO,
                                 const TCHAR *pszName )
{
  USES_CONVERSION;

  if( pszName == NULL )
    return;

  BSTR bstrType;
  // Ask object for type name
  HRESULT hRes = pBDO->GetTableName( &bstrType );
  cout << "\nType of object \"" << pszName <<"\": " << W2CA( bstrType )
       << endl;

  CComVariant varName;
  // Ask object for attribute "name"
  hRes = pBDO->GetAttribute( CComBSTR(L"name"), &varName );
  cout << "Attribut \"name\" of object \"" << pszName << "\": "
       << W2CA( varName.bstrVal ) << "\n" << endl;
}

//----------------------------------------------------------------------------
// GetProject
//     Returns existing project by its name
//----------------------------------------------------------------------------
HRESULT
DPEBaseClass::GetProject( CComBSTR bstrProjectName,
                          IEP_BaseDataObject **pErgoProject )
{
  HRESULT hRes = S_OK;
  //
  // Get children encapsulated in pProjectEnum
  //
  IEnumBaseDataObject *pProjectEnum = NULL;
  hRes = pProjectRoot->GetChildren( CComBSTR(L"ergoproject"),
                                    &pProjectEnum );
  if( hRes != S_OK )
  {
    return ( hRes );
  }

  CComPtr<IEP_BaseDataObject> pProject;
  unsigned long ulFetched = 0;
  while( S_OK == pProjectEnum->Next( 1, &pProject, &ulFetched ))
  {
	CComVariant varName;
	hRes = pProject->GetAttribute( CComBSTR(L"name"), &varName );
	if( hRes != S_OK )
	{
      return ( hRes );
	}

	if( CComBSTR( bstrProjectName ) == CComBSTR( varName.bstrVal ))
	{
      *pErgoProject = pProject.Detach();
      pProjectEnum->Release();
      pProjectEnum = NULL;
      return ( hRes );
	}
	pProject = NULL;
  }
  pProjectEnum->Release();
  pProjectEnum = NULL;
  return ( E_FAIL );
}
