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
library(stringr)
library(raster)
library(spatstat)
library(dismo)
library(adehabitatHR)
library(reshape2)
require(grid)

#extent for all maps

ext <- extent(-1750000,3500000,900000,4500000)
ext1 <- extent(-125, -70, 10, 40)

#empty lists for storing extracted EVI data
realdat <- list()
simdatmx <- list()

# Read buntings shpfile 
# Buntings shpfile creation method logged in Buntings.mkd
p <- readShapePoints("data/buntings.shp", proj4string = CRS("+proj=longlat +datum=WGS84"))

b <- readShapePoly("data/ne_10m_admin_1_states_provinces_shp.shp", proj4string = CRS("+proj=longlat +datum=WGS84"))
mx <- subset(b, NAME_0 == "Mexico")
mx <- gUnaryUnion(mx) #just the outline of mexico

for(month in 1:12){

  #Get the EVI map
  mappath <- paste("EVI_maps_hires/EVI", str_pad(month, 2, pad = "0"), "clip.tif", sep = "")
  map <- raster(mappath)
  #map <- raster::crop(map, ext1) #crop if needed.

  #plot(map)
  #plot(mx, add = T)

  points <- subset(p, MES_COL == month)

  #plot(points, add = T)
  #circs <- circles(points, d = 10000, n = 50)

  EVI <- extract(map, points@coords, buffer = 10000)
  #EVI <- extract(map, points@coords[1:5,], buffer = 10000)
  realdat[[month]] <- EVI
  
  cat('\r',month,".real")
  flush.console() 
  
  win1 <- as.owin(mx) #make mexico the window for random points
  simptsmx <- as.SpatialPoints.ppp(rpoint(500, win=win1))
  #simptsmx <- as.SpatialPoints.ppp(rpoint(5, win=win1))
  EVI <- extract(map, simptsmx, buffer = 10000)
  simdatmx[[month]] <- EVI
  
  cat('\r',month,".sim1")
  flush.console() 
}

save(realdat, simdatmx, simdatmcp, file="EVI_extractions")
load(file="EVI_extractions")


#how many pixels per location?
countpix <- function(x){
  return(sum(!is.na(x)))
}

alldat <- cbind(realdat, simdatmx)

max(rapply(realdat,countpix))
min(rapply(realdat,countpix))
mean(rapply(realdat,countpix))

max(rapply(simdatmx,countpix))
min(rapply(simdatmx,countpix))
mean(rapply(simdatmx,countpix))

max(rapply(alldat,countpix))
min(rapply(alldat,countpix))
mean(rapply(alldat,countpix))


#Get means for each specimen
avg.na <- function(x){
  return(mean(x, na.rm = T))
}

#Empty list for storing test results
lmx <- list()

for(k in 1:12){ #loop through each month
  
  #Get the means for each individual
  rmx <- unlist(lapply(simdatmx[[k]], FUN = avg.na))
  rreal <- unlist(lapply(realdat[[k]], FUN = avg.na))
  
  #do t-tests and add in standard deviations and 95% CIs
  n <- c(length(rreal), length(rmx)) #sample sizes (same for both mx and mcp)
  
  lmx[[k]] <- t.test(rreal, rmx) # the means
  lmx[[k]]$sd <- s <- c(sd(rreal), sd(rmx)) # the standard deviations
  lmx[[k]]$ci <- qt(0.975,df=n-1)*s/sqrt(n) # 95% CIs
}

tres = data.frame(month = c(1:12), mreal=rep(0,12), mmx=rep(0,12),
                   sdreal=rep(0,12), sdmx=rep(0,12),
                   cireal=rep(0,12), cimx=rep(0,12),
                   pmx =rep(0,12), tmx=rep(0,12))

for(l in 1:12){ #compile test results
  #m <- c(7,8,9,10,11,12,1,2,3,4,5,6)
  tres$month[l] <- l
  tres$mreal[l] <- lmx[[l]]$estimate[1]
  tres$mmx[l] <- lmx[[l]]$estimate[2]
  tres$sdreal[l] <- lmx[[l]]$sd[1]
  tres$sdmx[l] <- lmx[[l]]$sd[2]
  tres$cireal[l] <- lmx[[l]]$ci[1]
  tres$cimx[l] <- lmx[[l]]$ci[2]
  tres$pmx[l] <- lmx[[l]]$p.value
  tres$tmx[l] <- lmx[[l]]$parameter
}

tres1 <-melt(tres, id.vars="month")
tres2 <- tres1[1:24,]
tres2$sd <- tres1$value[25:48]
tres2$ci <- tres1$value[49:72]

ord <- c(7,8,9,10,11,12,1,2,3,4,5,6)
tres <- tres[ord,]

sigmx <- ifelse(tres$pmx<0.01,"*"," ")

#plot EVI scores with 95% CIs 
plot1 <- ggplot(tres2, aes(x=factor(month), y=value, fill=variable)) +
  theme_bw()+
  theme(axis.text=element_text(size=20),
        axis.title=element_text(size=25),
        legend.position=c(0.81, 0.87), 
        legend.title=element_text(size=25, face = "plain"),
        legend.text=element_text(size=20),
        legend.key.size = unit(.9, "cm"),
        legend.key = element_rect(colour = "black", size = 1),
        axis.title.y=element_text(vjust=1.5),
        axis.title.x=element_text(vjust=-0.5),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.line = element_line(size = 1),
        axis.ticks = element_line(size = 1),
        panel.border = element_blank(),
        panel.background = element_blank(),
        plot.margin=unit(c(4,4,4,4),"mm")) + 
  guides(fill = guide_legend(override.aes = list(colour = NULL)))+
  ylab("Mean EVI (±95% CI)")+
  geom_bar(position=position_dodge(), stat="identity", colour='black', width=.8) +
  geom_errorbar(aes(ymin=value-ci, ymax=value+ci), width=.2,position=position_dodge(.9))+
  scale_fill_manual("Location Type",labels = c("Specimen Data", "Simulation"), 
                    values=c("gray30", "gray90"))+
  scale_x_discrete("Month", limits=c(7,8,9,10,11,12,1,2,3,4,5,6), 
                   labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"))+
  coord_cartesian(ylim=c(2000,8000))+
  annotate("text",x=1:12,y=tres$mreal+150,label=sigmx)+
  annotate("text",x=1.7,y=7500,label="*p < 0.01", size=8)

#save the plot
ggsave(plot1, file="Figs/EVIfig.pdf")
ggsave(plot1, file="Figs/EVIfig.jpg", dpi = 300)
ggsave(plot1, file="Figs/EVIfig.png", dpi = 300)









