import pymqi

queue_manager = "QM1"
channel="CHNL.ARTEM"
host="127.0.0.1"
port='2020'
queue_name="Q1"
conn_info = '%s(%s)' % (host, port)
user = 'sender'
password = 'sender'

qmgr = pymqi.connect(queue_manager, channel, conn_info, user, password)

queue = pymqi.Queue(qmgr, queue_name)
queue.get()
queue.close()

qmgr.disconnect()