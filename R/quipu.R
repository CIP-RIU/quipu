#' Quipu-type charts for a set of SSR markers.
#' 
#' The chart shows SSR marker weights on a linear scale where each allele or 'gel band' is represented 
#' by a circle. The circle's diameter is sized inversely by its rareness within the set of accessions 
#' in the database at hand and within that locus. The purpose is to facilitate the visual screening
#' and comparison of genotypes with regard to these two questions:
#' 
#' What is the overall pattern of alleles in a genotype?
#' 
#' Which genotypes have rare alleles?
#' 
#' Motivation: Genebanks increasingly use molecular markers for routine
#' characterization of ex-situ collections and farmer managed diversity. CIP's
#' (International Potato Center) genebank presently uses a SSR marker-kit to
#' produce molecular profiles for potato accessions. We have been searching
#' for a compact graphical representation that shows both
#' molecular diversity and accession characteristics - thus permitting
#' biologists and collection curators to have a simpler way to interpret
#' high-volume data. Inspired by the ancient Andean quipus we devised a graph
#' that allows for standardized representation while leaving room for updates
#' of the marker kit and the collection of accessions. The graph has been used
#' in several CIP publications.
#' 
#' @name quipu-package
#' @docType package
NULL

#' @name potato.quipu
#' @title SSR sample data for a set of potato accessions
#' @description SSR sample data for a set of potato accessions
#' @format Tabular format. The records represent unique SSR marker weights in base pairs as obtained
#'    for a set of three accessions. The combination of the first three columns is unique. The fourth
#'    column map_location is used for assigning markers to chromosomes or linkage groups.
#' \itemize{
#'  \item{"acccession_id"} {Accession ID}
#'  \item{"marker"} {Marker name}
#'  \item{"marker_size"} {Marker size}
#'  \item{"map_location"} {Genetic ap location; usually Roman numbers for chromosomes or linkage group.}
#' }
#' @docType data
#' @keywords datasets
#' @aliases potato.quipu
# @export
NULL

#' @name allele.freqs
#' @title Sample allele frequencies
#' @description Sample allele frequencies
#' @format Tabular format. The records represent unique SSR alleles with their assigned frequencies. 
#' Frequencies were derived from the sample data and are just for illustrative purposes.
#' \itemize{
#'  \item{"marker"} {Marker name}
#'  \item{"marker_size"} {Marker size}
#'  \item{"frequency"} {A fraction between 0 and 1.}
#' }
#' @docType data
#' @keywords datasets
#' @aliases allele.freqs
# @export
NULL



library(stringr)
#library(agricolae)
library(pixmap)
library(shiny)


# assert <- function (expr, error) {
#   if (! expr) stop(error, call. = FALSE)
# }

layout_large_plot <- function (mrcs, grup1, ltr.size, id.label, nameclones, j, ylim, col.marg,
                               show.horizontal.lines=TRUE, show.desc = TRUE) {
  par(mar = c(6,4,4,2)+0.1)
  #print(mrcs)
  mainTitle = c(paste(id.label,": ",nameclones[j], sep=""),""," ")
  if(!show.desc) mainTitle = ""
  
  plot(1:length(mrcs),seq(min(grup1$Marker.size), max(grup1$Marker.size), length.out=length(mrcs)),
       type="n",axes=FALSE,ylab=list("Allele size [bp]",cex=ltr.size),
       #xlab=list("Chromosomes/SSR Name                                          ",cex=0.7, outer=TRUE),
       xlab="",
       main=mainTitle,
       cex.main= ltr.size ,xlim=c(1,length(mrcs)+7),ylim=ylim)
  mtext("                                                 Chromosomes/SSR name", 
        cex=ltr.size, side=1, line=5, adj=0)
  axis(2,seq(ylim[1],ylim[2],25),lwd=1.2,cex.axis=ltr.size,las=2, col=col.marg[2])  
  axis(3,at=1:length(mrcs),labels=1:length(mrcs),lwd=1.2,cex.axis=ltr.size, col=col.marg[3])
  axis(1, col = col.marg[1],at=1:length(mrcs) ,labels=mrcs,lty = 2, lwd = 1.2, cex.axis=ltr.size, las=2)
  
  # horizontal lines
  if(show.horizontal.lines){
    for(i in seq(ylim[1],ylim[2],25)) {
      lines(c(1,length(mrcs)),c(i,i),lty=3,lwd=0.8,col="gray80")
    } 
    
  }
}

