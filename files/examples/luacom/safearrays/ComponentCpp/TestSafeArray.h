

/* this ALWAYS GENERATED file contains the definitions for the interfaces */


 /* File created by MIDL compiler version 6.00.0361 */
/* at Thu Jan 03 19:24:16 2008
 */
/* Compiler settings for D:\Desarrollo\TestSafeArray\TestSafeArray.idl:
    Oicf, W1, Zp8, env=Win32 (32b run)
    protocol : dce , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
//@@MIDL_FILE_HEADING(  )

#pragma warning( disable: 4049 )  /* more than 64k source lines */


/* verify that the <rpcndr.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCNDR_H_VERSION__
#define __REQUIRED_RPCNDR_H_VERSION__ 475
#endif

#include "rpc.h"
#include "rpcndr.h"

#ifndef __RPCNDR_H_VERSION__
#error this stub requires an updated version of <rpcndr.h>
#endif // __RPCNDR_H_VERSION__

#ifndef COM_NO_WINDOWS_H
#include "windows.h"
#include "ole2.h"
#endif /*COM_NO_WINDOWS_H*/

#ifndef __TestSafeArray_h__
#define __TestSafeArray_h__

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
#pragma once
#endif

/* Forward Declarations */ 

#ifndef __ITest_FWD_DEFINED__
#define __ITest_FWD_DEFINED__
typedef interface ITest ITest;
#endif 	/* __ITest_FWD_DEFINED__ */


#ifndef __Test_FWD_DEFINED__
#define __Test_FWD_DEFINED__

#ifdef __cplusplus
typedef class Test Test;
#else
typedef struct Test Test;
#endif /* __cplusplus */

#endif 	/* __Test_FWD_DEFINED__ */


/* header files for imported files */
#include "oaidl.h"
#include "ocidl.h"

#ifdef __cplusplus
extern "C"{
#endif 

void * __RPC_USER MIDL_user_allocate(size_t);
void __RPC_USER MIDL_user_free( void * ); 

#ifndef __ITest_INTERFACE_DEFINED__
#define __ITest_INTERFACE_DEFINED__

/* interface ITest */
/* [unique][helpstring][dual][uuid][object] */ 


EXTERN_C const IID IID_ITest;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("353BD90E-14BD-47A8-AEB7-99C05C37E084")
    ITest : public IDispatch
    {
    public:
        virtual /* [helpstring][id] */ HRESULT STDMETHODCALLTYPE GetArray( 
            /* [retval][out] */ SAFEARRAY * *array) = 0;
        
        virtual /* [helpstring][id] */ HRESULT STDMETHODCALLTYPE SetArray( 
            /* [out][in] */ SAFEARRAY * *array) = 0;
        
        virtual /* [helpstring][id] */ HRESULT STDMETHODCALLTYPE GetArray432( 
            /* [retval][out] */ SAFEARRAY * *array) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct ITestVtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            ITest * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            ITest * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            ITest * This);
        
        HRESULT ( STDMETHODCALLTYPE *GetTypeInfoCount )( 
            ITest * This,
            /* [out] */ UINT *pctinfo);
        
        HRESULT ( STDMETHODCALLTYPE *GetTypeInfo )( 
            ITest * This,
            /* [in] */ UINT iTInfo,
            /* [in] */ LCID lcid,
            /* [out] */ ITypeInfo **ppTInfo);
        
        HRESULT ( STDMETHODCALLTYPE *GetIDsOfNames )( 
            ITest * This,
            /* [in] */ REFIID riid,
            /* [size_is][in] */ LPOLESTR *rgszNames,
            /* [in] */ UINT cNames,
            /* [in] */ LCID lcid,
            /* [size_is][out] */ DISPID *rgDispId);
        
        /* [local] */ HRESULT ( STDMETHODCALLTYPE *Invoke )( 
            ITest * This,
            /* [in] */ DISPID dispIdMember,
            /* [in] */ REFIID riid,
            /* [in] */ LCID lcid,
            /* [in] */ WORD wFlags,
            /* [out][in] */ DISPPARAMS *pDispParams,
            /* [out] */ VARIANT *pVarResult,
            /* [out] */ EXCEPINFO *pExcepInfo,
            /* [out] */ UINT *puArgErr);
        
        /* [helpstring][id] */ HRESULT ( STDMETHODCALLTYPE *GetArray )( 
            ITest * This,
            /* [retval][out] */ SAFEARRAY * *array);
        
        /* [helpstring][id] */ HRESULT ( STDMETHODCALLTYPE *SetArray )( 
            ITest * This,
            /* [out][in] */ SAFEARRAY * *array);
        
        /* [helpstring][id] */ HRESULT ( STDMETHODCALLTYPE *GetArray432 )( 
            ITest * This,
            /* [retval][out] */ SAFEARRAY * *array);
        
        END_INTERFACE
    } ITestVtbl;

    interface ITest
    {
        CONST_VTBL struct ITestVtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define ITest_QueryInterface(This,riid,ppvObject)	\
    (This)->lpVtbl -> QueryInterface(This,riid,ppvObject)

#define ITest_AddRef(This)	\
    (This)->lpVtbl -> AddRef(This)

#define ITest_Release(This)	\
    (This)->lpVtbl -> Release(This)


#define ITest_GetTypeInfoCount(This,pctinfo)	\
    (This)->lpVtbl -> GetTypeInfoCount(This,pctinfo)

#define ITest_GetTypeInfo(This,iTInfo,lcid,ppTInfo)	\
    (This)->lpVtbl -> GetTypeInfo(This,iTInfo,lcid,ppTInfo)

#define ITest_GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)	\
    (This)->lpVtbl -> GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)

