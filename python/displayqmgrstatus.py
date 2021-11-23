import requests
from requests.auth import HTTPBasicAuth

user='mqadmin'
password='mqadmin'
url="https://18.130.221.119:9443/ibmmq/rest/v1/admin/qmgr"

response = requests.get(url=url,auth=(user,password),verify=False)
print('Response code',response.json())
print ('Testing python by AJ')