layout_small_plot <- function (mrcs, grup1, ltr.size, id.label, nameclones, j, ylim, col.marg) {
  par(mar = c(0,0,0,0)+0.5)
  plot(1:length(mrcs),seq(min(grup1$Marker.size), max(grup1$Marker.size), length.out=length(mrcs)),
       type="n",axes=FALSE,ylab="",
       xlab="",
       main=""
       )
}


draw_vertical_lines <- function( mrcs, datt, ylim, obs.alls.frq, alls.range, layout,
                                 line.width = 2,
                                 show.size.range = TRUE
                                 ){
  ## the vertical lines 
  if(show.size.range) {
    alls.width = (line.width + 2)  
    alls.color = "grey80"
  } else {
    alls.width = line.width
    alls.color = "grey90"
  }
  
  for(i in 1:length(mrcs)){
   pt0=datt[datt$primer_name_original==mrcs[i],]
   pms = pt0$Marker.size
   if(nrow(pt0) == 0){
     pms = min(alls.range[alls.range$Marker == mrcs[i],"min"])
   }
   lines(c(i,i),c(min(pms),ylim[2]),lty=1,lwd=line.width,col="gray90",type = "l")  # line one
   lines(c(i,i),
           c(alls.range[alls.range$Marker == mrcs[i],"min"],
             alls.range[alls.range$Marker == mrcs[i],"max"]),
           #max(pt0$Marker.size)),
           lty=1,lwd=alls.width,col="gray80", type = "l")
   # } else {
      #lines(c(i,i),c(min(pt0$Marker.size),max(pt0$Marker.size)),lty=1,lwd=alls.width,col="gray80",type = "l")  
   # }
  }
  if(layout == "no text"){
    abline(h=(ylim[2]-28))
  }
  
}


draw_nodes <- function(mrcs, grup1, datt, ylim, ltr.size, dat){
  cmp="inicio"
  ## printing circles 
  mrcs = as.character(mrcs)
  #print(str(dat))
  dat[, 2] = as.character(dat[, 2])
  dat[, 4] = as.character(dat[, 4])
  #print(datt)
  for(i in 1:length(mrcs))
  {
    #print("Draw nodes")
    #print(str(mrcs[i]))
    
    pt1=grup1[grup1$primer_name_original==mrcs[i],]
    rom = as.character(dat[dat$primer_name_original == as.character(mrcs[i]),"Cromosomas"][1])
    #print(rom)
    #print(mrcs[i])
    # if(is.na(rom)){
    #   rom = obs.alls.frq
    # }
    #print(rom)
    
    #print(rom)
    if(nrow(pt1) > 0){
      # print(pt1[1, 4])
      # print(cmp)
      if(!is.na(cmp) & pt1[1,4] == cmp){
        lines(c(i-1,i),c(ylim[2],ylim[2]),lty=1,lwd=2,col="gray90",type = "l")
      }
      
      #sort alleles first by decreasing size
      pt1 = pt1[order(pt1[,5], decreasing = TRUE), ]
      points(rep(i,nrow(pt1)),pt1[,3],pch=16,col=pt1[,6],cex=pt1[,5])
      
      
      if(is.null(rom)){#} | nchar(rom)>6 ) {
        rom="unknw"
      }
    }
    text(i,(ylim[1]-5), rom, cex = ltr.size)
    
    cmp = rom
  }
}


