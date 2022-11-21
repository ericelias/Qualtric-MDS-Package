# Qualtric-MDS-Package
Contains all the necessary code to build an MDS study in Qualtrics and convert to a similarity matrix from in R

Everything is included to create an MDS study in Qualtrics from similarity ratings of two target images. This study uses the Qualtrics
loop and merge function to control the presenation of target pairs. The javascript and html code include include randomization within
each question to randomly assign where images are displayed (either the left or right). The randomization of left/right image as well 
target pair gets stored in the "order" embedded data field as a complete list. R code is also included to untangle that list.

The javascript and html code also incorporates a 1 second delay to prevent one image from loading before the other. The amount of freeze 
time can be adjusted by the experimenter. 

The uniquepairs.R file is used to populate the loop and merge list. This scipt takes a list of targets along with their sources locations
and outputs all the unique pairs.

