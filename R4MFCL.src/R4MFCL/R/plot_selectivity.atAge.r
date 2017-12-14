## Function to plot selectivity of 2 sex model from
#' @importFrom ggplot2 ggplot theme_set theme_bw geom_line aes_string geom_point facet_wrap guides labs ylab
#' @importFrom tidyr gather separate unite
#' @importFrom dplyr mutate
#' @importFrom magrittr '%>%'
#' @importFrom stringr str_split str_trim
#' @importFrom data.table as.data.table
#' @importFrom rlang sym syms
#' @export
#'
plot_selectivity.atAge<-function(filename="selectivity-multi-sex",
                                 fishlab,
                                 xlab="Age",
                                 ylab="Selectivity",
                                 ncol=NULL,
                                 dir="h",
                                 rep=read.rep("plot-09.par.rep"),
                                 use.selex.multi.sex=FALSE,
                                 plot=TRUE,
                                 verbose=TRUE
                          ){
  if(verbose)cat("Starting plot_selectivityatAge\n")
#  require(ggplot2)
#  require(reader)
#  require(stringr)
#  require(magrittr)
#  require(data.table)
#  require(dplyr)
#  require(tidyr)
  theme_set(theme_bw())
  if(use.selex.multi.sex & filename=="selectivity-multi-sex" & file.exists(filename) & file.size(filename)>0){
  ## To-do need to deal with time blocks
    nSp<-2
    xx<-readLines(filename)
    nfish<-length(grep(xx,pattern="^# fishery"))
    xx[sort(c((1:nfish)*3,(1:nfish)*3-1))] %>%
      sapply(function(x){str_trim(x) %>% str_split(pattern=" +",simplify=T) %>% as.numeric()},simplify="array") ->yy
    dimnames(yy)[[1]]<-paste0(1:dim(yy)[1])
    dimnames(yy)[[2]]<-  paste0("FL",rep(1:nfish,each=2),c("Male","Female"))
    yy<-apply(yy,1:2,as.numeric)
    yy.dt2<-as.data.table(t(yy))
    yy.dt2$Gender<-rep(c("Male","Female"),nfish)
  }else{
    if(verbose)cat("L41;") #;browser()
    if(all(rep$SelexTblocks==1)){
      nfish<- dim(rep$SelAtAge)[1]/rep$nSp
      tblocks<-FALSE
      nfishWTblocks<-nfish
    }else{
      nfish<- length(rep$SelexTblocks)/rep$nSp
      tblocks<-TRUE
      nfishWTblocks<-sum(rep$SelexTblocks)/rep$nSp
    }
    nSp<-rep$nSp
    yy<-t(rep$SelAtAge)
    FL0<-unlist(sapply(1:nfish,function(i){
            nblk<-rep$SelexTblocks[i]
            tmp<-if(nblk==1){paste(i)}else{paste(i,1:nblk,sep="_")}
            if(i<10){paste0("0",tmp)}else{tmp}
          }))
    dimnames(yy)[[1]]<-paste0(1:dim(yy)[1])
    dimnames(yy)[[2]]<-if(nSp>1){
      paste0("FL",rep(FL0,2),c(rep("Male",nfishWTblocks),rep("Female",nfishWTblocks)))
    }else{
     paste0("FL",FL0)
    }
    yy<-apply(yy,1:2,as.numeric)
    yy.dt2<-as.data.table(t(yy))
    yy.dt2$Gender<-if(nSp>1){c(rep("Male",nfishWTblocks),rep("Female",nfishWTblocks))
    }else{rep("Both",nfishWTblocks)}
  }
  if(verbose)cat("L69;")
  fishlab<-if(use.selex.multi.sex & filename=="selectivity-multi-sex" & file.exists(filename) & file.size(filename)>0){
    if(is.null(fishlab)){
      paste(rep(FL0,each=2),paste0("FL",rep(FL0,each=2)),sep="_")
    }else{
      paste(rep(FL0,each=2),rep(unlist(sapply(1:nfish,function(i){rep(fishlab[i],rep$SelexTblocks[i])})),each=2),sep="_")
    }
  }else{
    if(is.null(fishlab)){
      paste(rep(FL0,2),paste0("FL",rep(FL0,2)),sep="_")
    }else{
      paste(rep(FL0,2),rep(unlist(sapply(1:nfish,function(i){rep(fishlab[i],rep$SelexTblocks[i])})),2),sep="_")
    }
  }
  #######
  if(verbose)cat("L79;")#;browser()
  yy.dt2$Fishery<-fishlab[1:(nfishWTblocks*nSp)]
  yy.dt2 %>% unite(col="Fishery_Gender",!!!syms(c("Fishery","Gender")),sep="-") %>%
      gather(key="AgeClass",value="selex",remove=-!!sym("Fishery_Gender")) %>%
      separate(col="Fishery_Gender",into=c("Fishery","Gender"),sep="-") %>%
      mutate(Age=!!sym("as.numeric(AgeClass)"),Fish=!!sym("Fishery"))-> yy.dt3
  p<-yy.dt3 %>% ggplot(aes_string(x="Age",y="selex"))
  p<-p+xlab(xlab)+ylab(ylab)
  p<-p+geom_line(aes_string(color="Gender"))+geom_point(aes_string(color="Gender"),size=1)+facet_wrap(~Fish,ncol=ncol,dir=dir)+ylab(ylab)
  if(nSp==1)p<-p+labs(colour="")+guides(color=FALSE)    #+guide_legend(label=FALSE)
#  browser()
  if(plot)print(p)
  return(invisible(p))
}
