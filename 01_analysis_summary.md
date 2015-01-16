### Buntings data

Excel spreadsheet tabs were converted to shapefiles using QGIS GUI to assign lat and lon columns, then exported as shapefiles. Subsequently the shapefiles were all imported into a single sqlite database for further analysis. All R scripts get plot data from this sqlite database.

The `mxgrid` shapefile was created in an arbitrarily selected GRASS GIS region set to 1-degree tile steps and exported to shapefile.

## Importing shapefiles to sqlite

Import shapefiles:

    spatialite_tool -i -shp Downloads/buntings -d buntings.sqlite -t buntings -c utf-8 -s 4326 -2 -k
    spatialite_tool -i -shp Downloads/others -d buntings.sqlite -t other -c utf-8 -s 4326 -2 -k
    spatialite_tool -i -shp Downloads/mxgrid -d buntings.sqlite -t mxgrid -c utf-8 -s 4326 -2 -k

Then create spatial indices:

    create index indx_other on other(Geometry);
    create index indx_buntings on buntings(Geometry);
    create index indx_mxgrid on mxgrid(Geometry);


* Other is other similar birds observed (excluding painted buntings).
* buntings is just painted bunting observations.
* mxgrid is a 1-degree grid over mexico

These data were imported from excel spreadsheets and spatially querried to include only data points inside of Mexico.  No effort was made to move other outlier datapoints which were obviously erroneous into Mexico.

## Resulting tables

We now have sqlite tables for `buntings`, `other` and `mxgrid`. Summaries of the top 10 lines of the pertinent columns of those tables are below.

## Bunting observations

```
  sqlite> select PK_UID, MES_COL, LATITUD, LONGITUD from buntings limit 10;
  PK_UID      MES_COL     LATITUD      LONGITUD
  ----------  ----------  -----------  ------------
  1           12          20.91666667  -104.4833333
  2           8           26.21666667  -102.8666667
  3           3           22.83166667  -105.7766667
  4           11          16.16833333  -97.1
  5           3           17.10833333  -95.03333333
  6           1           18.76666667  -96.86666667
  7           11          22.83166667  -105.7766667
  8           4           22.36        -105.5383333
  9           10          22.83166667  -105.7766667
  10          10          20.665       -103.3133333
```

### Total lines

```
  sqlite> select count(*) from buntings;
  count(*)
  ----------
  1356
```

## Other species:

### Top 10 lines of the table:

```
  sqlite> select PK_UID, MES_COL, LATITUD, LONGITUD from other limit 10;
  PK_UID      MES_COL     LATITUD     LONGITUD
  ----------  ----------  ----------  ----------
  1                       18.665      -99.4883
  2           4           26.8817     -113.145
  3           7           23.45       -110.217
  4           5           18.46       -97.39
  5           3           19.265      -101.603
  6           7           17.6833     -97.6
  7           2           20.0333     -103.565
  8           1           19.1633     -102.287
  9           5           18.9233     -99.1517
  10          5           18.8833     -96.9333
```

### Total Count

```
  sqlite> select count(*) from other;
  count(*)
  ----------
  251409
```

## Empty grid:

```
  sqlite> select * from mxgrid limit 10;
  PK_UID      ID          XMIN           XMAX           YMIN           YMAX           Geometry
  ----------  ----------  -------------  -------------  -------------  -------------  ----------
  1           0           -119.91919135  -118.91919135  37.2937583173  38.2937583173
  2           1           -118.91919135  -117.91919135  37.2937583173  38.2937583173
  3           2           -117.91919135  -116.91919135  37.2937583173  38.2937583173
  4           3           -116.91919135  -115.91919135  37.2937583173  38.2937583173
  5           4           -115.91919135  -114.91919135  37.2937583173  38.2937583173
  6           5           -114.91919135  -113.91919135  37.2937583173  38.2937583173
  7           6           -113.91919135  -112.91919135  37.2937583173  38.2937583173
  8           7           -112.91919135  -111.91919135  37.2937583173  38.2937583173
  9           8           -111.91919135  -110.91919135  37.2937583173  38.2937583173
  10          9           -110.91919135  -109.91919135  37.2937583173  38.2937583173
```

## QA/QC

Before scripting in R, QA/QC were done to understand which data would be valid for plotting in R. No data are dropped or deleted, the R script is just programmed to run over the rows with valid collection months (MES_COL) 1-12.

other summary:

```
    select count(*) from other;
    count(*)
    ----------
    251409
```

```
    select mes_col, count(mes_col) from other group by mes_col;
    MES_COL     count
    ----------  ----------
                1999
    0           1
    1           18118
    10          15483
    11          17091
    12          15509
    2           20466
    20          1
    3           26943
    4           30277
    5           28839
    6           22557
    7           20004
    8           16429
    9           13057
    99          4635
```

If we're going to be using months to understand seasonality, we should probably not use records that have no month ~6636 records.

buntings summary:

```
    select count(*) from buntings;
    count(*)
    ----------
    1356
```

```
    select mes_col, count(mes_col) as count from buntings group by mes_col;
    MES_COL     count(mes_col)
    ----------  --------------
    0           15
    1           155
    2           130
    3           219
    4           142
    5           50
    6           11
    7           87
    8           120
    9           111
    10          84
    11          88
    12          121
    99          23
```

Here we also have 38 records with no accurate month.

## Perform Join on grid and point observations:

Now we'll perform a query which joins the two point data sets to the grid. The data set we get out can be thought of as a shapefile with summary statistics for each grid cell based on the number of underlying points in each of the `buntings` and `other` categories contained by that grid cell.

```
    create table buntings_month_grid as select grid.pk_uid as pk_uid,
     point.mes_col as mes_col, count(mes_col) as buntings
     from
     mxgrid as grid,
     buntings as point where Contains(grid.Geometry, point.Geometry)
      group by grid.pk_uid, mes_col;
    create table other_month_grid as
      select grid.pk_uid as pk_uid, point.mes_col as mes_col,
      count(mes_col) as other from mxgrid as grid, other as point where
       Contains(grid.Geometry, point.Geometry) group by grid.pk_uid, mes_col;

```
    create table bunting_abund_grid as
        select g.pk_uid as pk_uid, m.mes_col, g.id as id,
        g.geometry as Geometry, oj.mes_col as mes_col,
        cast(buntings as real) as buntings,
        cast(other as real) as other,
        cast(cast(buntings as rea)/(cast(other as real) +
        cast(buntings as real)) as real) as abund
    from
        mxgrid as g, (select distinct mes_col from buntings_month_grid) as m
    left join buntings_month_grid as bj
        on bj.pk_uid = g.pk_uid and bj.mes_col = m.mes_col
    left join other_month_grid as oj
        on oj.pk_uid = g.pk_uid and oj.mes_col = m.mes_col
    group by g.pk_uid, g.id, oj.mes_col;
```
 