#define ITest_Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)	\
    (This)->lpVtbl -> Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)


#define ITest_GetArray(This,array)	\
    (This)->lpVtbl -> GetArray(This,array)

#define ITest_SetArray(This,array)	\
    (This)->lpVtbl -> SetArray(This,array)

#define ITest_GetArray432(This,array)	\
    (This)->lpVtbl -> GetArray432(This,array)

#endif /* COBJMACROS */


#endif 	/* C style interface */



/* [helpstring][id] */ HRESULT STDMETHODCALLTYPE ITest_GetArray_Proxy( 
    ITest * This,
    /* [retval][out] */ SAFEARRAY * *array);


void __RPC_STUB ITest_GetArray_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


/* [helpstring][id] */ HRESULT STDMETHODCALLTYPE ITest_SetArray_Proxy( 
    ITest * This,
    /* [out][in] */ SAFEARRAY * *array);


void __RPC_STUB ITest_SetArray_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


/* [helpstring][id] */ HRESULT STDMETHODCALLTYPE ITest_GetArray432_Proxy( 
    ITest * This,
    /* [retval][out] */ SAFEARRAY * *array);


void __RPC_STUB ITest_GetArray432_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __ITest_INTERFACE_DEFINED__ */



#ifndef __TESTSAFEARRAYLib_LIBRARY_DEFINED__
#define __TESTSAFEARRAYLib_LIBRARY_DEFINED__

/* library TESTSAFEARRAYLib */
/* [helpstring][version][uuid] */ 


EXTERN_C const IID LIBID_TESTSAFEARRAYLib;

EXTERN_C const CLSID CLSID_Test;

#ifdef __cplusplus

class DECLSPEC_UUID("EC6D6D8D-2D13-4759-92D8-538DFE1CDAAA")
Test;
#endif
#endif /* __TESTSAFEARRAYLib_LIBRARY_DEFINED__ */

/* Additional Prototypes for ALL interfaces */

unsigned long             __RPC_USER  LPSAFEARRAY_UserSize(     unsigned long *, unsigned long            , LPSAFEARRAY * ); 
unsigned char * __RPC_USER  LPSAFEARRAY_UserMarshal(  unsigned long *, unsigned char *, LPSAFEARRAY * ); 
unsigned char * __RPC_USER  LPSAFEARRAY_UserUnmarshal(unsigned long *, unsigned char *, LPSAFEARRAY * ); 
void                      __RPC_USER  LPSAFEARRAY_UserFree(     unsigned long *, LPSAFEARRAY * ); 

/* end of Additional Prototypes */

#ifdef __cplusplus
}
#endif

#endif


