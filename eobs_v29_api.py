import cdsapi

c = cdsapi.Client()
key= '2548:a32dce56-b04a-42fc-8fc3-a972f94772ad', progress=True,retry_max=5)  
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
