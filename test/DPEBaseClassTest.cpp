// -*-c++-*-
//----------------------------------------------------------------------------
// File : DPEBaseClassTest.cpp
// Desc : Source file to generate DPE test case.
// Usage: 
//----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                    user
// 10-06-2003  Cre                                                         sjm
// 10-07-2003  Modify and add proper comments				   sjm
//----------------------------------------------------------------------------
#include "DPEBaseClass.h"
#include "EPConfigFactoryMain.h"
#include "BaseDataObj.h"
#include "ErgoplanDOImpl.h"

//
//myClass derived from DPEBaseClass
//Has only one method InvokeTestCase where user can
//write test case
//
class myClass: public DPEBaseClass
{
public:
    /**
     * Function to write the test case.
     * @param
     * @return
     *     HRESULT value
     * <br><b>Legal values</b>
     * <ul>
     * <li>S_OK if the operation succeeds</li>
     * <li>E_FAIL otherwise</li>
     * </ul>
     */
    HRESULT InvokeTestCase();

};

//----------------------------------------------------------------------------
// InvokeTestCase
//     User written test case
//----------------------------------------------------------------------------
HRESULT
myClass::InvokeTestCase()
{
    IEPIPDClient* pIPDClient = GetIPDClient();
    long lClientId = GetClientId();

    //User written TESTCASE.
    // Retrieve project root from server
    IEP_BaseDataObject *pProjectRoot = GetProjectRoot();
    
    // Retrieve archive root (library) from server
    IEP_BaseDataObject *pArchivRoot = GetArchivRoot();

    // Get project by name 'Temperature Sensor AF20'
    IEP_BaseDataObject *pProjectByName = NULL; 
    HRESULT hRes = GetProject( "Temperature Sensor AF20", 
				&pProjectByName );
    if( !PrintSuccess( hRes, "Retrieved project Temperature Sensor AF20" ))
    {
	return( hRes ); 
    }

    // Retrieve system element root from server
    CComPtr<IEP_BaseDataObject> pSERoot;
    hRes = pIPDClient->GetServerCOMObject( lClientId,
                                           __uuidof(DoSystemsElementRoot), 
                                           __uuidof(IEP_BaseDataObject),
				           (void **) &pSERoot);
    if( !PrintSuccess(hRes,"GetServerCOMObject (SystemElementRoot)"))
    {
	return( hRes );
    }

    // Print out object information
    PrintBDObjectInfo(pProjectRoot,_T("DOProjectRoot"));
    PrintBDObjectInfo(pArchivRoot,_T("DOArchivRoot"));
    PrintBDObjectInfo(pSERoot,_T("DoSystemsElementRoot"));

    return( hRes );
}


//
//Call MAIN macro, it has main() defined
//
MAIN( myClass)
