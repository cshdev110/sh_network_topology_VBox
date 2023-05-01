#!/bin/bash

#Create six VM using VBox. Three of them are normal host, and the other three are configure to be routers.
#VBox must have the specific VM (debian OS without desktop environment).
#The code will create a snapshot, and then the six host. 
#Lastly, it will set up them to create a network. The code will run a ping checking connection between host.

#Check if base VM exist at first
function check_base_vm {
    vboxmanage list vms | grep base > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Virtual machine 'base' found!"
    elif [ $? -ne 0 ]; then
        echo "Virtual machine named 'base' doesn't exist."
        exit 2
    fi
    #Checking if base VM has a snapshot called base-snapshot1
    vboxmanage snapshot base list | grep base-snapshot1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Snapshot 'base-snapshot1' from 'base VM' found!"
        check_steps=1
        check_base_vm_success=1
    elif [ $? -ne 0 ]; then
        #Creat snapshot for base VM
        echo -e "The snapshot 'base-snapshot1' for 'base' VM is not created.\n"
        read -r -N 1 -p "Do you want to creat a snapshot from base VM? Y(Yes) - n(no)" opt
        if [ $opt = y ];then
            vboxmanage snapshot base take base-snapshot1
            if [ $? -eq 0 ]; then
                echo "Snapshot successfully created."
                check_steps=1
                check_base_vm_success=1
            else
                echo -e "Error creating Snapshot.\nExit"
                exit 2
            fi
        fi
    fi
}

