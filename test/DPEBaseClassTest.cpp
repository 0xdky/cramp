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
	void InvokeTestCase();

};

void myClass::InvokeTestCase()
{
    IEPIPDClient* pIPDClient = GetIPDClient();
    long lClientId = GetClientId();

    //User written TESTCASE.
    // Retrieve project root from server
    IEP_BaseDataObject* pProjectRoot = GetProjectRoot();
    
    // Retrieve archive root (library) from server
    CComPtr<IEP_BaseDataObject> pArchivRoot;
    HRESULT hRes = pIPDClient->GetServerCOMObject( lClientId,
                                           __uuidof(DOArchivRoot), 
                                           __uuidof(IEP_BaseDataObject),
				           (void **) &pArchivRoot);
    PrintSuccess(hRes,"GetServerCOMObject (ArchivRoot)");

    // Retrieve system element root from server
    CComPtr<IEP_BaseDataObject> pSERoot;
    hRes = pIPDClient->GetServerCOMObject( lClientId,
                                           __uuidof(DoSystemsElementRoot), 
                                           __uuidof(IEP_BaseDataObject),
				           (void **) &pSERoot);
    PrintSuccess(hRes,"GetServerCOMObject (SystemElementRoot)");

    // Print out object information
    PrintBDObjectInfo(pProjectRoot,_T("DOProjectRoot"));
    PrintBDObjectInfo(pArchivRoot,_T("DOArchivRoot"));
    PrintBDObjectInfo(pSERoot,_T("DoSystemsElementRoot"));
}


//
//Call MAIN macro, it has main() defined
//
MAIN( myClass)
