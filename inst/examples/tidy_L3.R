#' summarize ocean colour from L3 bins
#' raadsync produces daily tibbles of Johnson/NASA chlophyll from L3-bins
#' here we focus on a specific region, specific months
#'  load up all values, compute statistics for mean/variance/n grouped by
#'   month, unique bin (L3 bins, MODISA)
#'  
library(raadtools)
library(roc)
library(tibble)  ## better than data.frame, do it
library(dplyr)
files <- chla_johnsonfiles() %>% dplyr::filter(format(date, "%m") %in% c("12", "01", "02"))
xlim <- c(70, 100)
ylim <- c(-70, -45)
NROWS <- 4320
domain_raster <- raster(extent(xlim, ylim), crs = "+init=epsg:4326" )
init <- initbin(NUMROWS = NROWS)
rowbins <- seq(init$basebin[findInterval(ylim[1], init$latbin)], 
               init$basebin[findInterval(ylim[2], init$latbin) + 1])
xybin <- as_tibble(bin2lonlat(rowbins,
                  nrows = NROWS)) %>%
       dplyr::mutate(bin_num = rowbins) %>% 
  dplyr::filter(x >= xlim[1], x <= xlim[2])

bins0 <- dplyr::select(xybin, "bin_num")
## statistical functions to summarize, so we can later
## compute variance (not just mean/n)
funs <- list(sum = sum, ssq = function(x) sum(x^2), n = length)
x <- purrr::map(files$fullname, 
           function(ifile) {readRDS(ifile) %>% inner_join(bins0, "bin_num")}
) %>% dplyr::bind_rows() %>% 
  mutate(month = format(date, "%B")) %>% 
 ## group by bin_number and month                                  
    group_by(bin_num, month) %>% 
  summarize_if(purrr::is_bare_numeric, funs)



## statistical functions to summarize, so we can later
## compute variance (not just mean/n)
funs <- list(sum = sum, ssq = function(x) sum(x^2), n = length)

# %>% 
#  mutate(month = format(date, "%B")) %>% 
 ## group by bin_number and month                                  
#    group_by(bin_num, month) %>% 
#  summarize_if(purrr::is_bare_numeric, funs)


library(ggplot2)
x[c("x", "y")] <- bin2lonlat(x$bin_num, NROWS)
ggplot(x, aes(x, y, colour = chla_johnson_sum/chla_johnson_n)) + 
  geom_point(pch = ".") + facet_wrap(~month)

