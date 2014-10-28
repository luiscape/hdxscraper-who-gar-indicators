## Simple script to update a resource in HDX / CKAN
import requests

r = requests.get('test-data.hdx.rwlabs.org', auth=('dataproject', 'humdata'))

print(r)