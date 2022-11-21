library("dplyr")  
df <-read.csv("Input", header = FALSE)

target <- pull(df, "V1")
targetpairs <-as.data.frame(t(combn(unique(target), 2)))
targetlocation <- pull(df, "V2")
targetlocationpairs <-as.data.frame(t(combn(unique(targetlocation), 2)))

list <-data.frame(targetpairs, targetlocationpairs)
list$TargetPair <- seq.int(nrow(list))
list<- list %>% relocate("TargetPair", .before = "V1")
list<- list %>% relocate("V1.1", .before = "V2")
write.csv(list,"OutputUniquePairs", row.names = FALSE)