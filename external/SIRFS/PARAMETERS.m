% Copyright ©2013. The Regents of the University of California (Regents).
% All Rights Reserved. Permission to use, copy, modify, and distribute
% this software and its documentation for educational, research, and
% not-for-profit purposes, without fee and without a signed licensing
% agreement, is hereby granted, provided that the above copyright notice,
% this paragraph and the following two paragraphs appear in all copies,
% modifications, and distributions. Contact The Office of Technology
% Licensing, UC Berkeley, 2150 Shattuck Avenue, Suite 510, Berkeley, CA
% 94720-1620, (510) 643-7201, for commercial licensing opportunities.
%
% Created by Jonathan T Barron and Jitendra Malik, Electrical Engineering
% and Computer Science, University of California, Berkeley.
%
% IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
% SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
% ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
% REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY,
% PROVIDED HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO
% PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


if ~params.SHAPE_FROM_SHADING
  
  if (params.NATURAL_ILLUMINATION == 0) && (params.USE_COLOR_IMAGES == 0)
    
    params.multipliers.height.smooth =  { 6.7272 }; % Mean Curvature Variation lambda
    params.multipliers.height.slant =   { 2.3784 }; % Isotropy lambda
    params.multipliers.height.contour_mult =    { 3.3636 }; % Contour lambda
    params.multipliers.height.contour_power =   { 0.75 }; % Contour gamma
    params.multipliers.height.init =    { 8 }; % External shape observation lambda
    params.multipliers.height.init_power =  { 1.1892 };  % External shape observation gamma
    
    params.multipliers.reflectance.smooth =  { 6.7272 }; % Reflectance smoothness lambda
    params.multipliers.reflectance.entropy_sigma =   { 1.6818 }; % Reflectance entropy sigma (parzen window bandwidth)
    params.multipliers.reflectance.entropy =         { 1.4142 }; % Reflectance entropy lambda
    params.multipliers.reflectance.hist =    { 4 }; % Absolute reflectance lambda
    
    params.multipliers.light.gaussian =         { 4.7568 }; % Illumination prior lambda
    
    
  elseif (params.NATURAL_ILLUMINATION == 0) && (params.USE_COLOR_IMAGES == 1)
    
    params.multipliers.height.contour_mult =    { 4 };
    params.multipliers.height.contour_power =   { 0.75 };
    params.multipliers.height.init =    { 6.7272 };
    params.multipliers.height.slant =   { 2.3784 };
    params.multipliers.height.smooth =  { 6.7272 };
    params.multipliers.height.init_power =      { 1.4142 };
    
    params.multipliers.reflectance.entropy_sigma =   { 1.6818 };
    params.multipliers.reflectance.entropy =         { 3.3636 };
    params.multipliers.reflectance.hist =    { 4.7568 };
    params.multipliers.reflectance.smooth =  { 13.4543 };
    
    params.multipliers.light.gaussian =         { 4.7568 };
    
    
  elseif (params.NATURAL_ILLUMINATION == 1) && (params.USE_COLOR_IMAGES == 1)
    
    params.multipliers.height.contour_mult =    { 2.8284 };
    params.multipliers.height.contour_power =   { 0.75 };
    params.multipliers.height.init_power =      { 0.8409 };
    params.multipliers.height.slant =   { 1 };
    params.multipliers.height.smooth =  { 4.7568 };
    params.multipliers.height.init =    { 2 };
    
    params.multipliers.reflectance.entropy_sigma =   { 2.8284 };
    params.multipliers.reflectance.entropy =         { 3.3636 };
    params.multipliers.reflectance.hist =    { 4.7568 };
    params.multipliers.reflectance.smooth =  { 16 };
    
    params.multipliers.light.gaussian =         { 3.3636 };
    
  else
    assert(0);
  end
  
  
  if isfield(params, 'VARIANT')
    
    if params.VARIANT == 1
      
      params.multipliers.height.contour_mult =    { 0 };
      
    elseif params.VARIANT == 2
      
      params.multipliers.height.slant =   { 0 };
      
    elseif params.VARIANT == 3
      
      params.multipliers.height.smooth =  { 0 };
      
    elseif params.VARIANT == 4
      
      params.multipliers.reflectance.entropy =         { 0 };
      
    elseif params.VARIANT == 5
      
      params.multipliers.reflectance.hist =    { 0 };
      
    elseif params.VARIANT == 6
      
      params.multipliers.reflectance.smooth =  { 0 };
      
    elseif params.VARIANT == 7
      
      params.multipliers.light.gaussian =         { 0 };
      
    elseif params.VARIANT == 8
      
      params.SOLVE_LIGHT = 0;
      
    elseif params.VARIANT == 9
      
      params.USE_INIT_Z = 1;
      params.INIT_Z_SIGMA = 30;
      
    elseif params.VARIANT == 10
      
      params.WHITEN_LIGHT = 0;
      
    elseif params.VARIANT == 11
      
      params.MAX_PYR_DEPTH = 1;
      
    elseif params.VARIANT == 12 % Don't do anything
      
      params.multipliers.height.contour_mult =    { 0 };
      params.multipliers.height.slant =   { 0 };
      params.multipliers.height.smooth =  { 0 };
      params.multipliers.height.init =    { 0 };
      
      params.multipliers.reflectance.entropy_sigma =   { 2.8284 };
      params.multipliers.reflectance.entropy =         { 0 };
      params.multipliers.reflectance.hist =    { 0 };
      params.multipliers.reflectance.smooth =  { 0 };
      
      params.multipliers.light.gaussian =         { 0 };
      
      
    elseif params.VARIANT == 13 % Shape-from-Contour
      
      % These parameters minimize error on the training set, but produce
      % kinda ugly looking results (because the shape smoothness paramters is
      % so high). Feel free to fiddle with that, and the slant prior, to
      % produce nicer looking results
      
      params.multipliers.height.contour_mult =    { 2.8284 };
      params.multipliers.height.contour_power =   { 0.75 };
      params.multipliers.height.init_power =      { 0.8409 };
      params.multipliers.height.init =    { 0 };
      params.multipliers.height.slant =   { 0.25 };
      params.multipliers.height.smooth =  { 64 };
      
      params.multipliers.reflectance.entropy_sigma =   { 1.6818 };
      params.multipliers.reflectance.entropy =         { 0 };
      params.multipliers.reflectance.hist =    { 0 };
      params.multipliers.reflectance.smooth =  { 0 };
      
      params.multipliers.light.gaussian =         { 0 };
      
    end
    
  end
  
