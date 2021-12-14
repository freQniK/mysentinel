# mysentinel
An easy to use wrapper around the sentinelcli 

## Configure
Edit these lines of the script:

```
ADDRESS=""
KEYNAME=""
```

To be the address of your sentinelcli wallet, starting with **sent**.
And the KeyName of your sentinelcli wallet.

## Usage

```
$ ./mysentinel.sh help
MySentinel dVPN v0.1.1 (freQniK)
 
Usage: ./mysentinel.sh [options]
 
Options: 
         list,                      list all available dVPN nodes
         subs,                      list your subscriptions with extra output of Location and Node Name
         conn <ID> <NODE_ADDRESS>,  connect to the Node with ID and NODE_ADDRESS
         part,                      disconnect from Sentinel dVPN. Note: you may have to ifconfig down <wg_interface> and edit /etc/resolv.conf
 
$ 
```

Example output:
```
$ ./mysentinel.sh subs
+------+---------------------------------------------+------+-------------------------------+-------+-------------------------------------------------+------------+--------------+-------+---------------+
|  ID  |                    OWNER                    | PLAN |            EXPIRY             | DENOM |                      NODE                       |   PRICE    |   DEPOSIT    | FREE  |    STATUS     |
+------+---------------------------------------------+------+-------------------------------+-------+-------------------------------------------------+------------+--------------+-------+---------------+
| 1329 | sent1c94r396teq8w3qgn548gp46zsjm2kjqn069z97 |    0 | 0001-01-01 00:00:00 +0000 UTC |       | sentnode1cwrk3xev08e75afd75y8ckqvt4ks4wq7g770v8 | 30000udvpn | 1000000udvpn | 0.00B | STATUS_ACTIVE |
| 1488 | sent1c94r396teq8w3qgn548gp46zsjm2kjqn069z97 |    0 | 0001-01-01 00:00:00 +0000 UTC |       | sentnode1gm8zm3rnkklr6zp20qazpqayqcwg7g2gfnwyxy | 30000udvpn | 1000000udvpn | 0.00B | STATUS_ACTIVE |
+------+---------------------------------------------+------+-------------------------------+-------+-------------------------------------------------+------------+--------------+-------+---------------+
 
-------------------------------------------------------------------------------------------------------------
|        Node Name           |          Location         |                   Node Address                   |
-------------------------------------------------------------------------------------------------------------
|   Bouts-Node-Paris         |       France              | sentnode1gm8zm3rnkklr6zp20qazpqayqcwg7g2gfnwyxy  |
|   Lomsy                    |       Poland              | sentnode1cwrk3xev08e75afd75y8ckqvt4ks4wq7g770v8  |
-------------------------------------------------------------------------------------------------------------
$ 
```

In case I want to connect to **Lomsy** I would run:

```
$ ./mysentinel.sh conn 1329 sentnode1cwrk3xev08e75afd75y8ckqvt4ks4wq7g770v8
```

To disconnect:
```
$ ./mysentinel.sh part
```

**NOTE:** I've experienced the follwing issues when using the sentinelcli to disconnect. It never brings down the wireguard interface. In my case after `mysentinel.sh part` I would then run `sudo ifconfig wg_interface down`. Furthermore, my `/etc/resolv.conf` is not set to my gateway, as I run a dnsproxy there. So you may have to edit `/etc/resolv.conf` as well back to the original settings.

# Tipjar
You tip a waiter for their servie, why not tip a programmer for their code?

![tipjar qr](./img/dvpn_qr_code.png)

```
DVPN: sent14q4f245fj25xy57yhjah98jcvy6e3zndx76fh4
```

