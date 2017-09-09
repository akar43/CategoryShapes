## Category-Specific Object Reconstruction from a Single Image (CVPR 2015)
#### [Abhishek Kar\*](http://cs.berkeley.edu/~akar), [Shubham Tulsiani\*](http://cs.berkeley.edu/~shubhtuls), [Joao Carreira](http://cs.berkeley.edu/~carreira), [Jitendra Malik](http://cs.berkeley.edu/~malik)

![meanshapes](https://people.eecs.berkeley.edu/~akar/meanshapes.png)

### Datasets and Paths:
You will need [**PASCAL VOC 2012**](http://host.robots.ox.ac.uk:8080/pascal/VOC/voc2012/VOCtrainval_11-May-2012.tar) and [**PASCAL 3D+**](http://cvgl.stanford.edu/projects/pascal3d.html) to run the code. Download them and change the paths in `startup.m` to reflect your paths.

### Compilation:
Run `compile.m`. Compile the vlfeat library under `external/`

### Data:
```
$ sh setup_data.sh
```
The above script will download data for the project, PASCAL VOC 2012 and PASCAL 3D+ and put it under `data/`. It will also download and extract `vlfeat` in the `external/`.

All the required data can be downloaded from [here](http://cs.berkeley.edu/~akar/categoryShapes/data.tar.gz). Unzip in `BASE_DIR/data` where `BASE_DIR` is the root directory for the codebase.

The code needs data formatted as in `data/pascalData` with keypoints and segmentations (either as polygons or binary masks). It also needs keypoint names as in data/partNames and the train/val split in PASCAL as in `data/pascalTrainValIds` and metadata about keypoints as in `data/voc_kp_metadata` to align to a canonical frame (here the Pascal 3D frame) and ensure a right handed co-ordinate system.

### Train Models:
```
mainTrain('car','debug',<parameter options>)
```
This will train basis shape models for a particular class (here 'car') with the experiment
id `'debug'` that you can use later to visualize/test/evaluate. Look at `get_params.m`
for description of parameters.

### Test Models:
```
jobID = mainTest('car','debug','withKps',<parameter options>)
```
This will test the model you trained above (with train id `'debug'`) on the validation set. The test id (here `'withKps'`) is to enable testing with the same trained model with different test settings (e.g. with or without keypoints, with different parameters, with or without optimizing scale, translation, rotation etc).

### Visualizing Results:
```
visInferredShapes('car', jobID)
```
Visualize the results for the models above. `jobID` is returned by `mainTest` after
execution. It is usually `'Test<trainId><testId>'`. Use this id to perform all
operations on the test data (evaluation/visualization etc).

```
visNRSFMmodel('car', jobID)
```
Visualize the result of NRSFM. Shows the predicted 3D keypoints and their convex hull.

```
visDeformations('car', trainId)
```
Visualize the learnt deformation bases. Note: use `trainId` instead of `jobID` here.

### Evaluation:
```
mainEval('car',jobID);
```
This will run the mesh and depth map evaluation on the cached meshes and depth maps.

### Cached files:
All the files are cached under in `'cachedir'` which is usually `./cache`. The
cached files are named as follows:

- `shapeModelNRSFM.mat` - Parameters for the trained NRSFM model. Also contains `test_model` which contains                   the estimated parameters on the test set

- `shapeModelOpt<id>.mat` - Parameters for the trained basis shape models.

- `statesDir<id>` - Directory containing the projection parameters from NRSFM and other info per instance.

- `inferredShapes<id>` - Directory containing fitted basis shapes to instances, projection parameters after optimization etc.

- `meshes<id>` - Directory containing meshes fitted to each instance. Each file contains `'faces'` and `'vertices'`. Can be viewed using the showMesh function

- `depthMap<id>` - Directory containing meshes rendered into depth maps per instance.

- `sirfs<id>` - Directory containing the outputs from SIRFS. Contains albedo, depth, normals, shading and illumination maps.
