***************************************************************************
************************** COPYRIGHT NOTICE *******************************
***************************************************************************

Copyright ©2013. The Regents of the University of California (Regents).
All Rights Reserved. Permission to use, copy, modify, and distribute
this software and its documentation for educational, research, and
not-for-profit purposes, without fee and without a signed licensing
agreement, is hereby granted, provided that the above copyright notice,
this paragraph and the following two paragraphs appear in all copies,
modifications, and distributions. Contact The Office of Technology
Licensing, UC Berkeley, 2150 Shattuck Avenue, Suite 510, Berkeley, CA
94720-1620, (510) 643-7201, for commercial licensing opportunities.

Created by Jonathan T Barron and Jitendra Malik, Electrical Engineering
and Computer Science, University of California, Berkeley.

IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY,
PROVIDED HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


***************************************************************************
***************************************************************************
***************************************************************************

SIRFS release 1.5

This is the code for "Shape, Illumination, and Reflectance from Shading", Jonathan T. Barron and Jitendra Malik, 2013. http://www.cs.berkeley.edu/~barron/

This release is all undocumented and uncommented research code. It might crash, or destroy your computer, or become sentient. Email me with questions and comments: jonbarron@gmail.com, I'll help you out.

This code includes:
 - A slightly modified version of Mark Schmidt's optimization toolbox: http://www.di.ens.fr/~mschmidt/Software/minFunc.html
 - A heavily modified version of Carl Edward Rasmussen's "checkgrad" function for checking the analytical gradient of a function.
 - The MIT-Berkeley Intrinsic Image Dataset, which is based on the MIT Intrinsic Image Dataset: http://people.csail.mit.edu/rgrosse/intrinsic/
 - Some pre-processed spherical harmonic illuminations of natural environment maps taken from the sIBL Archive: http://www.hdrlabs.com/sibl/archive.html


to use the code:

************* COMPILING ****************

We use some simple mex files, run "compile.m" to hackily compile them.


************* TRAINING ****************

To (optionally) retrain the model, run go_TrainModel, to rebuild our priors on shape, reflectance, and illumination. Part of this takes a while, as it does lots of cross-validation, and I've attached the .mat files of the models so it's not necessary. NOTE: because of some small code issues, the training code doesn't produce exactly the same model as what is attached, so if you re-train things your results might differ from ours.


********** TESTING ON THE MIT-BERKELEY INTRINSIC IMAGES DATASET ***********

To run the model on the MIT-Berkeley Intrinsic Images dataset, run go_MIT(). This function takes as an argument a string that determines which sort of experiment you want to run. Some example Matlab code:

% Run on the color image of the "raccoon" object under natural illumination, run
go_MIT('params.EVAL_NAMES = {''raccoon''}; params.USE_COLOR_IMAGE = 1; params.NATURAL_ILLUMINATION = 1;');

% Run on a grayscale image of the "paper2" object under MIT's "laboratory" illumination, run:
go_MIT('params.EVAL_NAMES = {''paper2''}; params.USE_COLOR_IMAGE = 0; params.NATURAL_ILLUMINATION = 0;');

% To run a shape-from-contour version of SIRFS on the dinosaur object, run:
go_MIT('params.EVAL_NAMES = {''dinosaur''}; params.VARIANT = 13;');
% the PARAMETERS.m file contains the parameter settings of several helpful variants of our model (mostly ablations of priors)

% To run the variant of our model that takes in some external observation of the shape that is the ground-truth shape blurred by a Gaussian of standard deviation 30, run:
go_MIT('params.USE_INIT_Z = 1; params.INIT_Z_SIGMA = 30;');
% This is also variant 9 in PARAMETERS.m

% You can also use the ground-truth shape or illumination:
go_MIT('params.SOLVE_SHAPE = 0;'); % assume shape is known and solve for illumination
go_MIT('params.SOLVE_LIGHT = 0;'); % assume illumination is known and solve for shape

% Run on the entire test set of the MIT dataset, run:
[results, state, data, params, avg_err] = go_MIT('params.EVAL_NAMES = MIT_TEST;');
avg_err.avg % the geometric mean of the average error over the entire test set (where the average error for an image is the geometric mean of each error metric for that image)

Many parameter settings can be seen in CONSTANTS.m. These probably shouldn't be touched. The "multiplier" parameters in PARAMETERS.m control the weights of each prior, and can be fiddled with (but are set to be optimal on the training set). These are pretty much the only "parameters" of the model. The model is fairly sensitive to these parameters, so you should change them with care.


********** TESTING ON ARBITRARY IMAGES ***********

If you just want to use SIRFS one some data you have, you should use SIRFS.m as an interface. It takes in an arbitrary image (and a mask, and an optional external shape observation, and any optional additional parameter tweaks) and results everything. In data/Images are some random images, mostly taken by me on my iPhone, which appear in the paper. Feel free to use them for whatever. Some matlab examples:


