###
#Step 2 Load environmental covariates and extract data to study sites

#Tania Valdivia Carrillo

#Environmental layers (.tif) were obtained from MARSPEC (using sdmpredictors package) and COPERNICUS (https://data.marine.copernicus.eu/product/GLOBAL_ANALYSISFORECAST_PHY_001_024/description)
#repositories to extract the environmental information for each sampling location in our metadata file. To achieve this, we homogenized the extent of all layers using the shapefile in the ./downloaded_predictors/shp/
#folder. All the processed layers are contained in the ./downloaded-predictors/ folder and are ready to be used in the Step2_Get_environmental_layers.R.

#Install packages
list.of.packages=c("raster", "rgdal", "dplyr")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, dependencies = T)

library(librarian)

librarian::shelf(list.of.packages)
source('custom_functions.R')

#remotes::install_github("michaeldorman/geobgu", force = TRUE)
library("geobgu")
###

#IMPORTANT: Set the working directory to the main folder where this repository is located on your disk.

####Load predictors from downloaded_predictors folder.

# Surface data, resolution 0.083x0.083, date: 08/2019

#BioOracle
bathy_083<-raster('./downloaded_predictors/bathy.tif')
dist_shore_083<-raster('./downloaded_predictors/dist_shore.tif')
slope_083<-raster('./downloaded_predictors/slope.tif')
#COPERNICUS LAYERS
ESV_surface_083_082019<-raster('./downloaded_predictors/ESV.tif')
epi_surface_083_022019<-raster('./downloaded_predictors/epi.tif')
lmeso_surface_083_022019<-raster('./downloaded_predictors/lmeso.tif')
umeso_surface_083_022019<-raster('./downloaded_predictors/umeso.tif')
zooc_surface_083_022019<-raster('./downloaded_predictors/zooc.tif')
zeu_surface_083_022019<-raster('./downloaded_predictors/zeu.tif')
npp_surface_083_082019<-raster('./downloaded_predictors/npp.tif')
NWV_surface_083_082019<-raster('./downloaded_predictors/NWV.tif')
OML_surface_083_082019<-raster('./downloaded_predictors/OML.tif')
pelagicL_depth_surface_083_082019<-raster('./downloaded_predictors/pelagicL_depth.tif')
SSH_surface_083_082019<-raster('./downloaded_predictors/SSH.tif')
SWS_surface_083_082019<-raster('./downloaded_predictors/SWS.tif')
SWT_surface_083_082019<-raster('./downloaded_predictors/SWT.tif')

#Extract latitude and longitude
lat_083 <- lon_083 <- SWT_surface_083_082019
xy_083 <- coordinates(SWT_surface_083_082019)
lon_083[] <- xy_083[, 1]
lat_083[] <- xy_083[, 2]
plot(lat_083)

#Create a raster brick
envCov_USA_surface_083_082019<-raster::brick(bathy_083,slope_083,dist_shore_083,ESV_surface_083_082019,npp_surface_083_082019,
                                             NWV_surface_083_082019,OML_surface_083_082019,pelagicL_depth_surface_083_082019,
                                             SSH_surface_083_082019,SWS_surface_083_082019,epi_surface_083_022019,lmeso_surface_083_022019,
                                             umeso_surface_083_022019,zooc_surface_083_022019,zeu_surface_083_022019,
                                             SWT_surface_083_082019,lon_083,lat_083)

names(envCov_USA_surface_083_082019)
names(envCov_USA_surface_083_082019)[4]<-"ESV"
names(envCov_USA_surface_083_082019)[5]<-"npp"
names(envCov_USA_surface_083_082019)[6]<-"NWV"
names(envCov_USA_surface_083_082019)[8]<-"pelagicL_depth"
names(envCov_USA_surface_083_082019)[10]<-"SWS"
names(envCov_USA_surface_083_082019)[11]<-"epi"
names(envCov_USA_surface_083_082019)[12]<-"lmeso"
names(envCov_USA_surface_083_082019)[13]<-"umeso"
names(envCov_USA_surface_083_082019)[14]<-"zooc"
names(envCov_USA_surface_083_082019)[15]<-"zeu"
names(envCov_USA_surface_083_082019)[16]<-"SWT"
names(envCov_USA_surface_083_082019)[17]<-"lon"
names(envCov_USA_surface_083_082019)[18]<-"lat"
plot(envCov_USA_surface_083_082019)

#Mask to WA coast
WA_short<- readOGR("./downloaded_predictors/shp/Mask_WA_Coast_short_B.shp")

envCov_spol_surface_083_082019 <- raster::mask(envCov_USA_surface_083_082019, WA_short,updateNA=TRUE)

plot(envCov_spol_surface_083_082019)

# writeRaster(envCov_USA_surface_083_082019,"./downloaded_predictors/envCov_USA_surface_083_082019.tif", options="INTERLEAVE=BAND",overwrite = TRUE)
# writeRaster(envCov_spol_surface_083_082019,"./downloaded_predictors/envCov_spol_surface_083_082019.tif", options="INTERLEAVE=BAND",overwrite = TRUE)

envCov_spol_surface_083_082019_df <- as.data.frame(envCov_spol_surface_083_082019, xy = TRUE)

(p <- ggplot() +
    geom_raster(data = envCov_spol_surface_083_082019_df, aes(x = x, y = y, fill = bathy)) +
    scale_fill_viridis_c() +
    coord_quickmap() +
    theme(legend.key.width = unit(1, "cm"), 
          legend.key.height = unit(1, "cm"), 
          legend.text = element_text(size = 10),
          legend.title = element_text(size = 10),
          plot.title = element_text(size = 16))+
    labs(title = "Bathymetry"))
#ggsave(".png", plot = p, width = 8, height = 6, units = "in", dpi = 300)

#Extract the environmental information on the metadata file

#Extract env_info per coordinate
#coordinates(coord) <-c("lon", "lat")
# md.taxa.long.formated<-read.csv("./dataframes/md_taxa_long_formated.csv") #ordered by latitude 
coord <- md.taxa.long[,c(24,23)] # Order must be lon lat
envCov_surface_083_df<-raster::extract(envCov_spol_surface_083_082019,coord,df=TRUE) %>% 
  select(!c(lat,lon))

md.taxa.long.formated.env083<-bind_cols(md.taxa.long,envCov_surface_083_df) 

md.taxa.long.formated.env083.uniq<-md.taxa.long.formated.env083 %>% 
  separate(sampleID_station, into = c("sampleID", "station"), sep = "_", remove = FALSE) %>% 
  mutate(Presence = ifelse(sum_occurrence >= 1, 1, 0)) %>% 
  relocate(`Presence`,.after=`prob_detection`) %>% 
  group_by(lat, lon, species) %>%
  filter(Presence == max(Presence)) %>%
  slice_head() %>%
  ungroup()
  
write.csv(envCov_surface_083_df, "./dataframes/envCov_surface_083_df.csv")
write.csv(md.taxa.long.formated.env083, "./dataframes/md_taxa_long_formated_env083.csv")


