// Test.cpp : Implementation of CTest
#include "stdafx.h"
#include "TestSafeArray.h"
#include "Test.h"
#include <stdio.h>

/////////////////////////////////////////////////////////////////////////////
// CTest


//////////////////////////////////////////////////////////////////////////
/// Returns a matrix with dimensions [2][3]
STDMETHODIMP CTest::GetArray(SAFEARRAY** a) {
	SAFEARRAYBOUND bounds[2] = { {2, 0}, {3, 0}};
	
	SAFEARRAY* array = SafeArrayCreate(VT_BSTR, 2, bounds);

	long indices[2];
	
	indices[0] = 0;
	
	indices[1] = 0; SafeArrayPutElement(array, indices, CComBSTR(L"A"));
	indices[1] = 1; SafeArrayPutElement(array, indices, CComBSTR(L"B"));
	indices[1] = 2; SafeArrayPutElement(array, indices, CComBSTR(L"C"));

	indices[0] = 1;

	indices[1] = 0; SafeArrayPutElement(array, indices, CComBSTR(L"D"));
	indices[1] = 1; SafeArrayPutElement(array, indices, CComBSTR(L"E"));
	indices[1] = 2; SafeArrayPutElement(array, indices, CComBSTR(L"F"));

	*a = array;

	return S_OK;
}

//////////////////////////////////////////////////////////////////////////
/// Returns a cube with dimensions [4][3][2]
STDMETHODIMP CTest::GetArray432(SAFEARRAY** a) {
	SAFEARRAYBOUND bounds[3] = { {4,0}, {3,0}, {2,0} };
	
	SAFEARRAY* array = SafeArrayCreate(VT_BSTR, 3, bounds);

	long indices[3];

	for(int i = 0; i < 4; i++) {
		for(int j = 0; j < 3; j++) {
			for(int k = 0; k < 2; k++) {
				char buffer[10];
				sprintf(buffer, "[%d,%d,%d]", i, j, k);
				indices[0] = i;
				indices[1] = j;
				indices[2] = k;

				SafeArrayPutElement(array, indices, CComBSTR(buffer));
			}
		}
	}

	*a = array;
	return S_OK;
}

/*void PrintSubDimension(SAFEARRAY* array, UINT index, UINT subDimension) {
	char buffer[1024];
	HRESULT hr;

	long* indices = new long[SafeArrayGetDim(array)];

	long lBound, uBound;
	hr = SafeArrayGetLBound(array, subDimension, &lBound);
	hr = SafeArrayGetUBound(array, subDimension, &uBound);
	sprintf(buffer, "SubDimension %d => [%d to %d]\r\n", subDimension, lBound, uBound);
	printf("%s", buffer);
	OutputDebugString(buffer);
	for(long i = lBound; i <= uBound; i++) {
		BSTR valor;
		indices[0] = index;
		indices[1] = i;
		hr = SafeArrayGetElement(array, indices, &valor);
		ATLASSERT(SUCCEEDED(hr));
		sprintf(buffer, "[%d, %d]=%S\t", index, i, valor);
		printf("%s", buffer);
		OutputDebugString(buffer);
		SysFreeString(valor);
	}
	delete[] indices;
}

//////////////////////////////////////////////////////////////////////////
/// 
void PrintFirstDimension(SAFEARRAY* array, UINT dimension) {
	char buffer[1024];

	HRESULT hr;
	long lBound, uBound;
	hr = SafeArrayGetLBound(array, dimension, &lBound);
	hr = SafeArrayGetUBound(array, dimension, &uBound);
	sprintf(buffer, "Dimension %d => [%d to %d]\r\n", dimension, lBound, uBound);
	printf("%s", buffer);
	OutputDebugString(buffer);
	
	for(long i = lBound; i <= uBound; i++) {
		sprintf(buffer, "Dimension %d => Indice=%d\r\n", dimension, i);
		printf("%s", buffer);
		OutputDebugString(buffer);
		PrintSubDimension(array, i, dimension + 1);
		printf("\r\n");
		OutputDebugString("\r\n");
	}
}*/

//////////////////////////////////////////////////////////////////////////
/// 
bool inc_indices(long* indices, SAFEARRAYBOUND* bounds, unsigned long dimensions) {
	long j = dimensions - 1;
	
	indices[j]++;
	
	while(
		(indices[j] >= (long) bounds[j].cElements + bounds[j].lLbound) &&
		(j >= 0)
		)
	{
		indices[j] = bounds[j].lLbound;
		indices[j - 1]++;
		j--;
		if(j == 0 && indices[j] >= (long) bounds[j].cElements + bounds[j].lLbound) {
			return false;
		}
	}
	return true;
}

