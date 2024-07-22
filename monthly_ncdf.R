# 22-07-2024
# to aggregate daily data from eobs as monthly, with the monthly mean and the standard deviation of the mean in the aggregated files.
library(ncdf4)
library(lubridate)

# Funzione per leggere i dati dal file NetCDF
read_nc_file <- function(file_path) {
  nc <- nc_open(file_path)
  data <- list()
  
  data$lon <- ncvar_get(nc, "longitude")
  data$lat <- ncvar_get(nc, "latitude")
  data$time <- ncvar_get(nc, "time")
  
  # Identificare la variabile disponibile nel file
  variable_name <- setdiff(names(nc$var), c("longitude", "latitude", "time"))
  data$variable <- ncvar_get(nc, variable_name)
  data$variable_name <- variable_name
  
  nc_close(nc)
  return(data)
}

# Funzione per convertire il tempo in formato timestamp
convert_time <- function(time) {
  as.POSIXct(time * 86400, origin = "1950-01-01", tz = "UTC")
}

# Funzione per aggregare i dati mensilmente e calcolare la media e la deviazione standard
aggregate_monthly <- function(data) {
  time_dates <- convert_time(data$time)
  
  # Estraiamo anno e mese da ciascuna data
  year_month <- format(time_dates, "%Y-%m")
  
  # Troviamo tutti gli anni e mesi unici nel dataset
  unique_year_month <- sort(unique(year_month))
  
  # Inizializziamo array per le medie e le deviazioni standard
  mean_result <- array(NA_real_, dim = c(length(data$lon), length(data$lat), length(unique_year_month)))
  sd_result <- array(NA_real_, dim = c(length(data$lon), length(data$lat), length(unique_year_month)))

  for (i in seq_along(unique_year_month)) {
    # Troviamo gli indici delle osservazioni corrispondenti all'anno e mese corrente
    indices <- which(year_month == unique_year_month[i]) 
    # Calcoliamo media e deviazione standard per ogni punto della griglia
    monthly_data <- data$variable[,,indices]
    mean_result[,,i] <- apply(monthly_data, c(1, 2), mean, na.rm = TRUE)
    sd_result[,,i] <- apply(monthly_data, c(1, 2), sd, na.rm = TRUE)
    
  }
  return(list(year_months = unique_year_month, mean_result = mean_result, sd_result = sd_result))
}


# Funzione per scrivere i risultati in un nuovo file NetCDF
write_nc_file <- function(file_path, data, aggregated_data) {
  lon_dim <- ncdim_def("longitude", "degrees_east", data$lon)
  lat_dim <- ncdim_def("latitude", "degrees_north", data$lat)
  
  # Calcoliamo il numero di mesi nel dataset aggregato
  num_months <- length(aggregated_data$year_months)
  
  # Definiamo la dimensione del tempo come sequenza di mesi
  time_dim <- ncdim_def("time", "months since 2011-01-01", 1:num_months)
  
  mean_variable_def <- ncvar_def(paste0(data$variable_name, "_monthly_mean"), "unit", list(lon_dim, lat_dim, time_dim), missval = 1e20, longname = paste("Monthly Mean of", data$variable_name))
  sd_variable_def <- ncvar_def(paste0(data$variable_name, "_monthly_sd"), "unit", list(lon_dim, lat_dim, time_dim), missval = 1e20, longname = paste("Monthly Standard Deviation of", data$variable_name))
  
  nc <- nc_create(file_path, list(mean_variable_def, sd_variable_def), force_v4 = TRUE)
  
  # Scrivi i dati di media mensile
  print(dim(aggregated_data$mean_result))
  ncvar_put(nc, mean_variable_def, aggregated_data$mean_result)
  
  # Scrivi i dati di deviazione standard mensile
  print(dim(aggregated_data$sd_result))
  ncvar_put(nc, sd_variable_def, aggregated_data$sd_result)
  
  nc_close(nc)
}

# Directory dei file NetCDF di input
input_directory <- "/Users/fabiomadonna/Desktop/Cartelle/PROGETTI/PNRR/SMICRAB/dataset-insitu-gridded-observations/eobs"


# Leggi tutti i file NetCDF nella directory
nc_files <- list.files(input_directory, pattern = "\\.nc$", full.names = TRUE)

# Loop attraverso tutti i file e processarli
for (input_file in nc_files) {
  # Lettura dei dati dal file NetCDF
  data <- read_nc_file(input_file)
  # Aggregazione mensile e calcolo della media e deviazione standard
  aggregated_data <- aggregate_monthly(data)
  # Percorso del file NetCDF di output
  output_file <- sub("\\.nc$", paste0("_", data$variable_name, "_monthly_agg.nc"), input_file)
  # Scrittura dei risultati in un nuovo file NetCDF
  
  write_nc_file(output_file, data, aggregated_data)
}
