## Simple script to update a resource in HDX / CKAN.
## Designed to run on the staging version of HDX.
# 6ca6ddbe-574e-4e4e-9d78-95ca1ceec08b

# Resource update not working.
# Try deleting a resource and then
# creating a new one.

import requests

# Function to collect old properties
def getOldResourceProperties(id):
	url = 'https://test-data.hdx.rwlabs.org/api/action/resource_show?id=' + id
	r = requests.get(url, auth=('dataproject', 'humdata'))
	doc = r.json()
	output = doc["result"]
	return output

# Function to define new properties
def defineNewProperties(id, apiKey):
	# First, collect old properties.
	oldProperties = getOldResourceProperties(id = '53442451-a0e1-4a2d-a425-4173b85c769c')

	# Then update only the desired ones.
	url = 'https://test-data.hdx.rwlabs.org/api/action/resource_update?id=' + id
	h = {'Authorization': apiKey}
	r = requests.post(url, data=oldProperties, headers=h, auth=('dataproject', 'humdata'))

	if r.status_code == 200:
		print 'Success!\n'
	else:
		print 'Fail!\n'
		print r.json()
		print oldProperties


# Calling the functions
defineNewProperties('53442451-a0e1-4a2d-a425-4173b85c769c', 'a6863277-f35e-4f50-af85-78a2d9ebcdd3')