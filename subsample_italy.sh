#!/bin/bash

# File di input e output
input_file="fg_ens_mean_0.1deg_reg_2011-2023_v28.0e.nc"
output_file="fg_ens_mean_0.1deg_reg_2011-2023_v28.0e_IT.nc"

# Limiti del dominio italiano
lon_min=6
lon_max=19
lat_min=36
lat_max=47

# Estrai i valori delle coordinate
ncdump -v latitude $input_file | grep -o '[-]*[0-9]\+\.[0-9]\+' > latitudes.txt
ncdump -v longitude $input_file | grep -o '[-]*[0-9]\+\.[0-9]\+' > longitudes.txt

# Funzione per trovare l'indice più vicino
find_index() {
  local value=$1
  local file=$2
  local min_diff=99999
  local index=0
  local counter=0
  while IFS= read -r line; do
    diff=$(echo "$line-$value" | bc | tr -d '-')
    if (( $(echo "$diff < $min_diff" | bc -l) )); then
      min_diff=$diff
      index=$counter
    fi
    counter=$((counter + 1))
  done < "$file"
  echo $index
}

# Trova gli indici corrispondenti
lat_start=$(find_index $lat_min latitudes.txt)
lat_end=$(find_index $lat_max latitudes.txt)
lon_start=$(find_index $lon_min longitudes.txt)
lon_end=$(find_index $lon_max longitudes.txt)

# Rimuovi i file temporanei
rm latitudes.txt longitudes.txt

# Sottocampionamento delle variabili nel dominio specificato
ncks -v time,latitude,longitude,fg -d longitude,$lon_start,$lon_end -d latitude,$lat_start,$lat_end $input_file $output_file

echo "Sottocampionamento completato. File di output: $output_file"
