// Test.h : Declaration of the CTest

#ifndef __TEST_H_
#define __TEST_H_

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CTest
class ATL_NO_VTABLE CTest : 
	public CComObjectRootEx<CComSingleThreadModel>,
	public CComCoClass<CTest, &CLSID_Test>,
	public IDispatchImpl<ITest, &IID_ITest, &LIBID_TESTSAFEARRAYLib>
{
public:
	CTest()
	{
	}

DECLARE_REGISTRY_RESOURCEID(IDR_TEST)

DECLARE_PROTECT_FINAL_CONSTRUCT()

BEGIN_COM_MAP(CTest)
	COM_INTERFACE_ENTRY(ITest)
	COM_INTERFACE_ENTRY(IDispatch)
END_COM_MAP()

// ITest
public:
	STDMETHOD(GetArray)(SAFEARRAY**);
	STDMETHOD(SetArray)(SAFEARRAY**);
	STDMETHOD(GetArray432)(SAFEARRAY**);
};

#endif //__TEST_H_
