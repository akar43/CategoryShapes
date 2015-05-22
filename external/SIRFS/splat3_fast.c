#include "math.h"
#include "mex.h"

# define ACCURACY 10
# define N_SIGMAS 6
# define N_BINS_MAX 50
# define N_BINS_MIN 10
# define EPS 2.2204e-15

void mexFunction(int nargout, mxArray *varargout[], int nargin, const mxArray *varargin[])
{
  
  mxArray *X_mat, *valid_mat, *span_mat, *n_bins_mat, *bin_width_mat, *bin_area_mat, *dims_mat, *N_mat, *bin_range_high_mat, *bin_range_low_mat, *half_width_mat;
  double *X, *bin_range_low, *bin_range_high, sigma, *span, *n_bins, *bin_width, *bin_area, *dims, *N, *half_width;
  
  mxArray *idx111_mat, *idx112_mat, *idx121_mat, *idx122_mat, *idx211_mat, *idx212_mat, *idx221_mat, *idx222_mat, *f1_mat, *f2_mat;
  unsigned int *idx111, *idx112, *idx121, *idx122, *idx211, *idx212, *idx221, *idx222;
  double *f1, *f2;
  double x, dX, before;
  double xx[3];
  double ff1[3];
  double ff2[3];
  unsigned int dd[3];
  unsigned int dims_expand[2];
  
  double ff10ff11, ff10ff21, ff20ff11, ff20ff21 = ff2[0] * ff2[1];
  
  int sz_mat[2];
  int int_dims[3];
  double n, t;
  int i, d, j;
  int idx;
  bool *valid;
  double bin_range_low_pad[3];
  double bin_range_high_pad[3];
    
  double f11f12, f21f12;
  
  
  char *fields[18] = {"valid", "span", "n_bins", "bin_width", "bin_area", "dims", "N", "idx111", "idx112", "idx121", "idx122", "idx211", "idx212", "idx221", "idx222", "f1", "f2"};
  varargout[0] = mxCreateStructMatrix(1, 1, 17, fields);
  
  X_mat = varargin[0];
  X = mxGetPr(X_mat);
  
  bin_range_low_mat = varargin[1];
  bin_range_low = mxGetPr(bin_range_low_mat);
  
  bin_range_high_mat = varargin[2];
  bin_range_high = mxGetPr(bin_range_high_mat);
  
  n = mxGetDimensions(X_mat)[0];
  
  valid_mat = mxCreateLogicalMatrix(n, 3);
  mxSetField(varargout[0], 0, "valid", valid_mat);
  valid = mxGetPr(valid_mat);
  
  span_mat = mxCreateDoubleMatrix(1, 1, mxREAL);
  mxSetField(varargout[0], 0, "span", span_mat);
  span = mxGetPr(span_mat);
  
  span[0] = 0;
  for (d = 0; d < 3; d++){
    
    t = bin_range_high[d] - bin_range_low[d];
    if (t > span[0]){
      span[0] = t;
    }
    
  }

  n_bins_mat = mxCreateDoubleMatrix(1, 1, mxREAL);
  mxSetField(varargout[0], 0, "n_bins", n_bins_mat);
  n_bins = mxGetPr(n_bins_mat);
  
  *n_bins = 100;

  
  bin_width_mat = mxCreateDoubleMatrix(1, 1, mxREAL);
  mxSetField(varargout[0], 0, "bin_width", bin_width_mat);
  bin_width = mxGetPr(bin_width_mat);
  
  *bin_width = *span / (*n_bins+1);
  
  
  bin_area_mat = mxCreateDoubleMatrix(1, 1, mxREAL);
  mxSetField(varargout[0], 0, "bin_area", bin_area_mat);
  bin_area = mxGetPr(bin_area_mat);
  
  *bin_area = (*bin_width)*(*bin_width)*(*bin_width);
  
  dims_mat = mxCreateDoubleMatrix(1, 3, mxREAL);
  mxSetField(varargout[0], 0, "dims", dims_mat);
  dims = mxGetPr(dims_mat);
  
  for (d = 0; d < 3; d++){
    dims[d] = 1 + ceil( (bin_range_high[d] - bin_range_low[d]) / (*bin_width) );
    int_dims[d] = (int)dims[d];
  }

  N_mat = mxCreateNumericArray(3, &int_dims, mxDOUBLE_CLASS, 0);
  mxSetField(varargout[0], 0, "N", N_mat);
  N = mxGetPr(N_mat);
  
  
  sz_mat[0] = (int)n;
  sz_mat[1] = (int)1;
  idx111_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx112_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx121_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx122_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx211_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx212_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx221_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  idx222_mat = mxCreateNumericArray(2, &sz_mat, mxUINT32_CLASS, 0);
  
  mxSetField(varargout[0], 0, "idx111", idx111_mat);
  mxSetField(varargout[0], 0, "idx112", idx112_mat);
  mxSetField(varargout[0], 0, "idx121", idx121_mat);
  mxSetField(varargout[0], 0, "idx122", idx122_mat);
  mxSetField(varargout[0], 0, "idx211", idx211_mat);
  mxSetField(varargout[0], 0, "idx212", idx212_mat);
  mxSetField(varargout[0], 0, "idx221", idx221_mat);
  mxSetField(varargout[0], 0, "idx222", idx222_mat);
  
  f1_mat = mxCreateDoubleMatrix(n, 3, mxREAL);
  f2_mat = mxCreateDoubleMatrix(n, 3, mxREAL);
  
  f1 = mxGetPr(f1_mat);
  f2 = mxGetPr(f2_mat);
  
  idx111 = mxGetPr(idx111_mat);
  idx112 = mxGetPr(idx112_mat);
  idx121 = mxGetPr(idx121_mat);
  idx122 = mxGetPr(idx122_mat);
  idx211 = mxGetPr(idx211_mat);
  idx212 = mxGetPr(idx212_mat);
  idx221 = mxGetPr(idx221_mat);
  idx222 = mxGetPr(idx222_mat);
   
  mxSetField(varargout[0], 0, "f1", f1_mat);
  mxSetField(varargout[0], 0, "f2", f2_mat);
 
  
  for (d = 0; d < 3; d++){
    bin_range_low_pad[d] = bin_range_low[d] + EPS;
    bin_range_high_pad[d] = bin_range_high[d] - EPS;
  }

  dd[0] = 1;
  dd[1] = dims[0];
  dd[2] = dims[0]*dims[1];
  
          
  for (i = 0; i < n; i++){
    for (d = 0; d < 3; d++){
      
      idx = i + n*d;
      if (X[idx] < bin_range_low_pad[d]){
        X[idx] = bin_range_low_pad[d];
      }else if (X[idx] > bin_range_high_pad[d]){
        X[idx] = bin_range_high_pad[d];
      }else{
        valid[idx] = true;
      }
      
      x = X[idx];
      
      dX = (x - bin_range_low[d]) / (*bin_width) + 1;
      
      before = (double)floor(dX);
      if (before > ((*n_bins)+1)){ before = (double)((*n_bins)+1); }
      
      ff2[d] = dX - before;
      ff1[d] = 1 - ff2[d];
      
      f2[idx] = ff2[d];
      f1[idx] = ff1[d];
      
      idx122[i] = idx122[i] + ( (unsigned int) before)*dd[d];
      
    }
    
    idx121[i] = idx122[i] - dd[2];
    idx222[i] = idx122[i] + dd[0];
    idx221[i] = idx222[i] - dd[2];
    idx112[i] = idx122[i] - dd[1];
    idx111[i] = idx112[i] - dd[2];
    idx212[i] = idx222[i] - dd[1];
    idx211[i] = idx212[i] - dd[2];
        
    ff10ff11 = ff1[0] * ff1[1];
    ff10ff21 = ff1[0] * ff2[1];    
    ff20ff11 = ff2[0] * ff1[1];
    ff20ff21 = ff2[0] * ff2[1];
            
    N[idx111[i]-1] = N[idx111[i]-1] + ff10ff11 * ff1[2];
    N[idx121[i]-1] = N[idx121[i]-1] + ff10ff21 * ff1[2];
    N[idx211[i]-1] = N[idx211[i]-1] + ff20ff11 * ff1[2];
    N[idx221[i]-1] = N[idx221[i]-1] + ff20ff21 * ff1[2];
    N[idx112[i]-1] = N[idx112[i]-1] + ff10ff11 * ff2[2];
    N[idx122[i]-1] = N[idx122[i]-1] + ff10ff21 * ff2[2];
    N[idx212[i]-1] = N[idx212[i]-1] + ff20ff11 * ff2[2];
    N[idx222[i]-1] = N[idx222[i]-1] + ff20ff21 * ff2[2];
      
      
  }
  
    
      
}
