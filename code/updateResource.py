## Simple script to update a resource in HDX / CKAN.

import ckanapi as ckan
import datetime as dt

def getOldResourceProperties(resource_id, key):

        # Basic definitions of the remote CKAN instance.
        hdx = ckan.RemoteCKAN('https://data.hdx.rwlabs.org/',
                apikey=key,
        user_agent='ckanapiexample/1.0')

        try:
                print('Updating resource.\n')
                current_time = dt.datetime.now().time()
                t = "Updated at: " + str(current_time)
                hdx.action.resource_update(id = resource_id,
                        description = t,
                        url = 'http://ds-ec2.scraperwiki.com/bdiq9rh/jl6of3vhfzl38tg/http/output.zip')  # CPS doesn't like httpS

        except ckan.errors.ValidationError:
                print 'You have missing parameters. Check the url and type are included.\n'

        except ckan.errors.NotFound:
                print 'Resource not found!\n'

# Running the function
getOldResourceProperties(resource_id = 'bb46ce84-717d-468f-9f5a-f44b90fb362c', key = 'you_key_here')