import requests
from requests.auth import HTTPDigestAuth
import json

print("Preparing to connect")
csf_token = "/home/artemobodovskyi/Desktop/Python/cookiejar.txt"
api_url = "https://localhost:9443/ibmmq/rest/v1/admin/qmgr/QM1/queue"

print("Setting a header")
headers = {
    "path": "https://localhost:9443/ibmmq/rest/v1/admin/qmgr/QM1/queue",
    "method": "POST",
    "host": "localhost",
    "port": "9443",
    "Authorization": "/home/artemobodovskyi/Desktop/Python/cookiejar.txt",
    "Content-Type": "application/json;charset=utf-8"
}
# print(headers)

queue = {"{\"name\":\"Q2\"}"}

print("Trying to make a POST call")
# try:
response = requests.post(
url=api_url,
headers=headers,
auth=('mqadmin', 'mqadmin'),
data=queue,
verify=False
)
print("Response code: {response.status_code}")
response.json()
# except requests.exceptions.ConnectionError:
# print("Connection refused")
