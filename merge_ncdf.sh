#!/bin/bash

# Nome del file output concatenato
output_file="concatenated.nc"

# Controlla se ci sono file .nc nella directory corrente
nc_files=( *.nc )
if [ ${#nc_files[@]} -eq 0 ]; then
  echo "Nessun file .nc trovato nella directory corrente."
  exit 1
fi

# Aggiungi una dimensione illimitata "time" se non esiste già
for file in "${nc_files[@]}"; do
  ncks --mk_rec_dmn time "$file" -O "$file.tmp" && mv "$file.tmp" "$file"
  if [ $? -ne 0 ]; then
    echo "Errore durante la conversione del file $file"
    exit 1
  fi
done

# Usa ncrcat per concatenare i file .nc
ncrcat -O "${nc_files[@]}" "$output_file"

# Controlla se l'operazione è riuscita
if [ $? -eq 0 ]; then
  echo "Tutti i file .nc sono stati concatenati con successo in $output_file."
else
  echo "Errore durante la concatenazione dei file .nc."
  exit 1
fi
