## Bunting Movements in Mexico



```r
library(RSQLite)
library(lattice)
```

```
## Warning: package 'lattice' was built under R version 3.0.1
```

```r
library(ggplot2)
library(maptools)
```

```
## Warning: package 'maptools' was built under R version 3.0.1
## Warning: package 'sp' was built under R version 3.0.1
```

```r
g <- readShapePoly("data/grid.shp")
b <- readShapeLines("data/ne_10m_admin_1_states_provinces_shp.shp")
p <- readShapePoints("data/buntings.shp")
mx <- subset(b, ISO == "MEX")
# source('plot_buntings.R')
```



## DB Connection 
Make connections to database file.



Specimin collections over time:

```r
# clean up columns that aren't 4 digit years
oyrs <- dbGetQuery(con, "select cast(ANYO_COL as integer) as year, count(cast(ANYO_COL as integer)) as count from other where cast(ANYO_COL as integer) >= 1820 and cast(ANYO_COL as integer) <= 2020 group by ANYO_COL")
oyrs$type <- "others"
byrs <- dbGetQuery(con, "select cast(anyo_col as integer) as year, count(cast(anyo_col as integer)) as count from buntings where cast(anyo_col as integer) >= 1820 and cast(anyo_col as integer) <= 2020 group by anyo_col")
byrs$type <- "Passerina ciris"
yrs <- rbind(oyrs, byrs)

ggplot(yrs, aes(x = factor(year), y = count)) + geom_bar() + facet_wrap(~type, 
    scales = "free") + coord_flip()
```

```
## Warning: Removed 16 rows containing missing values (position_stack).
## Warning: position_stack requires constant width: output may be incorrect
```

```
## Error: ggplot2 does not currently support free scales with a non-cartesian coord or coord_flip.
```




```r
ocnt <- dbGetQuery(con, "select cast(MES_COL as integer) as month, count(MES_COL) as count from other where cast(MES_COL as integer) > 0 and cast(MES_COL as integer) < 13 group by MES_COL")
ocnt$type <- "other"
bcnt <- dbGetQuery(con, "select cast(mes_col as integer)as month, count(mes_col) as count from buntings where cast(mes_col as integer) > 0 and cast(mes_col as integer) < 13 group by mes_col")
bcnt$type <- "Passerina ciris"
cnts <- rbind(bcnt, ocnt)
ggplot(cnts, aes(x = month, y = count, xlab = "Month")) + opts(title = "Number of Painted Bunting Specimins compared to other specimins for each month") + 
    geom_line() + scale_x_continuous(name = "Month") + scale_y_continuous(name = "Specimins") + 
    facet_wrap(~type, scales = "free")
```

```
## 'opts' is deprecated. Use 'theme' instead. (Deprecated; last used in version 0.9.1)
## Setting the plot title with opts(title="...") is deprecated.
##  Use labs(title="...") or ggtitle("...") instead. (Deprecated; last used in version 0.9.1)
```

![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4.png) 




```r
plot(mx)
```

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5.png) 


Grass analysis of average EVI 2001 - 2011:

```{}
  # Create binary raster with upper quartile of average EVI from each monthly average.
  for m in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do 
      eval $(r.univar -eg MOD13A3_${m}_avg@MOD13A3); 
      r.mapcalc MOD13A3_${m}_upperquartile="if(MOD13A3_${m}_avg@MOD13A3 > ${third_quartile}, 1, null())";
  done
  # apply gray color and export
  for i in $(g.mlist -r pat=MOD13A3_..._upperquartile); do 
    echo "1 gray" | r.colors ${i} rules=-; 
    r.out.gdal input=${i} output=${i}.tif
  done
```
