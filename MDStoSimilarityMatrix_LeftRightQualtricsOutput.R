library(dplyr)

###Qualtrics output
raw <- read.csv(
  "Raw Qualtrics Output", 
  header =TRUE)

###Unique pairs list used to create loop and merge in Qualtrics
uniquepairs <- read.csv(
  "The complete list copied into loop and merge. ALso the output from the uniquepair.R script", 
  header= TRUE)

###All targets with abbreviations and list number
Facecodes <- read.csv(
  "Basic list of faces along with abbreviations and an arbitrary numbering (starting with 1)", 
  header = FALSE)

###Removing extra columns from Qualtrics output csv
raw <- raw[-c(1,2),-c(1:8,10:17)]

###Changing the lowest and highest similarity ratings to integers
raw[raw=="Extremely Similar"] <- as.integer(7)
raw[raw=="Extremely Dissimilar"] <- as.integer(1)

###Unpacking left/right ordering embedded data
###Put the number of ratings per participant into ratings_per_participant value
ratings_per_participant <- 7
similarityratings <-c(1:ratings_per_participant)
raw$order <-sub(".", "", raw$order)
raw$order <- gsub(",,",",", raw$order)
df_order <- data.frame(raw$ResponseId, raw$order)
df_order <- df_order %>% rename(ResponseId = raw.ResponseId)
list <-c()
for (e in 1:length(similarityratings)){
  assignment <- c("left","right","TargetPair")
  question <- c(e,e,e)
  joint <- paste(question, assignment)
  joint <- gsub(" ", "_", joint)
  list <- append(list,joint)
}
df_order <- df_order %>% separate(raw.order, list)

###Creating long df by trial for order
df_order <-  df_order %>% pivot_longer(
  cols = -ResponseId,
  names_to = c("trial",".value"),
  names_pattern = '(\\d+)_(.*)')

###Adding target names to df_order
df_order$firstFace <- ifelse(
  df_order$left == '0', 
  uniquepairs$V1[match(df_order$TargetPair,uniquepairs$TargetPair)],
  uniquepairs$V2[match(df_order$TargetPair,uniquepairs$TargetPair)])
df_order$secondFace <- ifelse(
  df_order$right == '0', 
  uniquepairs$V1[match(df_order$TargetPair,uniquepairs$TargetPair)],
  uniquepairs$V2[match(df_order$TargetPair,uniquepairs$TargetPair)])

###Creating long df by trial for rating
df_long <- pivot_longer(raw, cols=2:11, names_to = "TargetPair", values_to = "Rating")
df_long <-df_long[!(is.na(df_long$Rating) | df_long$Rating==""), ]
df_long$TargetPair <- sub(".", "", df_long$TargetPair)
df_long$TargetPair <- gsub("\\_.*","", df_long$TargetPair)

###Merging df_long and df_order
df <- merge(df_long, df_order, by=c("ResponseId","TargetPair"))
df$Rating <- as.integer(df$Rating)

###Counting the number of trials for each participant
groupedtrials <- df %>% group_by(ResponseId) %>% summarize(total_trials = n_distinct(trial))
df$total_trials <- groupedtrials$total_trials[match(df$ResponseId, groupedtrials$ResponseId)]

###Finding the mode rating for each participant
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
groupmode <-df %>% group_by(ResponseId) %>% mutate(mode=Mode(Rating))
df$mode <- groupmode$mode

###Finding how often participant used mode rating and dividing by their total trials
df$rating_mode_match <- ifelse(df$mode==df$Rating,1,0)
group_mode_total <- df %>% group_by(ResponseId) %>%  summarise(Frequency = sum(rating_mode_match))
df$mode_total <- group_mode_total$Frequency[match(df$ResponseId, group_mode_total$ResponseId)]
df$mode_percentage <- df$mode_total/df$total_trials
df$junk <-ifelse(df$mode_percentage>=.9,1,0)

###Mean, SD, and z-score for each participant
meansd_raw <- df %>% group_by(ResponseId) %>% summarise(across(.cols = Rating, list(mean = mean, sd = sd)))
df$rating_average <- meansd_raw$Rating_mean[match(df$ResponseId, meansd_raw$ResponseId)]
df$rating_sd <- meansd_raw$Rating_sd[match(df$ResponseId, meansd_raw$ResponseId)]
df$rating_z <- (df$Rating-df$rating_average)/df$rating_sd

###Variable transformation of target names using FaceCodes raw
df$firstFace_rename <- Facecodes$V2[match(df$firstFace, Facecodes$V1)]
df$secondFace_rename <- Facecodes$V2[match(df$secondFace, Facecodes$V1)]
df$face1 <- Facecodes$V3[match(df$firstFace, Facecodes$V1)]
df$face2 <- Facecodes$V3[match(df$secondFace, Facecodes$V1)]
df$high <- pmax(df$face1,df$face2)
df$low <- pmin(df$face1,df$face2)

###'clean' is final raw from cleaning phase
###If mode rating is used in more than 90% of trials for participant, then participant is dropped
clean <- df %>% filter(junk == "0")

###Similarity Matrix building begins
###Assigning column and row names and populating with mean scores of similarity ratings from 'clean' raw
sm <- clean %>% group_by(high,low) %>% summarise(across(.cols = Rating, list(mean = mean)))
sm$dissim_mean <- 7 - sm$Rating_mean
rname <- Facecodes$V2
cname <- Facecodes$V2
len <-length(rname)
simmat <- data.frame(matrix(ncol = len, nrow = len, dimnames = list(rname,cname)))
for (e in 1:(len-1)){
  for (f in 1:(len-e)){
    l <- e+ f
    k <- sm[which(sm$low == e & sm$high == l), ]
    simmat[l,e] <- c(k[,4])
  }
}
###simmat is the final data frame needed for smacof MDS
