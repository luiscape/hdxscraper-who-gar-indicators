## Simple script to update a resource in HDX / CKAN.


import ckanapi as ckan

def getOldResourceProperties(resource_id, key):

	# Basic definitions of the remote CKAN instance.
	hdx = ckan.RemoteCKAN('https://data.hdx.rwlabs.org/',
		apikey=key,
    	user_agent='ckanapiexample/1.0')

	try:
		print('Updating resource.\n')
		hdx.action.resource_update(id = resource_id,
			url = 'coisaFeia')

	except ckan.errors.ValidationError:
		print 'You have missing parameters. Check the url and type are included.\n'

	except ckan.errors.NotFound:
		print 'Resource not found!\n'

# Running the function
getOldResourceProperties(resource_id = 'bb46ce84-717d-468f-9f5a-f44b90fb362c', key = 'your_api_key_here')
