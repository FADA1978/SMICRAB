import cdsapi

c = cdsapi.Client()

c.retrieve(
    'insitu-gridded-observations-europe',
    {
        'product_type': 'ensemble_mean',
        'variable': [
            'relative_humidity', 'wind_speed',
        ],
        'grid_resolution': '0.1deg',
        'period': '2011_2023',
        'version': '28.0e',
        'format': 'tgz',
    },
    'download.tar.gz')
