#include "math.h"
#include "mex.h"

#define EPS 2.2204e-16
        
void mexFunction(int nargout, mxArray *varargout[], int nargin, const mxArray *varargin[])
{
  
  mxArray *Z_mat, *K_mat, *dK_mat;
  double *Z, *K, *dK;
  
  double Zx, Zy, Zxy, Zxx, Zyy, Za, Zb, Zc, Zd, Ze, Zf, Zg, Zh, ZxSq, ZySq, ZxSq_p, ZySq_p, ZxZy, ZmagSq, Zmag, denom, numer, b;
  double Z00, Z01, Z02, Z10, Z11, Z12, Z20, Z21, Z22;
  
  int *Z_sz, i0, j0, i1, j1, i2, j2, k0, k1, k2, Z_count, o, t;
  int idx00, idx01, idx10, idx11, idx20, idx21, idx12, idx02, idx22;
  int dK_dims[3];
  
  Z_mat = varargin[0];
  Z = mxGetPr(Z_mat);
  
  Z_sz = mxGetDimensions(Z_mat);
  
  K_mat = mxCreateDoubleMatrix(Z_sz[0], Z_sz[1], mxREAL);
  K = mxGetPr(K_mat);
  varargout[0] = K_mat;
  
  dK_dims[0] = (int)(Z_sz[0]);
  dK_dims[1] = (int)(Z_sz[1]);
  dK_dims[2] = 6;
  Z_count = dK_dims[0] * dK_dims[1];
  dK_mat = mxCreateNumericArray(3, &dK_dims, mxDOUBLE_CLASS, 0);
  dK = mxGetPr(dK_mat);
  varargout[1] = dK_mat;
    
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
      
      
      Zc = Z[idx22] - Z[idx00];
      Zd = Z[idx20] - Z[idx02];
      Ze = Z[idx00] + Z[idx22];
      Zf = Z[idx20] + Z[idx02];
      
      Zx = (Zc + Zd + 2*(Z[idx21] - Z[idx01]))/8;
      Zy = (Zc - Zd + 2*(Z[idx12] - Z[idx10]))/8;
      
      Za  = (Ze + Zf)/4 - Z[idx11];
      Zb  = (Z[idx12] + Z[idx10] - Z[idx21] - Z[idx01])/2;
      Zxy = (Ze - Zf)/4;
      
      Zyy = Za + Zb;
      Zxx = Za - Zb;
      
      
      ZxSq = Zx * Zx;
      ZySq = Zy * Zy;
      ZxSq_p = 1 + ZxSq;
      ZySq_p = 1 + ZySq;
      ZxZy = -2* Zx * Zy;
      ZmagSq = ZxSq_p + ZySq;
      Zmag = sqrt(ZmagSq);
      
      denom = 2*ZmagSq*Zmag;
      if (denom < EPS) { denom = EPS; }
      
      numer = ZxSq_p*Zyy + ZxZy*Zxy + ZySq_p*Zxx;
      
      K[idx11] = numer / denom;
      
      t = i1 + dK_dims[0]*j1;
      b = 3*(numer / ZmagSq);
      
      dK[t] = denom;
      dK[t + Z_count] = 2*(Zx*Zyy - Zy*Zxy) - (Zx*b);
      dK[t + 2*Z_count] = 2*(Zy*Zxx - Zx*Zxy) - (Zy*b);
      dK[t + 3*Z_count] = ZySq_p;
      dK[t + 4*Z_count] = ZxSq_p;
      dK[t + 5*Z_count] = ZxZy;
      
      
    }
  }
  
}
