# Download data for project
wget http://cs.berkeley.edu/~akar/categoryShapes/data.tar.gz
tar -xvzf data.tar.gz
mv data.tar.gz data/

# Download PASCAL VOC
wget http://host.robots.ox.ac.uk:8080/pascal/VOC/voc2012/VOCtrainval_11-May-2012.tar
tar xvzf VOCtrainval_11-May-2012.tar
mv VOCdevkit data/
mv VOCtrainval_11-May-2012.tar data/

# Download PASCAL 3D
wget ftp://cs.stanford.edu/cs/cvgl/PASCAL3D+_release1.0.zip
unzip PASCAL3D+_release1.0.zip
mv PASCAL3D+* data/

