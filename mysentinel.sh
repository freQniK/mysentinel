#!/bin/bash 

# EDIT THESE
ADDRESS=""
KEYNAME=""

# DO NOT TOUCH 
SCRT="31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8"
IBCSPACES="                                                               "

help_screen() {
 	__usage="
         MySentinel dVPN v0.3.3 (freQniK)
        
         Usage: $0 [options]
          
         Options: 
                  list,                         list all available dVPN nodes
                  sub <NODE_ADDRESS> <DEPOSIT>, subscribe to a node with address and deposit amount (in udpvn or uscrt, i.e., 500000udpvn, 7000uscrt)
                  subs,                         list your subscriptions with extra output of Location and Node Name
                  quota <ID>,                   list the quota and data used for subscription ID (found in subs option)
                  conn <ID> <NODE_ADDRESS>,     connect to the Node with ID and NODE_ADDRESS
                  part,                         disconnect from Sentinel dVPN. Note: you may have to ifconfig down <wg_interface> and edit /etc/resolv.conf
                  recover,                      add a wallet from the seed phrase
          "
        echo "$__usage"
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
        NODEOUTPUT=`sentinelcli query nodes \
            --home "${HOME}/.sentinelcli" \
            --node https://rpc.sentinel.co:443 \
            --limit 1000`
        echo "$NODEOUTPUT" | sed -e 's/ibc\/'"$SCRT"'/uscrt'"$IBCSPACES"'/g'
}


subscribe_to_node() {
	NODE=${1}
	DEPOSIT=${2^^}
	
	deposit=`echo ${DEPOSIT} | grep "SCRT"`
	is_scrt=$?
	
	if [[ $is_scrt -eq 0 ]]; then
		scrt_amt=`echo ${deposit} | sed 's/[^0-9]*//g'`
		DEPOSIT=$scrt_amt"ibc/"$SCRT
		echo "Total SCRT: ${DEPOSIT,,}"
	
	fi
	
	echo "NODE: $NODE, DEPOSIT: ${DEPOSIT,,}"
	echo -ne "Confrim (y/n): "
	read confirmation
	if [[ "${confirmation^^}" == "Y" ]]; then	
		sentinelcli tx subscription subscribe-to-node \
		    --home "${HOME}/.sentinelcli" \
		    --keyring-backend os \
		    --gas-prices 0.1udvpn \
		    --chain-id sentinelhub-2 \
		    --node https://rpc.sentinel.co:443 \
		    --from "$KEYNAME" $NODE ${DEPOSIT,,}
    	else
    		echo "Aww shucks. Alright then."
	fi
}

list_sentinel_subscriptions() {
        grep_nodes=""
        SUBOUTPUT=`sentinelcli query subscriptions \
            --home "${HOME}/.sentinelcli" \
            --node https://rpc.sentinel.co:443 \
            --status Active \
            --limit 100 \
            --address $ADDRESS`
        echo "$SUBOUTPUT" | sed -e 's/ibc\/'"$SCRT"'/uscrt'"$IBCSPACES"'/g'
        
        echo " "
        echo "                                                      Available Nodes                                                       "
        echo "+--------------------------------------------------------------------------------------------------------------------------------------------------------------+" 
        echo "|  ID  |        Node Name           |          Location         |                   Node Address                   |      Allocated       |       Consumed     |"
        echo "+--------------------------------------------------------------------------------------------------------------------------------------------------------------+"
        
        mapfile -t NODES < <(echo "${SUBOUTPUT}" | grep -oE "(sentnode[^[:space:]]+)")
        mapfile -t NODEIDS < <(echo "${SUBOUTPUT}" | tail +4 | head -n -1 | cut -d "|" -f 2 | tr -d " ")
#        echo "THESE ARE SUB NODES"
#	echo " "
#	for n in ${NODES[@]}; do
#        	echo "$n"
#	done
        k=0
        for node in ${NODES[@]}; do
                if [[ $k -eq 0 ]]; then
                        grep_nodes="$node"
                else
                        grep_nodes="$grep_nodes|$node"
                fi
                let k++
        done
#        echo ""
#        echo "$grep_nodes"
	
        NODEOUTPUT=`list_sentinel_nodes | grep -E "(${grep_nodes})"`
#        echo " "
#        echo "$NODEOUTPUT"
        mapfile -t NODENAMES < <(echo "${NODEOUTPUT}" | cut -d "|" -f 2 | tr -d " ")
        mapfile -t NODELOCS < <(echo "${NODEOUTPUT}" | cut -d "|" -f 6 | tr -d " ") 
        mapfile -t NODESLIST < <(echo "${NODEOUTPUT}" | cut -d "|" -f 3 | tr -d " ") 
        
        k=0
        j=0
#	echo "" 
	
#        for name in ${NODENAMES[@]}; do
#        	echo "$name"
#	done
	#
#	for addy in ${NODESLIST[@]}; do
#        	echo "$addy"
#	done
	

        for node in ${NODES[@]}; do
                #for new_node in ${NODESLIST[@]}; do
                for avail_node in ${NODESLIST[@]}; do
#			echo "New/Sub Node: $node | ${avail_node}"
                        if [[ "${node}" == "${avail_node}" ]]; then
                        	      SUBQUOTA=`list_subscription_quota ${NODEIDS[$k]}`
                        	      allocated=`echo "$SUBQUOTA" | tail -2 | head -1 | cut -d "|" -f 3 | tr -d " "`
                        	      consumed=`echo "$SUBQUOTA" | tail -2 | head -1 | cut -d "|" -f 4 | tr -d " "`
                        	      
                                echo -ne "| ${NODEIDS[$k]} "  
                                echo -ne "|   ${NODENAMES[$j]}"
                                
                                len=`echo "${NODENAMES[$j]}" | wc -c`
                                spacelen=`echo "25 - $len" | bc`
                                for ((i = 0 ; i <= $spacelen ; i++)); do
                                        echo -ne " "
                                done
                                echo -ne "|       ${NODELOCS[$j]}"
                                
                                len=`echo "${NODELOCS[$j]}" | wc -c`
                                spacelen=`echo "20 - $len" | bc`
                                for ((i = 0 ; i <= $spacelen ; i++)); do
                                        echo -ne " "
                                done
                                echo -ne "|"
                                echo -ne " ${avail_node}  |"
                                
                                len=`echo "${allocated}" | wc -c`
                                spacelen=`echo "16 - $len" | bc`
                                for ((i = 0 ; i <= $spacelen ; i++)); do
                                        echo -ne " "
                                done
                                echo -ne "${allocated}"
                        	      echo -ne "      |"   
                        	         
                        	      len=`echo "${consumed}" | wc -c`
                                spacelen=`echo "16 - $len" | bc`
                                for ((i = 0 ; i <= $spacelen ; i++)); do
                                        echo -ne " "
                                done
                                echo  "${consumed}    |"
                                
                                break
                        else
                                let j++
                                continue
                                
                                
                        fi
                done
                j=0
                let k++
        done
        echo "+--------------------------------------------------------------------------------------------------------------------------------------------------------------+"
        
      
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

if [[ -z $ADDRESS ]] && [[ -z $KEYNAME ]]; then
	echo -ne "Wallet Address: "
	read address
	echo -ne "Key Name: "
	read keyname
	sed -i 's/ADDRESS=\"\"/ADDRESS=\"'"$address"'\"/g' $0
 	sed -i 's/KEYNAME=\"\"/KEYNAME=\"'"$keyname"'\"/g' $0
fi

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