//////////////////////////////////////////////////////////////////////////
/// Inverts an array of SAFEARRAYBOUNDS (inplace)
static void InvertArrayBounds(SAFEARRAYBOUND* arrayBounds, UINT dimensions) {
	for(UINT dimension = 0; dimension < (dimensions / 2); dimension++) {
		LONG lbound = arrayBounds[dimension].lLbound;
		LONG elements = arrayBounds[dimension].cElements;

		arrayBounds[dimension].lLbound = arrayBounds[dimensions - 1 - dimension].lLbound;
		arrayBounds[dimension].cElements = arrayBounds[dimensions - 1 - dimension].cElements;
		arrayBounds[dimensions - 1 - dimension].lLbound = lbound;
		arrayBounds[dimensions - 1 - dimension].cElements = elements;
	}	
}

//////////////////////////////////////////////////////////////////////////
/// 
STDMETHODIMP CTest::SetArray(SAFEARRAY** arr) {
	char buffer[1024];
	SAFEARRAY* miArray = *arr;
	SAFEARRAYBOUND* rgsabounds = miArray->rgsabound;

	/*CBString features;
	if(miArray->fFeatures & FADF_AUTO) {
		features += "FADF_AUTO ";
	}
	if(miArray->fFeatures & FADF_STATIC) {
		features += "FADF_STATIC ";
	}
	if(miArray->fFeatures & FADF_EMBEDDED) {
		features += "FADF_EMBEDDED ";
	}
	if(miArray->fFeatures & FADF_FIXEDSIZE) {
		features += "FADF_FIXEDSIZE ";
	}
	if(miArray->fFeatures & FADF_RECORD) {
		features += "FADF_RECORD ";
	}
	if(miArray->fFeatures & FADF_HAVEIID) {
		features += "FADF_HAVEIID ";
	}
	if(miArray->fFeatures & FADF_HAVEVARTYPE) {
		features += "FADF_HAVEVARTYPE ";
	}
	if(miArray->fFeatures & FADF_BSTR) {
		features += "FADF_BSTR ";
	}
	if(miArray->fFeatures & FADF_UNKNOWN) {
		features += "FADF_UNKNOWN ";
	}
	if(miArray->fFeatures & FADF_DISPATCH) {
		features += "FADF_DISPATCH ";
	}
	if(miArray->fFeatures & FADF_VARIANT) {
		features += "FADF_VARIANT ";
	}
	sprintf(buffer, "SafeArray: features: 0x%04x --> %s\r\n", miArray->fFeatures, (LPCTSTR)features);
	printf("%s", buffer);
	OutputDebugString(buffer);*/

	sprintf(buffer, "Dimensions: Accessing through rgsabound\r\n");
	printf("%s", buffer);
	OutputDebugString(buffer);
	int i;
	for(i = 0; i < SafeArrayGetDim(miArray); i++) {
		sprintf(buffer, "dim[%d] => [%d to %d]  -  %d\r\n", i + 1, rgsabounds[i].lLbound, (rgsabounds[i].cElements + rgsabounds[i].lLbound) - 1, rgsabounds[i].cElements);
		printf("%s", buffer);
		OutputDebugString(buffer);
	}

	sprintf(buffer, "Dimensions: Accessing through SafeArray APIs\r\n");
	printf("%s", buffer);
	OutputDebugString(buffer);

	UINT dimensions = SafeArrayGetDim(miArray);
	long lBound, uBound;
	for(UINT j = 1; j <= dimensions; j++) {
		SafeArrayGetLBound(miArray, j, &lBound);
		SafeArrayGetUBound(miArray, j, &uBound);

		sprintf(buffer, "dim[%d] => [%d to %d]  -  %d\r\n", j, lBound, uBound, uBound - lBound + 1);
		printf("%s", buffer);
		OutputDebugString(buffer);
	}

	//PrintFirstDimension(miArray, 1);

    // Initializes indexes
    long* indices = new long[dimensions];
	SAFEARRAYBOUND* invertedBounds = new SAFEARRAYBOUND[dimensions];
	memcpy(invertedBounds, rgsabounds, sizeof(SAFEARRAYBOUND) * dimensions);

	InvertArrayBounds(invertedBounds, dimensions);

    for(i = 0; i < dimensions; i++) {
		indices[i] = invertedBounds[i].lLbound;
	}
	
	unsigned long dimension = indices[0] - 1;
	do {
		char temp[32];
		BSTR element;
		HRESULT hr = SafeArrayGetElement(miArray, indices, &element);

		sprintf(buffer, "[%d", indices[0]);
		for(int k = 1; k < dimensions; k++) {
			sprintf(temp, ", %d", indices[k]);
			strcat(buffer, temp);
		}
		sprintf(temp, "]=%S\r\n", element);
		strcat(buffer, temp);
		printf("%s", buffer);
		OutputDebugString(buffer);
		SysFreeString(element);
	}
	while(inc_indices(indices, invertedBounds, dimensions));
	delete[] indices;
	delete[] invertedBounds;

	return S_OK;
}