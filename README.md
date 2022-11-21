Everything is included to create a pairwise similarity rating study in Qualtrics. The survey uses the Qualtrics loop and merge function to control the presentation of target image pairs. The javascript and html code include randomization within each question to randomly assign where images are displayed (either the left or right). The randomization of left/right images and target pairs is stored in the "order" embedded data field as a complete list. R code is also included to untangle that list and assign to the proper trial for analysis.

The javascript and html code also incorporates a 1 second delay to prevent one image from loading before the other. The amount of freeze time can be adjusted by the experimenter. 

The uniquepairs.R script takes a list of targets along with their source locations and outputs all possible unique pairs. This output should be transfered to the loop and merge list in Qualtrics.

