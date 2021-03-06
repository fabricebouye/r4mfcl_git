#' Plots of SSB (or total biomass or recruit) stacked by region and (if 2-sex ) by gender
#' @param plotrep output of read.rep
#' @param pmain pmain
#' @param type string either "SSB", "REC", or anything else (total biomass)
#' @param maxylim naximum of y-axis
#' @param lgposi position of legend
#' @param reg.cols colos to be used for each stacked level
#' @param tit.colour color of title
#' @param reverse LOGICAL order of stack
#' @param fill LOGICAL if plot area be filled with color
#' @param alpha alpha for colors of filled area
#' @param plot LOGICAL plot be sent to graphics device or not
#' @param reg.labels labels for each region
#' @param femaleOnly if TRUE and the model is sex structured and type=="SSB", only female SSB be plotted
#' @param scaler scaler to apply (default=1), this is to be used to compare e.g. sex agregated model with 2 sex model
#' @param verbose LOGICAL if to print out messages
#' @importFrom ggplot2 ggplot geom_area aes_string guides guide_legend position_stack
#' @importFrom ggplot2 scale_fill_manual scale_fill_discrete theme labs element_text scale_color_manual scale_color_discrete
#' @importFrom magrittr "%>%"
#' @importFrom tidyr gather
#' @importFrom grDevices grey
#'
#' @export
#'
plot_biomass.stacked.gg <- function(plotrep, pmain="Run 3d", type="SSB", maxylim=NULL,
                                        lgposi=c(0.9, 0.93), reg.cols = NULL, tit.colour=grey(0.4),reverse=TRUE,fill=TRUE,
                                        alpha=1,plot=TRUE,reg.labels=NULL,femaleOnly=TRUE,scaler=1,verbose=FALSE)
{
#  require(ggplot2)
#  require(tidyr)
#  require(magrittr)
#  require(scales)
## Quick remedy for lgposi
if(length(lgposi)==1 && lgposi=="topright"){lgposi<-c(0.9,0.93);cat("lgposi was changed from topright to c(0.9,0.95)")}
if(length(lgposi)==1 && lgposi=="topleft"){lgposi<-c(0.1,0.93);cat("lgposi was changed from topright to c(0.1,0.95)")}
## check lgposi since legend.position of ggplot only accepts
## ("none", "left", "right", "bottom", "top", or two-element numeric vector)
if(length(lgposi)==1 && match(lgposi, c("none", "left", "right", "bottom", "top"), nomatch = 0) == 0){
  stop("lgposi only accepts (\"none\", \"left\", \"right\", \"bottom\", \"top\", or two-element numeric vector)")
}
# Number of years
  nyr <- plotrep$nTimes

#first year
  year1 <- plotrep$Year1

#number of time steps per year
  tsteps <- plotrep$nRecs.yr
  year <- trunc(seq(year1,length=nyr,by=1/tsteps))

  if(type=="SSB")
  {
     #    B <- plotrep$AdultBiomass/1000
    B <- if(plotrep$nSp==1 ||  !femaleOnly){
          plotrep$AdultBiomass/1000*scaler
        }else{
          plotrep$AdultBiomass[,which(plotrep$regSpPtr==which(plotrep$spSexPtr==1))]/1000*scaler
        }
if(verbose){ cat("L36 in plot.biomass.stacked.gg.r\n");browser()}
         textlab <- "Spawning potential"
  }else{
    if(type=="REC"){
      B <- if(plotrep$nSp==1 ||  !femaleOnly){
        textlab <- "Recruitment (millions of fish)"
      	plotrep$Recruitment*tsteps/1000000*scaler
      }else{
        textlab <- "Female recruitment (millions of fish)"
      	plotrep$Recruitment[,which(plotrep$regSpPtr==which(plotrep$spSexPtr==1))]*tsteps/1000000*scaler
      }
    }else{
      B <- plotrep$TotBiomass/1000*scaler
      textlab <- "Total biomass (1'000's mt)"
    }
  }
    ##--- aggregate by year
if(plotrep$nReg > 1){
if(verbose) cat("L76\n") #;browser()
  Bout <- aggregate(B,list(year),mean)
} else {
  stop("This model only has one region so will look pretty stupid, that's why I'm not going to let you plot it")
}

if(verbose) cat("L82 in plot_biomass.stacked\n") #;browser()
titles <- paste("Region",seq(1,(ncol(Bout)-1)))
if(is.null(maxylim)){
  maxylim <- max(apply(Bout[,2:ncol(Bout)],1,sum))
}
yr <- Bout[,1]
cols<-if(!is.null(reg.cols)){
  reg.cols[1:(ncol(Bout)-1)]
}else{
  NULL
}

Bout.stacked<-Bout
for(i in 3:ncol(Bout)){
  Bout.stacked[,i]<-Bout.stacked[,i-1]+Bout.stacked[,i]
}
dimnames(Bout)[[2]]<-
dimnames(Bout.stacked)[[2]]<-c("Year",paste0("Region",1:(ncol(Bout.stacked)-1)))
if(verbose)cat("L76 in plot.biomass.stacked\n") # ;browser()
Bout.stacked.long<-Bout %>% gather(key="Region",value="val",-!!sym("Year"))
 Bout.stacked.long %>% ggplot()->plt
if(verbose){ cat("L79 in plot.biomass.stacked\n");browser()}
 plt<-plt+xlab("Year")+ylab(textlab)
if(fill){
  plt<-plt+geom_area(aes_string(x="Year",y="val",fill="Region"),position=position_stack(reverse=FALSE),alpha=alpha)
  plt<-if(!is.null(cols) && is.null(reg.labels)){
    plt+scale_fill_manual(values=cols)
  }else if(is.null(cols) && !is.null(reg.labels)){
    plt+scale_fill_discrete(labels=reg.labels)
  }else if(!is.null(cols) && !is.null(reg.labels)){
    plt+scale_fill_manual(values=cols, labels=reg.labels)
  }else{plt}
}else{
  plt<-plt+geom_line(aes_string(x="Year",y="val",color="Region"),position=position_stack(reverse=reverse))
  if(!is.null(cols) && is.null(reg.labels))plt<-plt+scale_color_manual(values=cols)
  if(is.null(cols) &&  !is.null(reg.labels))plt<-plt+scale_color_discrete(labels=reg.labels)
  if(!is.null(cols) && !is.null(reg.labels))plt<-plt+scale_color_manual(values=cols, labels=reg.labels)
}

plt<-plt+theme(legend.position = lgposi,legend.box=("vertical"))
if(reverse)plt<-plt+guides(fill = guide_legend(reverse=TRUE))
plt<-plt+guides(fill=guide_legend(title=NULL))
xlimits<-range(Bout[,1]) ;xlimits[1]<-floor(xlimits[1]/10)*10 ; xlimits[2]<-(floor(xlimits[2]/10)+1)*10 ; # +xlim(range(Bout[,1]))
#ylimits<-
plt<-plt+ylim(0,maxylim)+scale_x_continuous(breaks=seq(xlimits[1],xlimits[2],by=10),limits=xlimits)
if(!is.null(pmain)){
  plt<-plt+labs(title=pmain)+theme(plot.title=element_text(hjust = 0.5,color=tit.colour))
}
if(plot)print(plt)
return(invisible(plt))
}
