#!/bin/bash 

# EDIT THESE
ADDRESS="sent1c94r396teq8w3qgn548gp46zsjm2kjqn069z97"
KEYNAME="Sisyphus"

help_screen() {
        echo "MySentinel dVPN v0.1.1 (freQniK)"
        echo " "
        echo "Usage: $0 [options]"
        echo " "
        echo "Options: "
        echo "         list,                      list all available dVPN nodes"
        echo "         subs,                      list your subscriptions with extra output of Location and Node Name"
        echo "         conn <ID> <NODE_ADDRESS>,  connect to the Node with ID and NODE_ADDRESS"
        echo "         part,                      disconnect from Sentinel dVPN. Note: you may have to ifconfig down <wg_interface> and edit /etc/resolv.conf"
        echo " "
        exit
}

list_sentinel_nodes() {
        sentinelcli query nodes \
            --home "${HOME}/.sentinelcli" \
            --node https://rpc.sentinel.co:443 \
            --limit 300

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
        echo "-------------------------------------------------------------------------------------------------------------" 
        echo "|        Node Name           |          Location         |                   Node Address                   |"
        echo "-------------------------------------------------------------------------------------------------------------"
        
        mapfile -t NODES < <(echo "${SUBOUTPUT}" | grep -oE "(sentnode[^[:space:]]+)")
 
        k=0
        for node in ${NODES[@]}; do
                if [[ $k -eq 0 ]]; then
                        grep_nodes="$node"
                else
                        grep_nodes="$grep_nodes|$node"
                fi
                let k++
        done

        NODEOUTPUT=`list_sentinel_nodes | grep -E "(${grep_nodes})"`
        mapfile -t NODENAMES < <(echo "${NODEOUTPUT}" | cut -d "|" -f 2 | tr -d " ")
        mapfile -t NODELOCS < <(echo "${NODEOUTPUT}" | cut -d "|" -f 6 | tr -d " ") 
        mapfile -t NODESLIST < <(echo "${NODEOUTPUT}" | cut -d "|" -f 3 | tr -d " ") 
        
        k=0
        j=0
        for name in ${NODENAMES[@]}; do
                for new_node in ${NODESLIST[@]}; do
                        if [[ "${new_node}" == ${NODES[$k]} ]]; then
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
                                echo " ${NODES[$j]}  |"
                                
                                let j++
                                break
                        else
                                let j++
                                continue
                                
                                
                        fi
                done
                j=0
                let k++
        done
        echo "-------------------------------------------------------------------------------------------------------------"
        
      
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
            --from  $KEYNAME $ID $NODE_ADDRESS
}

part_sentinel_node() {
        sentinelcli disconnect \
            --home "${HOME}/.sentinelcli"
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
                conn|--connect)
                        ID=${2}
                        NODE_ADDRESS=${3}
                        connect_sentinel_node $ID $NODE_ADDRESS $KEYNAME
                        shift
                        shift
                        shift
                        ;;
                part|--disconnect)
                        part_sentinel_node
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