% Load in some image, and run SIRFS on it.
input_image = double(imread('data/Images/Peets.png'))/255;
input_mask = all(input_image > 0,3);
output = SIRFS(input_image, input_mask, [], '');


% Load in some image, and run grayscale SIRFS on it.
input_image = mean(double(imread('data/Images/Peets.png'))/255,3);
input_mask = all(input_image > 0,3);
output = SIRFS(input_image, input_mask, [], '');


%  Load in an image (which happens to be from the MIT dataset) and fix its
%  shape to be the true shape
input_image = double(imread('data/MIT-Berkeley-Natural/raccoon/diffuse.png')) / double(intmax('uint16'));
input_mask = all(input_image > 0, 3);
load data/MIT-Berkeley-Laboratory/raccoon/Z.mat
input_height = depth;
output = SIRFS(input_image, input_mask, input_height, 'params.SOLVE_SHAPE = 0;');


%  Load in a grayscale image (which happens to be from the MIT dataset) and
%  incorporate some noisy external shape observation.
input_image = mean(double(imread('data/MIT-Berkeley-Laboratory/raccoon/diffuse.png')) / double(intmax('uint16')),3);
input_mask = all(input_image > 0, 3);
load data/MIT-Berkeley-Laboratory/raccoon/Z.mat
input_height = depth + randn(size(depth))*3;

% Both of these control how external shape information is used. Because
% these are probably different for your application than they were for
% mine, you should probably fiddle with these.
sigma = 5; % Controls the "bandwidth" of the input depth (the standard deviation of a Gaussian at which point the signal becomes reliable)
mult = 20; % Controls the importance of the input depth (the multiplier on the loss)
output = SIRFS(input_image, input_mask, input_height, ['params.USE_INIT_Z = true; params.INIT_Z_SIGMA = ', num2str(sigma), '; params.multipliers.height.init = { ', num2str(mult), ' };']);


You can also use the parameter input string to play with the "multipliers", which you may find useful if your data is unusual or specific. For example, if you're looking at terrain imagery, it's probably flat, so the "slant" multiplier (which controls the isotropy prior) should probably be higher, etc.


********** SHAPE FROM SHADING ***********

If you're interested in doing basic shape-from-shading (IE, your objects have no reflectance variation, and are all painted white, which I'm told happens all the time in the real world) then we have a simple degenerate case of our algorithm for that. Really, this variant does "SIFS", as we recover illumination in addition to shape, though I guess you could hack the code to fix the illumination to something.

To do shape-from-shading, instead of minimizing g(I - S(Z,L)) (our prior on reflectance) we minimize a simple reconstruction term: mult * ((I - S(Z,L))^2 + ep^2)^(pow/2). The reflectance image we return is basically then just a "residual" image. The parameters governing this reconstruction term (mult, ep, pow) have been tuned to the training set, and the parameters governing them are in PARAMETERS.m.

% Load in a shading-only image (it can be color, no worries)
input_image = double(imread('data/MIT-Berkeley-Natural/raccoon/shading_color.png')) / double(intmax('uint16'));
input_mask = all(input_image > 0, 3);

% Do SIFS
output = SIRFS(input_image, input_mask, [], ['params.SHAPE_FROM_SHADING = 1;'] );

% Of course, because SIFS is a special case of SIRFS, SIRFS will do a pretty reasonable job on a reflectance-less image too (actually, I think SIRFS usually looks better, for some reason):
output = SIRFS(input_image, input_mask ); 


********** PHOTOMETRIC STEREO ***********

In our papers, we mentioned that we used our own photometric stereo algorithm to produce our ground-truth depth and illumination for the MIT Intrinsic Image dataset. That code is not included in this package, but SIRFS can be modified into a photometric stereo algorithm pretty easily. All you need to do is optimize over N images (and N reflectance images and N illuminations) instead of 1 image, while using the same shape for each image. We have simple code that does this, which basically modifies SIRFS from minimizing a single loss to minimizing an average loss over several reflectances and illuminations. It seems to work pretty well, though I haven't really evaluated it empirically at all (this is hard to do, as the ground-truth was produced by a different photometric stereo algorithm). But perhaps someone will find this useful. You could use this to recreate a new ground-truth for an intrinsic image dataset, but in that scenario, it may be wise to modify this model a bit. For example, you would want to encourage each reflectance image for the same object to resemble each other, and you would want the illumination model for each illumination condition to be the same, or similar, across objects.

% Run a photometric stereo algorithm on the 10 images of an object in the MIT Intrinsic Image dataset.
states = go_MIT_PhotometricStereo('params.NATURAL_ILLUMINATION = 0;');

