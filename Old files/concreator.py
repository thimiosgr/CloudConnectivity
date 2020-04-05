import commands
import os
import subprocess

print '\nCreating container\n'

out = commands.getoutput('docker run -d ubuntu /bin/bash -c "while true; do sleep 3600; done"')
conname  = out[0:12]

print 'Updating...\n'
os.system('docker exec -it %s apt update' %conname)

print 'Installing Ifconfig...'
os.system('docker exec -it %s apt-get install net-tools' %conname)

print 'Installing ping...'
os.system('docker exec -it %s apt-get install iputils-ping -y' %conname) 