draw_legend <- function(j, mrcs, ylim, grp.brks, col.fig, grp.size, ltr.size, img.format, 
                        nameclones2, species.name, set.name, clones, show.accs.total,
                        x, obs.alls.frq.ref, show_desc=TRUE){
  ## one legend
  legend(length(mrcs)+0.7, ylim[2], 
         c(paste("0% - ",                        round(grp.brks[1]*100,0),"%", sep=""), 
           paste(round(grp.brks[1]*100,0),"% - ",round(grp.brks[2]*100,0),"%", sep=""), 
           paste(round(grp.brks[2]*100,0),"% - ",round(grp.brks[3]*100,0),"%", sep=""), 
           paste(round(grp.brks[3]*100,0),"% - 100%", sep="")), 
         col = c(col.fig[1],col.fig[2],col.fig[3],col.fig[4]),
         text.col = "gray1", lty = c(1,1,1,1), pch = c(16,16,16,16), merge = TRUE,
         pt.cex=grp.size,
         cex=ltr.size,title="Allele frequency     ")
  if(interactive() & img.format!="screen") cat(paste(j,":\t",nameclones2[j],"\n",sep=""))
  ## two legend
  d1=species.name
  d2=set.name
  d3=date()
  d4=length(mrcs)
  d5=length(clones)
  if(show.accs.total ){
    imp=c("Species Name:",d1,"","Set Name:",d2,"",
          #"Total Markers:",d4,"",
          
          "Total Genotypes:",d5,"",
          "Source of allele frq:",obs.alls.frq.ref,"",
          "Evaluation Date:",d3,"")
  } else {
    imp=c("Species Name:",d1,"","Set Name:",d2,"",
          # "Total Markers:",d4,"",
          "Source of allele frq:",obs.alls.frq.ref,"",
          "Evaluation Date:",d3,"")
  }
  if(show_desc) legend(length(mrcs)+0.7,ylim[2]-70,imp,pch="",cex=ltr.size-.2, title="Description") 
  
  if(!is.na(x)){
    pixmap::addlogo(x, px=c(length(mrcs)+0.7,length(mrcs)+6.5), py=c(70,125))  
  }
  par(mar = c(5,4,4,2)+0.1)
  
}

get_obs_freq <- function(tbl){
  xx = paste0(tbl$primer_name, "_", tbl$marker_size)
  xy = table(xx)/length(xx)
  #zz = as.data.frame(cbind(Marker = names(xy), Frequency = as.numeric(xy)))
  Marker = stringr::str_split(names(xy), "_")
  zz = matrix(unlist(Marker), ncol = 2, byrow = T)
  zz = as.data.frame(cbind(zz, Frequency = as.numeric(xy)), stringsAsFactors = FALSE)
  names(zz) = c("marker", "marker_size", "frequency")
  zz[, 2] = as.integer(zz[, 2])
  zz[, 3] = as.numeric(zz[, 3])
  zz
}

