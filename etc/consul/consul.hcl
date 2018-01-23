datacenter = "CONSUL_DATACENTER_NAME"
data_dir = "/var/lib/consul"
server = false
log_level = "ERR"
client_addr = "127.0.0.1"
ports {
  dns = 53
  http = 8500
}
recursors = ["8.8.8.8", "8.8.4.4"]
raft_protocol = 3
disable_update_check = true
disable_host_node_id = true
