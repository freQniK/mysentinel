#!/bin/bash 

# EDIT THESE
ADDRESS=""
KEYNAME=""

help_screen() {
        echo "MySentinel dVPN v0.2.1 (freQniK)"
        echo " "
        echo "Usage: $0 [options]"
        echo " "
        echo "Options: "
        echo "         list,                         list all available dVPN nodes"
        echo "         sub <NODE_ADDRESS> <DEPOSIT>, subscribe to a node with address and deposit amount (in udpvn, i.e., 500000udpvn"
        echo "         subs,                         list your subscriptions with extra output of Location and Node Name"
        echo "         quota <ID>,                   list the quota and data used for subscription ID (found in subs option)"
        echo "         conn <ID> <NODE_ADDRESS>,     connect to the Node with ID and NODE_ADDRESS"
        echo "         part,                         disconnect from Sentinel dVPN. Note: you may have to ifconfig down <wg_interface> and edit /etc/resolv.conf"
        echo "         recover,                      add a wallet from the seed phrase"
        echo " "
        exit
}

list_subscription_quota() {
	ID=$1
	sentinelcli query quotas \
	    --home "${HOME}/.sentinelcli" \
	    --node https://rpc.sentinel.co:443 \
	    --page 1 $ID

}

list_sentinel_nodes() {
        sentinelcli query nodes \
            --home "${HOME}/.sentinelcli" \
            --node https://rpc.sentinel.co:443 \
            --limit 700

}


subscribe_to_node() {
	NODE=${1}
	DEPOSIT=${2}

	echo "NODE: $NODE, DEPOSIT: $DEPOSIT"
	sentinelcli tx subscription subscribe-to-node \
	    --home "${HOME}/.sentinelcli" \
	    --keyring-backend os \
            --gas-prices 0.1udvpn \
	    --chain-id sentinelhub-2 \
	    --node https://rpc.sentinel.co:443 \
	    --from "$KEYNAME" $NODE $DEPOSIT
}

list_sentinel_subscriptions() {
        grep_nodes=""
        SUBOUTPUT=`sentinelcli query subscriptions \
            --home "${HOME}/.sentinelcli" \
            --node https://rpc.sentinel.co:443 \
            --status Active \
            --page 1 \
            --address $ADDRESS`
        echo "$SUBOUTPUT"
        echo " "
        echo "                                       Available Nodes                                                       "
        echo "--------------------------------------------------------------------------------------------------------------------" 
        echo "   ID  |        Node Name           |          Location         |                   Node Address                   |"
        echo "--------------------------------------------------------------------------------------------------------------------"
        
        mapfile -t NODES < <(echo "${SUBOUTPUT}" | grep -oE "(sentnode[^[:space:]]+)")
        mapfile -t NODEIDS < <(echo "${SUBOUTPUT}" | tail +4 | head -n -1 | cut -d "|" -f 2 | tr -d " ")
        #for n in ${NODES[@]}; do
        #	echo "$n"
	#done
        k=0
        for node in ${NODES[@]}; do
                if [[ $k -eq 0 ]]; then
                        grep_nodes="$node"
                else
                        grep_nodes="$grep_nodes|$node"
                fi
                let k++
        done
        #echo ""
        #echo "$grep_nodes"
	
        NODEOUTPUT=`list_sentinel_nodes | grep -E "(${grep_nodes})"`
        #echo " "
        #echo "$NODEOUTPUT"
        mapfile -t NODENAMES < <(echo "${NODEOUTPUT}" | cut -d "|" -f 2 | tr -d " ")
        mapfile -t NODELOCS < <(echo "${NODEOUTPUT}" | cut -d "|" -f 6 | tr -d " ") 
        mapfile -t NODESLIST < <(echo "${NODEOUTPUT}" | cut -d "|" -f 3 | tr -d " ") 
        
        k=0
        j=0
	#echo "" 
	
        #for name in ${NODENAMES[@]}; do
        #	echo "$name"
	#done
	#
	#for addy in ${NODESLIST[@]}; do
        #	echo "$addy"
	#done
	

        for name in ${NODENAMES[@]}; do
                #for new_node in ${NODESLIST[@]}; do
                for old_node in ${NODES[@]}; do
		#	echo "New/Sub Node: $old_node | ${NODESLIST[$k]}"
                        if [[ "${old_node}" == ${NODESLIST[$k]} ]]; then
                                echo -ne "| ${NODEIDS[$j]} "  
                                echo -ne "|   ${NODENAMES[$k]}"
                                
                                len=`echo "${NODENAMES[$k]}" | wc -c`
                                spacelen=`echo "25 - $len" | bc`
                                for ((i = 0 ; i <= $spacelen ; i++)); do
                                        echo -ne " "
                                done
                                echo -ne "|       ${NODELOCS[$k]}"
                                
                                len=`echo "${NODELOCS[$k]}" | wc -c`
                                spacelen=`echo "20 - $len" | bc`
                                for ((i = 0 ; i <= $spacelen ; i++)); do
                                        echo -ne " "
                                done
                                echo -ne "|"
                                echo " ${NODESLIST[$k]}  |"
                                
                                break
                        else
                                let j++
                                continue
                                
                                
                        fi
                done
                j=0
                let k++
        done
        echo "--------------------------------------------------------------------------------------------------------------------"
        
      
}

connect_sentinel_node() {
        ID=$1
        NODE_ADDRESS=$2
        KEYNAME=$3
        sentinelcli connect \
            --home "${HOME}/.sentinelcli" \
            --keyring-backend os \
            --chain-id sentinelhub-2 \
            --node https://rpc.sentinel.co:443 \
            --gas-prices 0.1udvpn \
            --yes \
            --from "$KEYNAME" $ID $NODE_ADDRESS
}

part_sentinel_node() {
        sentinelcli disconnect \
            --home "${HOME}/.sentinelcli"
	echo "Reusting sudo permission to remove wg99 interface and shut down properly..."
	sudo ip link delete wg99
}

recover_key() {
	echo -ne "Wallet Name: "
	read wallet_name
	sentinelcli keys add \
	    --home "${HOME}/.sentinelcli" \
	    --keyring-backend os \
	    "$wallet_name" --recover

}

while [ "$#" -gt 0 ]; do
        key=${1}

        case ${key} in
                list|--list)
                        list_sentinel_nodes
                        shift
                        ;;
	       subs|--subscriptions)
                        list_sentinel_subscriptions
                        shift
                        ;;
                sub|--subscribe)
                        NODE=${2}
                        DEPOSIT=${3}
                        subscribe_to_node $NODE $DEPOSIT
                        shift
                        shift
                        shift
                        ;;

                quota|--quota)
                        ID=${2}
                        list_subscription_quota $ID
                        shift
                        shift
                        ;;
                conn|--connect)
                        ID=${2}
                        NODE_ADDRESS=${3}
                        connect_sentinel_node $ID $NODE_ADDRESS "$KEYNAME"
                        shift
                        shift
                        shift
                        ;;
                part|--disconnect)
                        part_sentinel_node
                        shift
                        ;;
                recover|--recover)
               		recover_key
               		shift
               		;;
                help|--help)
                        help_screen
                        shift
                        ;;
                *)
                        shift
                        ;;
        esac
done