#' Creates quipu-type charts for a set of SSR markers
#' 
#' The chart shows SSR marker weights on a linear scale where each allele or 'gel band' is represented 
#' by a circle. The circle's diameter can be sized and colored by its rareness. Two parameters 'col.fig' and
#' 'grp.size'allow to do so. The 'rareness' can be calculated - by default - based only on the dataset
#' at hand or by a supplied reference table. To do so, the parameter 'obs.alls.frq' expects a dataframe with
#' three columns named 'Marker', 'Marker.Size' and 'Frequency'. Another parameter, 'obs.alls.frq.ref'
#' should be used to supply a character string containing the reference to the source of allele
#' frequencies being used. For visualization purposes, the class breaks can be defined using a
#' vector of three numeric values in the range between 0 and 1 and be passed to the parameter
#' 'grp.brks'. The default is 0.01, 0.05 and 0.001.
#' 
#' The chart was motivated by the need to represent genetic uniqueness of potato plant materials in a given set
#' for a catalogue and the Andean tradition of quipus.
#' 
#' 
#' 
#' @name rquipu
#' @param data a data.frame with minimal four columns: accession_id, primer_name, marker_size, map_location; alternatively, 
#' @param a.subset a vector of accession identifiers
#' @param ylim the range of marker sizes (or alleles) in base pair (bp) units
#' @param res the resolution of the final image in pixels (width, height)
#' @param dir.print the directory to use for storing the created images; default: current working directory
#' @param dir.logo the path to a logo to display on the chart
#' @param col.node colors for the chart elements
#' @param col.marg colors for the chart margin elements
#' @param species.name scientific name of the species of the set of accessions
#' @param set.name a name for the set of accessions
#' @param img.format specify a format for the final chart (jpeg or png); default png.
#' @param ltr.size letter size 
#' @param show.accs.total a logical value to show the number of accessions from the dataset
#' @param id.label label for identifier
#' @param node.size size of circle diameter for allele circles by frequency group
#' @param grp.brks cut-off values between frequency groups; must be three values between 0 and 1 and in ascending order 
#' @param obs.alls.frq observed allele frequencies; format three-column data frame with heads: Marker, Marker.Size, Frequency. 
#' @param obs.alls.frq.ref a reference to the source of the allele frequencies
#' @param layout whether a full chart or one without text; use 'full' or 'no text'.
#' @param show.size.range show or hide the allele size range on top of the vertical line
#' @param show.horizontal.lines show or hide horizontal lines in the large layout
#' @param vertical.lines.width line width of vertical lines; default is 2
#' @param show.desc logical; show 'Description' box or not
#' @example inst/examples/rquipu.R
#' @import graphics
#' @import grDevices
#' @author Reinhard Simon, Pablo Carhuapoma
#' @aliases rquipu
#' @export
rquipu <-  function (data, #accession, marker, marker.size, map.location, 
            a.subset = c("all"),
            ylim = c(50,350), 
            res=c(1500,1200),
            dir.print = getwd(), #tempdir(),
            dir.logo = NA, 
            col.node = c("red3","green","blue","gray50"), 
            col.marg = c("gray60","black","black"), 
            species.name = NA, 
            set.name = NA,
            img.format = "png", #c("screen","jpeg","jpg","png"),
            ltr.size = 0.8,
            show.accs.total = TRUE,
            id.label = "Identifier",
            node.size = c(1.5, 1.2, 0.9, 0.6),
            grp.brks = c(0.01, 0.05, 0.1),
            obs.alls.frq = NULL,
            obs.alls.frq.ref = "dataset",
            layout=c("full", "no text"),
            show.size.range = TRUE,
            show.horizontal.lines = TRUE,
            vertical.lines.width = 2,
            show.desc = TRUE
)
  {
  
  grp.size = node.size
  col.fig = col.node
  assert(is.data.frame(data), "Data is not a data.frame")
  #assert(!any(is.na((data))), "Data has NAs.")
  
  if(!is.null(attr(data, which = "map"))){
    data = scores2list(data)
  }
  
  assert(all(names(data) %in% c("accession_id", "primer_name","marker_size","map_location")),
         "The data.frame does not contain the expected column names (see documentation).")
  assert(nrow(data)>0,
         "The data.frame does not contain sufficient data.")
  
  stopifnot(all(is.vector(col.fig), is.character(col.fig), length(col.fig)==4))
  stopifnot(all(col.fig %in% colors()))
  
  stopifnot(all(is.vector(grp.brks), is.numeric(grp.brks), length(grp.brks)==3))
  stopifnot(all(grp.brks[1] > 0, grp.brks[2] > grp.brks[1], grp.brks[3] > grp.brks[2], 1>grp.brks[3] ) )
  
  stopifnot(all(is.vector(grp.size)))
  
  marker = NULL
  marker_size = NULL
  
  if(!is.null(obs.alls.frq)){
    stopifnot(all(class(obs.alls.frq)=="data.frame", 
                  names(obs.alls.frq) %in% c("marker", "marker_size", "frequency"))
              )
    stopifnot(all(is.numeric(obs.alls.frq$frequency), 
                  0 < min(obs.alls.frq$frequency), 
                  max(obs.alls.frq$frequency < 1) ))
  }
  if(is.null(obs.alls.frq)){
    obs.alls.frq <- get_obs_freq(data)
  }
  
 
  
    options(warn = -1)
      CLON = data$accession_id
      MARK = data$primer_name
      SIZE = data$marker_size
      CROMOS = data$map_location
  
  
   if(!("all" %in% a.subset))  {
     assert(is.vector(a.subset), 
            "The parameter 'a.subset' must be a vector.")
     assert(is.character(a.subset), 
            "The parameter 'a.subset' must be a vector of type 'character'.")
     ss = a.subset %in% data$accession_id
     mss= paste(a.subset[!ss],collapse=", ")
     # print(a.subset)
     # print(ss)
     # print(a.subset[!ss])
     if(!ss) return(NULL)
     assert(all(ss),paste("The dentifier(s): '",mss,"' is/are not in the database.", sep=""))
   }
      
  # nn = unique(CLON)
  # shiny::withProgress(max = nn, {    
      
   dir=paste("In the folder ", dir.print, sep="")
   dat=data.frame(CIP.number=CLON, primer_name_original=MARK, Marker.size=SIZE, Cromosomas=CROMOS)
   
   ## sorting the data by level of chromosome
   dt2=data.frame(rm1=c("I","II","III","IV","V","VI","VII","VIII","IX","X","XI",
                        "XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX",
                        "XXI", "XXII", "XXIII", "XIV", "XV"),
                  valor=1:25)
   datos=data.frame(dat,rep("unknw",nrow(dat)))
   dt2=as.matrix(dt2)
   datos=as.matrix(datos)
   # print(str(datos))
   # print(str(dt2))
   for(i in 1:nrow(dat))
   { 
     for(j in 1:nrow(dt2))
     {
       # print(i)
       # print(j)
       # print(datos[i, 4])
       # print(dt2[j, 1])
       if(datos[i,4]==dt2[j,1]){datos[i,5]=dt2[j,2]}
     }
   }
   datos=data.frame(datos)
   dat=dat[order(datos[,5], datos[,2],datos[,3]),]
   
  
   datt=data.frame(dat,peso=rep(0,nrow(dat)),color=rep(0,nrow(dat)))
   
   # Calculate allele frequency by locus or primer pair
   alls = paste(dat$primer_name ,dat$Marker.size,sep=".")
   alls.fr=table(alls)
   alls.to=table(dat$primer_name)
   
   up = unique(dat$primer_name)
   for(a in 1:length(up) ){
     pn = as.character(up[a])
     alls.fr[stringr::str_detect(names(alls.fr),pn)]= 
       alls.fr[stringr::str_detect(names(alls.fr),pn)]/alls.to[[pn]]
   }

   alls.range=NULL
   if(!is.null(obs.alls.frq)){
     Alleles = paste(obs.alls.frq$marker, obs.alls.frq$marker_size, sep=".")
     obs.fr = cbind(Alleles, obs.alls.frq$frequency)
     row.names(obs.fr) = Alleles
     ofr = table(obs.fr[,1])
     ofr = obs.fr[,2]
     
     assert(all(names(alls.fr) %in% names(ofr)),
            paste( 
              paste(names(alls.fr)[!(names(alls.fr) %in% names(ofr))],collapse=", "), 
              "is/are missing in your reference file of allele frequencies." )
            )
     alls.fr = ofr
     # alls.range = tapply.stat(obs.alls.frq[,"marker_size"], obs.alls.frq[,"marker"], min)
     # alls.range = cbind(alls.range,
     #                    tapply.stat(obs.alls.frq[,"marker_size"], obs.alls.frq[,"marker"], max)[2])
     
     # alls.range = obs.alls.frq[, c(1, 2)] %>% group_by(marker) %>% summarise(min(marker_size), max(marker_size))
     
     alls.range = obs.alls.frq[, c(1, 2)] 
     alls.range = dplyr::group_by(alls.range, marker) 
     alls.range = dplyr::summarise(alls.range, min(marker_size), max(marker_size))
     
     names(alls.range) = c("Marker","min","max") # Marker -> Primer
   }


   #print(str(alls.fr))
   for(r in 1:nrow(datt)){
     #print(str(datt))
     an = paste(datt$primer_name_original[r],datt$Marker.size[r],sep=".")
     #print(an)
     ra = as.numeric(alls.fr[[an]])
     
     if(ra<  (grp.brks[1]))                    {datt[r,5]=grp.size[1]; datt[r,6]=col.fig[1]}
     if(ra>= (grp.brks[1]) & ra< (grp.brks[2])){datt[r,5]=grp.size[2]; datt[r,6]=col.fig[2]}
     if(ra>= (grp.brks[2]) & ra< (grp.brks[3])){datt[r,5]=grp.size[3]; datt[r,6]=col.fig[3]}
     if(ra>= (grp.brks[3]))                    {datt[r,5]=grp.size[4]; datt[r,6]=col.fig[4]}
     #print(paste(r, ra, datt[r,5],sep=" "))
   }
   
   ## Graphic
   x = NA
   if(!is.na(dir.logo)){
     if(file.exists(dir.logo)){
     x <- pixmap::read.pnm(dir.logo) # reading the logo  
   }
   }
   
   if(a.subset != "all"){
     datt = datt[datt$CIP.number %in% a.subset, ]
   }

   
   clones=unique(datt$CIP.number)
   #nameclones1=paste("CIP",unique(datt$CIP.number))
   nameclones1=paste(unique(datt$CIP.number))
   nameclones=paste(nameclones1,"                          ", sep="")
   
   if(img.format %in% c("jpeg","jpg")) nameclones2=file.path(dir.print, paste(nameclones1,".jpg", sep=""))
   if(img.format=="png")  nameclones2=file.path(dir.print, paste(nameclones1,".png", sep=""))
   
   #mrcs=unique(datt$primer_name_original)
   mrcs=unique(dat$primer_name_original) 
   #print(mrcs)
   
   for(j in 1:length(clones))
   {
     #incProgress(amount = 1)
     grup1=datt[datt$CIP.number==clones[j],]
     #mrcs=unique(grup1$primer_name_original) 
     
     
     ## print image 
     if(img.format %in% c("jpeg","jpg")) jpeg(nameclones2[j],quality = 100,width = res[1], height = res[2],pointsize = 22)
     if(img.format=="png") png(nameclones2[j],width = res[1], height = res[2],pointsize = 22)
     if(layout=="full"){
       layout_large_plot(mrcs, grup1, ltr.size, id.label, nameclones, j, ylim, col.marg, 
                         show.horizontal.lines, show.desc)
       draw_legend(j, mrcs, ylim, grp.brks, col.fig, grp.size, ltr.size, img.format, nameclones2, species.name,
                        set.name, clones, show.accs.total, x, obs.alls.frq.ref, show_desc = show.desc)       
     } else {
       layout_small_plot(mrcs, grup1, ltr.size, id.label, nameclones, j, ylim, col.marg)
     }
     
     draw_vertical_lines(mrcs, datt, ylim, obs.alls.frq, alls.range, layout, 
                         vertical.lines.width,
                         show.size.range)
     draw_nodes(mrcs, grup1, datt, ylim, ltr.size, dat )
     
     if(img.format != "screen" ) dev.off()
   }
  #}, message = "Creating images.")
  options(warn=1)
  
}

#' Run a short interactive demo
#' 
#' Shows the two typical plots and the effects of the main parameters.
#' 
#' @aliases runDemo
#' @author Reinhard Simon
#' @example inst/examples/ex_runDemo.R
#' @export
#' 
runDemo <- function() {
  shiny::runApp(system.file("shiny", package = "quipu"))
}
