# https://localhost:9443/ibm/api/docs
# https://localhost:9443/ibm/api/explorer

# Creating a CSRF token
curl  -k https://localhost:9443/ibmmq/rest/v1/login -X POST -H "Content-Type: application/json; charset=UTF-8"  --data "{\"username\":\"mqadmin\",\"password\":\"mqadmin\"}" -c /home/artemobodovskyi/Desktop/Python/cookiejar.txt

#Creating a qmgr
curl -k https://localhost:9443/ibmmq/rest/v1/admin/qmgr/ -X POST -b /home/artemobodovskyi/Desktop/Python/cookiejar.txt -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"name\":\"QM2\"}"

# Creating a queue
curl -k https://localhost:9443/ibmmq/rest/v1/admin/qmgr/QM1/queue -X POST -b /home/artemobodovskyi/Desktop/Python/cookiejar.txt -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"name\":\"Q2\"}"

#Setting aurhority records
curl https://localhost:9443/ibmmq/rest/v1/admin/action/qmgr/QM1/mqsc -X POST -H "Content-Type: application/json" -d "{\"type\": \"runCommand\",\"parameters\": {\"command\": \"SET AUTHREC PROFILE(MAQ1) OBJTYPE(QUEUE) GROUP('sender') AUTHADD(BROWSE,INQ,PUT,GET)\"}}" -H "ibm-mq-rest-csrf-token: blank" -k -u mqadmin:mqadmin

#Deleting a queue
curl https://localhost:9443/ibmmq/rest/v1/admin/qmgr/QM1/queue/Q1 -X DELETE -H "ibm-mq-rest-csrf-token: blank" -k -u mqadmin:mqadmin


# Operations with messages
curl -i -k https://localhost:9443/ibmmq/rest/v1/messaging/qmgr/QM1/queue/Q1/message -X DELETE
-u mqadmin:mqadmin "ibm-mq-rest-csrf-token: /home/artemobodovskyi/Desktop/Python/cookiejar.txt"

curl -i -k https://localhost:9443/ibmmq/rest/v1/messaging/qmgr/QM1/queue/Q1/message -X POST 
-u user:password -H "ibm-mq-rest-csrf-token: /home/artemobodovskyi/Desktop/Python/cookiejar.txt" -H "Content-Type: text/plain;charset=utf-8" -d "Hello World!"

#Useful links:
# REST API resources: https://www.ibm.com/docs/en/ibm-mq/9.0?topic=reference-rest-api-resources