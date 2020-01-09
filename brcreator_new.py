import commands
import os 
import subprocess

allbridges = []
def brfinder(out):
    temp = ''
    cnt = 0
    for i in out:
        cnt = cnt+1
        if ord(i)!=10:
                temp = temp+i
        if ord(i)==10 or cnt==len(out):
                allbridges.append(temp)
                temp=''

bridgelist  = commands.getoutput('sudo ovs-vsctl list-br')
brfinder(bridgelist)
opt = raw_input("\nDo you want to delete an old bridge (Y/N) ? ")
if opt!='Y' and opt!='N':
    os._exit(0)
while opt=='Y':
    oldbrname = raw_input("\nEnter the name of the bridge you want to delete: ")
    if oldbrname in allbridges:
        os.system('sudo ovs-vsctl del-br %s' %oldbrname)
        print ("\nBridge \'%s\' succesfully deleted!\n" %oldbrname)
        break
    else:
        print("\nThere is no such bridge.")
        os._exit(0)

qu = raw_input("Do you want to create a new bridge (Y/N) ? ")
while qu == 'Y':
    newbridge = raw_input("\nType the name of the new bridge: ")
    if newbridge in allbridges:
        print("This bridge already exists. Give another name please.\n")
    else:
        os.system("sudo ovs-vsctl add-br %s" %newbridge) 
        print("\nBridge \'%s\' was created!" %newbridge)
        break