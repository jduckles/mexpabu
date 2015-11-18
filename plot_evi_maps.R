#Genreate EVI maps for each month with Painted Buntings specimen collection locations 
#and circles for each grid cell indicating the number of specimens.

# Enables split apply combine for each map across data
library(plyr)
# Sexy colors
library(RColorBrewer)
# Map data and tools
library(maptools)
# For color ramps
library(classInt)
# plot library
library(ggplot2)
# Vector wizardry
library(rgeos)
library(raster)
library(stringr)

#extent for all maps

ext <- extent(-125, -70, 10, 40)

# Grid was made in GRASS GIS mapset and exported
g <- readShapePoly("data/grid.shp", proj4string = CRS("+proj=longlat +datum=WGS84")) # load 1-degree grid

# NAs to zero for plotting purposes
g$other[ is.na(g$other) ] <- 0 # Set NAs to zero
g$buntings[ is.na(g$buntings) ] <- 0 # NAs to zero

# Bring in admin boundaries
b <- readShapeLines("data/ne_10m_admin_1_states_provinces_shp.shp", proj4string = CRS("+proj=longlat +datum=WGS84"))

# Read buntings shpfile
# Buntings shpfile creation method logged in Buntings.mkd
p <- readShapePoints("data/buntings.shp", proj4string = CRS("+proj=longlat +datum=WGS84"))

# Pull only data from MEXICO
mx <- subset(b, ISO == "MEX")
par(mar=c(0,0,0,0))

crp <- raster::crop(b,ext)

# Globals
## list of months
months <- c("January", "February", "March", "April", "May", "June", "July", "August","September","October","November","December")

# Function to draw monthly plots, month will be fed in by lapply() splits
#   on month.

ploteffort <- function(month,nclr=5) {
  effort <- g$buntings + g$other
  
  mapclass <- classIntervals(na.omit(effort), nclr, style="fisher")

  colpal <- brewer.pal(nclr,"Greys")
  monthdata <- subset(g, (mes_col == month) & (!is.na(mes_col)))
  pltclass <- classIntervals(monthdata$other, nclr, style="fixed", fixedBreaks=mapclass['brks']$brks)
  pcol <- findColours(pltclass, colpal, cutlabels=T)

  map <- raster(paste("EVI_maps_hires/EVI",str_pad(month, 2, pad = "0"),"clip.tif", sep = ""))
  map <- projectRaster(map,crs ="+proj=longlat +datum=WGS84")
  #get rid of negative values
  map <- calc(map,fun=function(x){ifelse(x < 0,NA,x)})
  map <- raster::crop(map, ext)
  tpos <- ifelse(month%%2, 0.7, 0.3) #odd and even months alternate positions
  pdf(sprintf('Figs/EVI_PABU%02d.pdf',month), width=10, height=5.5)
  #dev.print(sprintf('effort%02d.png',month)) 
    par(mar=c(5,5,2,4))
    plot(map, legend.width = 1.25, cex.axis = 2, cex.sub = 1.5, cex.lab = 1.6,
         xlim = c(ext[1],ext[2]), ylim = c(ext[3],ext[4]),
         xlab = 'Degrees longitude', ylab = 'Degrees latitude', cex.lab=2,
         legend.args=list(text='EVI', side=3, font=2, 
                          line=0.5, cex=2))
    #plot(monthdata, xlim=c(-119.0,-85.75), ylim=c(14.0, 32.74), col=pcol, border="gray", add = T)
    #plot(crp , col="dodgerblue3", add=T)
    bgcolor <- rgb(246,40,26,128, max=255)
    plot(gCentroid(subset(g,mes_col==month),byid=T), pch=21, col="darkgray", cex=sqrt(subset(g,mes_col == month)$abund)*15, bg=bgcolor, add=T)
    plot(subset(p, MES_COL == month), add=T, pch=20, col="blue", cex=0.5)
    #legend(-97,33, title="Collection effort\nSpecimins Collected", legend=names(attr(pcol,"table")), fill=attr(pcol,"palette"), cex = 2, bty = "n" )
    title(months[month], adj = tpos, cex.main = 2, line = -2)
  #dev.copy(pdf,file=sprintf('effort%02d.pdf',month));
  dev.off ()
}

lapply(seq(1,12), ploteffort)

