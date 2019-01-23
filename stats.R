# Obs: It works only if the script is "Sourced" before the run.
# This can be done via the command: source('path/to/this/file/plots2.R')
# The suggestion is to use Rstudio as IDE and make sure to have the flag "Source on Save" checked.
# ( see: http://stackoverflow.com/questions/13672720/r-command-for-setting-working-directory-to-source-file-location )
# If it doesn't work because of UTF8, see: https://support.rstudio.com/hc/en-us/community/posts/200661587-Bug-when-sourcing-the-application?sort_by=votes 
this.dir <- dirname(parent.frame(2)$ofile)
setwd(this.dir)

library(ggplot2)
options(gsubfn.engine = "R") # Thanks to http://stackoverflow.com/questions/17128260/r-stuck-in-loading-sqldf-package
library(sqldf)
library(gridExtra)
library(gtable)
library(grid)
library(scales)
library(reshape2)
library(rPref)
library(xtable)
library(directlabels)
library(ggrepel)
#library(memisc)
library(ggthemes)
library(plotrix)
library(plyr)
#library(rescale)
library(dplyr)

folder <- './'
folderInput <- './log/'

# *********************************
# ******** UTILITY FUNCTIONS ******
# *********************************

f <- function(x) {
  if (x <= 9999 && x%%1==0 ) result <- as.integer(x+0.5)
  else {
    if (x<0.01 || x>9999) result <- sapply(strsplit(format(x, scientific=TRUE), split="e"), function(x) paste0("$", x[1], " \times 10^{", x[2], "}$"))
    else result <- as.integer(x*100+0.5)/100
  }
  return(result)
}

g <- function(x) {
  if (is.null(x) || is.na(x)) result <- "NA"
  else result <- paste("\\num{",x,"}",sep="")
  return(result)
}

optLegend <- theme(legend.direction = "horizontal", legend.justification = c(0, 1), legend.position = c(0.03,0.99))
noLegend <- theme(legend.position = "none", axis.title.x=element_blank(), axis.title.y=element_blank())
noAxisLabel <- theme(axis.title.x=element_blank(), axis.title.y=element_blank())
scaleGrey <- scale_fill_grey(start = 0.5, end = 1)

g_legend <- function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}
geo <- geom_point(size=2)
nl <- theme(legend.position="none")
bl <- theme(legend.direction = "horizontal", legend.position = "bottom")
sm <- geom_smooth(method=lm, se=FALSE) #see: http://www.sthda.com/english/wiki/ggplot2-scatter-plots-quick-start-guide-r-software-and-data-visualization

# *****************************
# ********** FUNCTIONS ********
# *****************************

# statistics about comparison experiments
statistics <- function() {
  print("Tabella 1")
  assign("dat", read.csv(paste(folderInput,"logsFinal.txt",sep=""), encoding="UTF-8"), envir=.GlobalEnv)
  #dat <<- transform(dat, correct = ifelse(correct == "true", 1, 0))
  datElab <<- sqldf("select benchmark,params,mfics,maxmficsize,process,avg(initTests),avg(askedTests),avg(benCycles),avg(totalTests) as avgTests,avg(time) as avgTime,avg(f) from dat group by benchmark,process,params,mfics,maxmficsize")
  datElab2 <<- sqldf("select process,benchmark,avg(initTests) as TSinit,avg(askedTests) as TSasked,avg(benCycles) as cycles,avg(totalTests) as avgTests, avg(time) as avgTime, avg(precision) as avgPrecision, avg(recall) as avgRecall, avg(f) as avgF from dat group by process, benchmark")
  print("datElab3")
  datElab3 <<- sqldf("select datElab2.process, datElab2.benchmark, TSinit, TSasked, cycles, avgTests, sqrt(sum((totalTests-avgTests)*(totalTests-avgTests))/(count(*))) as varTests, avgTime, avgPrecision, avgRecall, avgF from datElab2,dat where dat.process=datElab2.process and dat.benchmark=datElab2.benchmark group by datElab2.process, datElab2.benchmark")
  print("datElab4")
  datElab4 <<- sqldf("select process, avg(TSinit), avg(TSasked), avg(cycles), avg(avgTests), avg(varTests), avg(avgTime), avg(avgPrecision),avg(avgRecall),avg(avgF) from datElab3 group by process")
  #  datElab4 <<- sqldf("select datElab2.process, TSinit, TSasked, cycles, avgTests, sqrt(((sum(totalTests)-sum(avgTests))*(sum(totalTests)-sum(avgTests)))/(count(*)-1)) as varTests, avgTime, correctness from datElab2,dat where dat.process=datElab2.process group by datElab2.process")
  
  #datTable <- format(datElab, digits=3)
  #print(xtable(datTable, type = "latex", display=c("s","s","s","s","s","s","s","s","s","s","s","s")))
  
  #datTable <- format(datElab2, digits=3)
  #print(xtable(datTable, type = "latex", display=c("s","s","s","s","s","s","s","s")))
  print("datElab4Table:")
  datTable <- format(datElab4, digits=3)
  print(xtable(datTable, type = "latex", display=rep("s",ncol(datTable)+1)))
  
  #p <- ggplot(datElab2, aes(x = correctness, y = avgTests)) + geom_point(aes(color=process)) + 
  #  xlab("correctness") + ylab("tests") +
  #  theme_bw() 
  #ggsave(p,file=paste(folder,"frRepair.pdf",sep=""), width=4, height=3)
  
  # separa anche i vari benchmark (quelli reali)
  datElab3$process <- revalue(datElab3$process, c("BEN"="CBEN"))
  datElab3$process <- revalue(datElab3$process, c("FIC"="BFIC"))
  datElab3$process <- revalue(datElab3$process, c("MIX"="AMIX"))
  datElab3$process <- revalue(datElab3$process, c("MFS"="DSOFOT"))
  datElab5 <<- data.frame(unique(datElab3[,2]))
  print(unique(datElab3[,2]))
  datElabOrd <- sqldf(paste("select process from datElab3 order by process", sep=""))
  for (process in unique(datElabOrd[,1])) {
    print(process)
    datElab5[paste(process,"test")] <<- sqldf(paste("select avg(avgTests) from datElab3 where process = '",process,"' group by benchmark", sep=""))
    datElab5[paste(process,"precision")] <<- sqldf(paste("select avg(avgPrecision) from datElab3 where process = '",process,"' group by benchmark", sep=""))
    datElab5[paste(process,"recall")] <<- sqldf(paste("select avg(avgRecall) from datElab3 where process = '",process,"' group by benchmark", sep=""))
    datElab5[paste(process,"f")] <<- sqldf(paste("select avg(avgF) from datElab3 where process = '",process,"' group by benchmark", sep=""))
    datElab5[paste(process,"time")] <<- sqldf(paste("select avg(avgTime) from datElab3 where process = '",process,"' group by benchmark", sep=""))
                                   #sqldf("select process, avg(avgTests), avg(varTests), avg(avgTime) from datElab3 group by process")
  }
  datTable <- format(datElab5, digits=2)
  print(xtable(datTable, type = "latex", display=rep("s",ncol(datTable)+1)))
  #datElab5 <<- mutate_all(datElab5, funs(replace(., !is.numeric(.), 0)))
  #for (i in names(datElab5))
  #df <- as.data.frame(lapply(datElab5, function(x){replace(x, is.na(x) || x=='NA',0.0)}))
  #print(df)
  #print(apply(df, 2, mean) )
  write.csv(datElab5, "data.csv", na = "0")
}
statistics()
