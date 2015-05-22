#include "math.h"
#include "mex.h"

void mexFunction(int nargout, mxArray *varargout[], int nargin, const mxArray *varargin[])
{
  
  mxArray *d_loss_N_mat, *d_loss_X_mat;
  
  mxArray *idx111_mat, *idx112_mat, *idx121_mat, *idx122_mat, *idx211_mat, *idx212_mat, *idx221_mat, *idx222_mat, *f1_mat, *f2_mat, *valid_mat;
  unsigned int *idx111, *idx112, *idx121, *idx122, *idx211, *idx212, *idx221, *idx222;
  double *f1, *f2;
  double *d_loss_N, *d_loss_X;
  bool *valid;
  
  double dV111, dV121, dV211, dV221, dV112, dV122, dV212, dV222;
  
  int n, i, d, j, idx1, idx2, idx3;
  
  d_loss_N_mat = varargin[0];
  idx111_mat = varargin[1];
  idx112_mat = varargin[2];
  idx121_mat = varargin[3];
  idx122_mat = varargin[4];
  idx211_mat = varargin[5];
  idx212_mat = varargin[6];
  idx221_mat = varargin[7];
  idx222_mat = varargin[8];
  f1_mat = varargin[9];
  f2_mat = varargin[10];
  valid_mat = varargin[11];
  
  n = mxGetDimensions(idx111_mat)[0];
  
  varargout[0] = mxCreateDoubleMatrix(n, 3, mxREAL);
  d_loss_X_mat = varargout[0];
  d_loss_X = mxGetPr(d_loss_X_mat);
  
  d_loss_N = mxGetPr(d_loss_N_mat);
  
  idx111 = mxGetPr(idx111_mat);
  idx112 = mxGetPr(idx112_mat);
  idx121 = mxGetPr(idx121_mat);
  idx122 = mxGetPr(idx122_mat);
  idx211 = mxGetPr(idx211_mat);
  idx212 = mxGetPr(idx212_mat);
  idx221 = mxGetPr(idx221_mat);
  idx222 = mxGetPr(idx222_mat);
  
  f1 = mxGetPr(f1_mat);
  f2 = mxGetPr(f2_mat);
  
  valid = mxGetPr(valid_mat);
  
  for (i = 0; i < n; i++){
    
    dV111 = d_loss_N[idx111[i]-1];
    dV121 = d_loss_N[idx121[i]-1];
    dV211 = d_loss_N[idx211[i]-1];
    dV221 = d_loss_N[idx221[i]-1];
    dV112 = d_loss_N[idx112[i]-1];
    dV122 = d_loss_N[idx122[i]-1];
    dV212 = d_loss_N[idx212[i]-1];
    dV222 = d_loss_N[idx222[i]-1];
    
    d = 0;
    idx1 = i;
    idx2 = idx1 + n;
    idx3 = idx2 + n;
    
    if (valid[idx1]){
      d_loss_X[idx1] = f1[idx2]*(f1[idx3]*(dV211-dV111) +f2[idx3]*(dV212-dV112)) + f2[idx2]*(f1[idx3]*(dV221-dV121) + f2[idx3]*(dV222-dV122));
    }
    
    if (valid[idx2]){
      d_loss_X[idx2] = f1[idx1]*(f1[idx3]*(dV121-dV111) +f2[idx3]*(dV122-dV112)) + f2[idx1]*(f1[idx3]*(dV221-dV211) + f2[idx3]*(dV222-dV212));
    }
    
    if (valid[idx3]){
      d_loss_X[idx3] = f1[idx1]*(f1[idx2]*(dV112-dV111) +f2[idx2]*(dV122-dV121)) + f2[idx1]*(f1[idx2]*(dV212-dV211) + f2[idx2]*(dV222-dV221));
    }
    

  }
  
}
