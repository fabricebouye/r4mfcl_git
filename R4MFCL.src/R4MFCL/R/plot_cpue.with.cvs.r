#' @importFrom ggplot2 geom_point geom_line facet_wrap theme element_blank theme_set theme_bw aes_string
#' @importFrom magrittr "%<>%" "%>%"
#' @importFrom dplyr filter mutate summarise
#' @importFrom rlang quo
#' @importFrom stats setNames
#' @export
plot_cpue.with.cvs <- function(repfile=read.rep("ALB15/plot-12.par.rep"), frqfiles=read.frq("ALB15/alb.frq"),
                               fleetlabs=paste("Region",1:8), nfish=1:8, plot.layout=c(3,3), n.cols=3,
                               plot.annual=TRUE, fac.levels=c("P-ALL-1","P-ALL-2","P-ALL-3","S-ID.PH-4","S-ASS-ALL-5"))
{

# require(dplyr)
# require(magrittr)

theme_set(theme_bw())

    tmp <- if(repfile$nRecs.yr==4){
              data.frame(yrqtr = rep(repfile$yrs, each=length(nfish)), fishery = nfish)
           }else if(repfile$nRecs.yr==1){
              data.frame(yrqtr = rep( rep(repfile$yrs,each=4)+(1:4)/4-0.125, each=length(nfish)),fishery = nfish)
           }

    mat <- as.data.frame(frqfiles$mat)
    mat$se[mat$effort == -1] <- NA
    mat$effort[mat$effort == -1] <- NA  
    mat %<>% filter('%in%'(!!sym("fishery"), !!sym("nfish"))) %>% 
        mutate(cpue = !!sym("catch/effort"), cvs = !!sym("1/sqrt(2*se)"), yrqtr = !!sym("year + (qtr - 0.5)/12"))

    fshmeans <- aggregate(mat$cpue, list(mat$fishery), mean, na.rm=TRUE)
    mat$cpue <- mat$cpue/fshmeans[match(mat$fishery, fshmeans[,1]),2]

     mat %<>% mutate(LL = !!sym("exp(log(cpue) - 2*cvs)"), UL = !!sym("exp(log(cpue) + 2*cvs)"))
 

    pldat <- merge(mat, tmp, by=c("yrqtr","fishery"), all.y=TRUE)
    pldat$fishery <- factor(fleetlabs[pldat$fishery], levels = fac.levels)
    pldat$years <- floor(pldat$yrqtr)

    if(plot.annual){
    pldat %<>% group_by(!!sym("fishery"), !!sym("years")) %>% 
                summarise(cpue = !!sym("mean(cpue, na.rm=TRUE)"),
                                                          LL = !!sym("mean(LL, na.rm=TRUE)"),
                                                          UL = !!sym("mean(UL, na.rm=TRUE)"))
        pldat$yrqtr <- pldat$years
    }

    pl <- ggplot(pldat, aes_string(x="yrqtr", y="LL")) + geom_point(size=0.5, colour="grey") + geom_line(size=0.8, colour="grey") +
                 facet_wrap(~ fishery, ncol=n.cols) + xlab("Year") + ylab("CPUE") +
                 geom_line(aes_string(x="yrqtr", y="UL"), colour="grey", size=0.7) + geom_point(aes_string(x="yrqtr", y="UL"), colour="grey", size=0.5) +
                 geom_line(aes_string(x="yrqtr", y="cpue"), colour="black", size=0.7) + geom_point(aes_string(x="yrqtr", y="cpue"), colour="black", size=0.5) +
                 theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

    print(pl)

}











