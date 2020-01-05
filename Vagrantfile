config_fqdn              = "mail.vagrant"
config_ip_address        = "192.168.33.254"

Vagrant.configure(2) do |config|
  config.vm.box = "generic/debian10"

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 256
    vb.cpus = 2
  end

  config.vm.hostname = config_fqdn
  config.vm.network "private_network", ip: config_ip_address
  config.vm.synced_folder ".", "/vagrant"

  config.vm.provision "shell", path: "provision-certificate.sh"
  config.vm.provision "shell", path: "provision-dnsmasq.sh"
  config.vm.provision "shell", path: "provision-postfix.sh"
  config.vm.provision "shell", path: "provision-dovecot.sh"
  config.vm.provision "shell", path: "provision.sh"
end
