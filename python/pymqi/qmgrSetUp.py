import logging
import pymqi

# Logging to change authrecs
logging.basicConfig(level=logging.INFO)

# QMGR objects info
queue_manager = "QM1"
host = "127.0.0.1"
port = '2020'
channel = "CHNL.ARTEM"
queue_name = "Q1"
conn_info = '%s(%s)' % (host, port)
user = 'sender'
password = 'sender'

# Defining a channel
channel_name = 'CHNL.PYTHON'
channel_type = pymqi.CMQXC.MQCHT_SVRCONN

chnl_args = {
    pymqi.CMQCFC.MQCACH_CHANNEL_NAME: channel_name,
    pymqi.CMQCFC.MQIACH_CHANNEL_TYPE: channel_type
}

# Defining a queue
queue_name = 'Q_PYTHON'
queue_type = pymqi.CMQC.MQQT_LOCAL
max_depth = 120

queue_args = {
    pymqi.CMQC.MQCA_Q_NAME: queue_name,
    pymqi.CMQC.MQIA_Q_TYPE: queue_type,
    pymqi.CMQC.MQIA_MAX_Q_DEPTH: max_depth
}

# Setting authority records
profile_name = [b'QM1']
auth_entity = [
    pymqi.CMQCFC.MQAUTH_BROWSE,
    pymqi.CMQCFC.MQAUTH_INQUIRE
]

auth_args = {
    pymqi.CMQCFC.MQCACF_AUTH_PROFILE_NAME: 'Q1',
    pymqi.CMQCFC.MQIACF_OBJECT_TYPE: pymqi.CMQC.MQOT_Q,
    pymqi.CMQCFC.MQIACF_AUTH_ADD_AUTHS: auth_entity,
    pymqi.CMQCFC.MQCACF_AUTH_PROFILE_NAME: profile_name
}

# Creating connection and setting execution
qmgr = pymqi.connect(queue_manager, channel, conn_info, user, password)
pcf = pymqi.PCFExecute(qmgr)
# Creating objects
pcf.MQCMD_CREATE_CHANNEL(chnl_args)
pcf.MQCMD_CREATE_Q(queue_args)

# Setting authrec
pcf.MQCMD_SET_AUTH_REC(auth_args)

qmgr.disconnect()
