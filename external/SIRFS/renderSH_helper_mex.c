#include "math.h"
#include "mex.h"

void mexFunction(int nargout, mxArray *varargout[], int nargin, const mxArray *varargin[])
{
  
  double *N, *L, *E, *dL, *dN;
  double d[9];
  double c1, c2, c3, c4, c5;
  double c1d, c2d;
  int ii, i, j;
  double n1, n2, n3;
  double e0;
  bool return_dL, return_dN;
  
  return_dN = nargout >= 2;  
  return_dL = nargout >= 3;
  
  c1 = 0.429043;
  c2 = 0.511664;
  c3 = 0.743125;
  c4 = 0.886227;
  c5 = 0.247708;
  
  c1d = 2*c1;
  c2d = 2*c2;
  
  N = mxGetPr(varargin[0]);
  L = mxGetPr(varargin[1]);
  
  ii = mxGetDimensions(varargin[0])[0];
  
  varargout[0] = mxCreateDoubleMatrix(ii, 1, mxREAL);
  E = mxGetPr(varargout[0]);
  
  if(return_dN){
    varargout[1] = mxCreateDoubleMatrix(ii, 3, mxREAL);
    dN = mxGetPr(varargout[1]);
  }

  if(return_dL){
    varargout[2] = mxCreateDoubleMatrix(ii, 9, mxREAL);
    dL = mxGetPr(varargout[2]);
  }
    
  for( i = 0; i < ii; i = i + 1){
    
    n1 = N[i];
    n2 = N[i + ii];
    n3 = N[i + 2*ii];
    
    d[0] = c4;
    d[1] = c2d*n2;
    d[2] = c2d*n3;
    d[3] = c2d*n1;
    d[4] = c1d*n1*n2;
    d[5] = c1d*n2*n3;
    d[6] = c3*n3*n3 - c5;
    d[7] = c1d*n1*n3;
    d[8] = c1*(n1*n1 - n2*n2);
    
    e0 = 0;
    for(j = 0; j < 9; j++){
      e0 += d[j]*L[j];
    }
    
    E[i] = e0;
      
    if(return_dL){
      for(j = 0; j < 9; j++){
        dL[i + j*ii] = d[j];
      }
    }

    if(return_dN){
      dN[i] = n1*c1d*L[8] + n2*c1d*L[4] + n3*c1d*L[7] + c2d*L[3];
      dN[i + ii] = n1*c1d*L[4] - n2*c1d*L[8] + n3*c1d*L[5] + c2d*L[1];
      dN[i + 2*ii] = n1*c1d*L[7] + n2*c1d*L[5] + 2*n3*c3*L[6] + c2d*L[2];

    }
  }
}