#Creating infrastructure by cloning base VM
function create_infrastructure {
    for device in "${vms[@]}"; do
        device=($device)
        vboxmanage list vms | grep ${device[0]} > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            vboxmanage clonevm base --name ${device[0]} --snapshot base-snapshot1 --options link --register > /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --cableconnected2 off > /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --cableconnected3 off > /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --cableconnected4 off > /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --nic1 nat --intnet1 "eth0"> /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --nic2 intnet --intnet2 ${device[2]} > /dev/null 2>&1
            if [ ${#device[*]} -gt 4 ]; then
                vboxmanage modifyvm ${device[0]} --nic3 intnet --intnet3 ${device[3]} > /dev/null 2>&1
                vboxmanage modifyvm ${device[0]} --nic4 intnet --intnet4 ${device[4]} > /dev/null 2>&1
                vboxmanage modifyvm ${device[0]} --cableconnected3 on > /dev/null 2>&1
                vboxmanage modifyvm ${device[0]} --cableconnected4 on > /dev/null 2>&1
            fi
            vboxmanage modifyvm ${device[0]} --cableconnected2 on > /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --natpf1 delete "ssh" > /dev/null 2>&1
            vboxmanage modifyvm ${device[0]} --natpf1 "ssh,tcp,,${device[1]},,22" > /dev/null 2>&1
        fi
    done
    for device in "${vms[@]}"; do
        device=($device)
        vboxmanage list vms | grep ${device[0]}
        if [ $? -ne 0 ]; then
            echo -e "The VM ${device[0]} was not created. Try again.\n"
            check_steps=1
            return
        fi
    done
    echo -e "All VMs were checked successfully\n"
    check_steps=2
}

function setup_interfaces {
    interfaces=(
"# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# VboxNetwork: PC1

auto eth0
iface eth0 inet dhcp
auto eth1
iface eth1 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    network 192.168.1.0
    broadcast 192.168.1.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.1.254 dev eth1
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.1.254 dev eth1"
"# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# VboxNetwork: PC2

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.2.1
    netmask 255.255.255.0
    network 192.168.2.0
    broadcast 192.168.2.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.2.254 dev eth1
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.2.254 dev eth1"
"# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# VboxNetwork: PC3

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.3.1
    netmask 255.255.255.0
    network 192.168.3.0
    broadcast 192.168.3.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.3.254 dev eth1
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.3.254 dev eth1"
"# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# VboxNetwork: R1

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.1.254
    netmask 255.255.255.0
    network 192.168.1.0
    broadcast 192.168.1.255
    
auto eth2
iface eth2 inet static
    address 192.168.100.1
    netmask 255.255.255.0
    network 192.168.100.0
    broadcast 192.168.100.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.100.2 dev eth2
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.100.2 dev eth2
    
auto eth3
iface eth3 inet static
    address 192.168.101.2
    netmask 255.255.255.0
    network 192.168.101.0
    broadcast 192.168.101.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.101.1 dev eth3
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.101.1 dev eth3"
    
"# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# VboxNetwork: R2

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.2.254
    netmask 255.255.255.0
    network 192.168.2.0
    broadcast 192.168.2.255
    
auto eth2
iface eth2 inet static
    address 192.168.100.2
    netmask 255.255.255.0
    network 192.168.100.0
    broadcast 192.168.100.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.100.1 dev eth2
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.100.1 dev eth2
    
auto eth3
iface eth3 inet static
    address 192.168.102.1
    netmask 255.255.255.0
    network 192.168.102.0
    broadcast 192.168.102.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.102.2 dev eth3
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.102.2 dev eth3"

"# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# VboxNetwork: R3

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.3.254
    netmask 255.255.255.0
    network 192.168.3.0
    broadcast 192.168.3.255
    
auto eth2
iface eth2 inet static
    address 192.168.101.1
    netmask 255.255.255.0
    network 192.168.101.0
    broadcast 192.168.101.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.101.2 dev eth2
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.101.2 dev eth2
    
auto eth3
iface eth3 inet static
    address 192.168.102.2
    netmask 255.255.255.0
    network 192.168.102.0
    broadcast 192.168.102.255
    post-up route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.102.1 dev eth3
    pre-down route del -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.102.1 dev eth3"
    )
    echo
    echo "Please wait until the VM starts completely"
    while :
    do
        for (( iv=0; iv<${#vms[@]}; iv++)); do
            vmv=(${vms[$iv]})
            vboxmanage list runningvms | grep ${vmv[0]} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                vboxmanage startvm ${vmv[0]} & > /dev/null 2>&1
            fi
        done
        runv=0
        while :
        do
            vmv=(${vms[$runv]})
            vboxmanage list runningvms | grep ${vmv[0]} > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "VM ${vmv[0]} is running"
                (( runv++ ))
            fi
            if [ $runv -eq 6 ]; then
                break
            fi
        done
        if [ $runv -eq 6 ]; then
            break
        fi
    done
    echo -e "...Waiting for the vm finishes to start, and then, sets up the interfaces...\n"
    for (( i=0; i<${#vms[@]}; i++ )) ; do
        vm=(${vms[$i]})
        echo "${interfaces[i]}" > interfaces
        while :
        do
            sshpass -p "network" scp -o StrictHostKeyChecking=no -P "${vm[1]}" interfaces network@127.0.0.1:~/ > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                rm -r interfaces
                echo "Configuring ${vm[0]}..."
                while :
                do
                    echo "network" | sshpass -p "network" ssh -o StrictHostKeyChecking=no -tt -p "${vm[1]}" network@127.0.0.1 "sudo cp ~/interfaces /etc/network/interfaces" > /dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        echo "${vm[0]}" | grep R > /dev/null 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e " Configuring forward..."
                            echo "network" | sshpass -p "network" ssh -o StrictHostKeyChecking=no -tt -p "${vm[1]}" network@127.0.0.1 "sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf" > /dev/null 2>&1
                        fi
                        echo -e " Rebooting..."
                        echo "network" | sshpass -p "network" ssh -o StrictHostKeyChecking=no -tt -p "${vm[1]}" network@127.0.0.1 "sudo reboot" > /dev/null 2>&1
                        
                        echo -e " Interface configured\n"
                        break
                    fi
                done
                break
            fi
        done
    done
    for iv in ${!vms[@]}; do
        vm=(${vms[$iv]})
        echo "${vm[0]}" | grep R > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            while :
            do
                echo "Finishing settings for ${vm[0]} ..."
                echo "network" | sshpass -p "network" ssh -o StrictHostKeyChecking=no -tt -p "${vm[1]}" network@127.0.0.1 "sudo iptables -A FORWARD -j ACCEPT" > /dev/null 2>&1
                if [ $? = 0 ]; then
                    echo "network" | sshpass -p "network" ssh -o StrictHostKeyChecking=no -tt -p "${vm[1]}" network@127.0.0.1 "sudo iptables -t nat -A POSTROUTING -j MASQUERADE" > /dev/null 2>&1
                    break
                fi
            done
            echo -e " IPTALBES configured"
            check_steps=3
        fi
    done
    echo
}

function pings {
    pings_to_do=(
                "PC1 2201 192.168.2.1 PC2"
                "PC1 2201 192.168.3.1 PC3"
                "PC1 2201 192.168.1.254 R1"
                "PC1 2201 192.168.100.2 R2"
                "PC1 2201 192.168.101.1 R3"
                "PC2 2202 192.168.1.1 PC1"
                "PC2 2202 192.168.3.1 PC3"
                "PC2 2202 192.168.2.254 R2"
                "PC2 2202 192.168.100.2 R1"
                "PC2 2202 192.168.102.2 R3"
                "PC3 2203 192.168.2.1 PC2"
                "PC3 2203 192.168.1.1 PC1"
                "PC3 2203 192.168.3.254 R3"
                "PC3 2203 192.168.101.2 R1"
                "PC3 2203 192.168.102.1 R2"
                )
    echo -e "This little test will ping:\n"
    echo "PC1 ping -> PC2"
    echo "PC1 ping -> PC3"
    echo "PC1 ping -> R1"
    echo "PC1 ping -> R2"
    echo "PC1 ping -> R3"
    echo "and..."
    echo "PC2 ping -> PC1"
    echo "PC2 ping -> PC3"
    echo "PC2 ping -> R2"
    echo "PC2 ping -> R1"
    echo "PC2 ping -> R3"
    echo "and..."
    echo "PC3 ping -> PC2"
    echo "PC3 ping -> PC1"
    echo "PC3 ping -> R3"
    echo "PC3 ping -> R1"
    echo "PC3 ping -> R2"

    for iv in ${!pings_to_do[@]}; do
        ping=(${pings_to_do[$iv]})
        echo -e "\n---> ${ping[0]} ping to ${ping[2]} (${ping[3]})<---"
        sshpass -p "network" ssh -t -p ${ping[1]} network@127.0.0.1 "ping -c 2 ${ping[2]} | grep -e PING -e icmp"
        echo "------------------------------------------------------"
    done
}

function shutdownVM {
    for iv in ${!vms[@]}; do
        vm=(${vms[$iv]})
        echo "VM ${vm[0]} shutdown"
        vboxmanage controlvm ${vm[0]} acpipowerbutton
    done
}

function removeVM {
    for iv in ${!vms[@]}; do
        vm=(${vms[$iv]})
        echo "VM ${vm[0]} removed"
        vboxmanage unregistervm --delete ${vm[0]}
    done
}

function options {
    echo
    echo "==========================================================================================="
    echo "(1) -> Step 1: Check if the base VM exist and if it has a snapshot called 'base-snapshot1'"
    echo "(2) -> Step 2: Create infrastructure cloning base VM"
    echo "(3) -> Step 3: Setting up interfaces"
    echo "(4) -> Step 4: Test the Network doing pings"
    echo "(5) -> Step 5: Shut down VMs"
    echo "(6) -> Step 6: Delete VMs"
    echo "(q) -> Press q to Exit"
    echo "==========================================================================================="
    echo

}

declare -g check_steps=0
declare -g check_base_vm_success=0
declare -a vms=("PC1 2201 PC1"
                "PC2 2202 PC2"
                "PC3 2203 PC3"
                "R1 2204 PC1 neta netb"
                "R2 2205 PC2 neta netc"
                "R3 2206 PC3 netb netc")
while :
do
    options
    read -r -N 1 -p "Step chosen: " opt
    echo
    case $opt in
        1)
            echo -e "\n-> Check if the base VM exist and if it has a snapshot called 'base-snapshot1'.\n"
            check_base_vm
            ;;
        2)
            if (( $check_steps > 0 )) ; then
                echo -e "-> Create infrastructure from cloning 'base' VM."
                if [ $check_base_vm_success = 1 ]; then
                    create_infrastructure
                else
                    echo "-> The requirements in step 1 weren't succeded."
                fi
            else
                echo -e "\n-> Go to step 1 first, to check the 'base VM'.\n"
            fi
            ;;
        3)
            if (( $check_steps > 1 )); then
                echo -e "-> Setting up interfaces"
                # Checking for sshpass
                if ! command -v sshpass > /dev/null 2>&1; then
                    echo -e "The program sshpass in not install. It is necessary to continue.\n"
                    read -r -N 1 -p "Would you allow to install it? yes(y) - no(n): " opt
                    echo
                    if [ $opt = y ]; then
                        #Checking for internet
                        wget -q --spider https://www.google.com
                        if [ ! $? -eq 0 ]; then
                            echo -e "\nNo Internet connection. It is necessary to install sshpass.\n"
                            echo "Exit"
                            break
                        fi
                        sudo apt -y install sshpass > /dev/null 2>&1
                        if command -v sshpass > /dev/null 2>&1; then
                            echo -e "\nsshpass successfully installed.\n"
                        else
                            echo -e "\nErro at installing sshpass. Try again or install it typing: sudo apt install sshpass"
                            echo "Exit"
                            break
                        fi
                    else
                        continue
                    fi
                fi
                setup_interfaces
            else
                echo -e "\n-> Go to step 2 first, to check or create the infrastructure.\n"
            fi
            ;;
        4)
            if (( $check_steps > 2 )); then
                echo -e "->Test the Network doing pings"
                pings
            else
                echo -e "\n-> Go to step 3 first, to set up the interfaces in each VM.\n"
            fi
            ;;
        5)
            if (( $check_steps > 0 )); then
                echo -e "->Shut down VMs"
                shutdownVM
            else
                echo -e "\n-> Go to step 4 first.\n"
            fi
            ;;
        6)
            if (( $check_steps > 0 )); then
                echo -e "->Remove VMs"
                removeVM
            else
                echo -e "\n-> Go to step 5 first.\n"
            fi
            ;;
        q)
            echo -e "Exit"
            break
            ;;
        *)
            echo -e "\nOption incorrect."
    esac
done