else % Shape-from-Shading parameters
  
  if (params.NATURAL_ILLUMINATION == 0) && (params.USE_COLOR_IMAGES == 0)
    
    params.multipliers.sfs.power = { 1.414200 };
    params.multipliers.sfs.mult = { 56.568500 };
    params.multipliers.sfs.epsilon = { 0.004000 };
    
    params.multipliers.height.smooth = { 0.420400 };
    params.multipliers.height.slant = { 1.681800 };
    params.multipliers.height.contour_mult =    { 3.3636 };
    params.multipliers.height.contour_power = { 3.000300 };
    
    params.multipliers.light.gaussian = { 2.378400 };

    
  elseif (params.NATURAL_ILLUMINATION == 0) && (params.USE_COLOR_IMAGES == 1)
    
    params.multipliers.sfs.power = { 1.414200 };
    params.multipliers.sfs.mult = { 56.568500 };
    params.multipliers.sfs.epsilon = { 0.004000 };
    
    params.multipliers.height.smooth = { 0.420400 };
    params.multipliers.height.slant = { 1.681800 };
    params.multipliers.height.contour_mult = { 2.378400 };
    params.multipliers.height.contour_power = { 3.000300 };
    
    params.multipliers.light.gaussian = { 4.756800 };
    
  elseif (params.NATURAL_ILLUMINATION == 1) && (params.USE_COLOR_IMAGES == 1)
    
    params.multipliers.sfs.power = { 1.000000 };
    params.multipliers.sfs.mult = { 28.284300 };
    params.multipliers.sfs.epsilon = { 0.000345 };
    
    params.multipliers.height.smooth = { 0.707100 };
    params.multipliers.height.slant = { 1.414200 };
    params.multipliers.height.contour_mult = { 2.828400 };
    params.multipliers.height.contour_power = { 0.500000 };
    
    params.multipliers.light.gaussian = { 4.000000 };
    
  else
    assert(0);
  end
  
end
