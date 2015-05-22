#include "math.h"
#include "mex.h"

#define EPS 2.2204e-16
        
void mexFunction(int nargout, mxArray *varargout[], int nargin, const mxArray *varargin[])
{
  
  mxArray *dLK_mat, *dK_mat, *dLZ_mat;
  double *Z, *K, *dK;
  double Zx, Zy, Zxy, Zxx, Zyy, Za, Zb, Zc, Zd, Ze, Zf, Zg, Zh, ZxSq, ZySq, ZxSq_p, ZySq_p, ZxZy, ZmagSq, Zmag, denom, numer, b;
  double Z00, Z01, Z02, Z10, Z11, Z12, Z20, Z21, Z22;
  
  int *Z_sz, i0, j0, i1, j1, i2, j2, k0, k1, k2, Z_count, o;
  int idx00, idx01, idx10, idx11, idx20, idx21, idx12, idx02, idx22;
  
  dLK_mat = varargin[0];
  dLK = mxGetPr(dLK_mat);
  
  dK_mat = varargin[1];
  dK = mxGetPr(dK_mat);
  
  Z_sz = mxGetDimensions(dLK_mat);
  
  dLZ_mat = mxCreateDoubleMatrix(Z_sz[0], Z_sz[1], mxREAL);
  dLZ = mxGetPr(dLZ_mat);
  varargout[0] = dLZ_mat;
  
  for(i1 = 0; i1 < Z_sz[0]; i1++){
    for(j1 = 0; j1 < Z_sz[1]; j1++){
      
      
      j0 = j1 - 1;
      if (j0 < 0)
        j0 = 0;
      
      i0 = i1 - 1;
      if (i0 < 0)
        i0 = 0;
      
      j2 = j1 + 1;
      if (j2 >= Z_sz[1])
        j2 = Z_sz[1]-1;
      
      i2 = i1 + 1;
      if (i2 >= Z_sz[0])
        i2 = Z_sz[0]-1;
      
      k0 = Z_sz[0] * j0;
      k1 = Z_sz[0] * j1;
      k2 = Z_sz[0] * j2;
      
      
      idx00 = i0 + k0;
      idx10 = i1 + k0;
      idx20 = i2 + k0;
      
      idx01 = i0 + k1;
      idx11 = i1 + k1;
      idx21 = i2 + k1;
      
      idx02 = i0 + k2;
      idx12 = i1 + k2;
      idx22 = i2 + k2;
      
      o = idx11*6;
      denom = dK[o];
      df1 = 
      
      dK[o+1] = 2*(Zx*Zyy - Zy*Zxy) - (Zx*b);
      dK[o+2] = 2*(Zy*Zxx - Zx*Zxy) - (Zy*b);
      dK[o+3] = ZySq_p;
      dK[o+4] = ZxSq_p;
      dK[o+5] = ZxZy;

      dLZ[idx11] = dLK[idx11]
      
    }
  }
  
}
