# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    config.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=700,fmode=600"]
  else
    config.vm.synced_folder ".", "/vagrant"
  end
  config.vm.define "test" do |d|
    d.vm.box = "ubuntu/trusty64"
    d.vm.hostname = "test"
    d.vm.network "private_network", ip: "10.100.198.200"
    d.vm.provision :shell, path: "scripts/bootstrap_ansible.sh"
    d.vm.provider "virtualbox" do |v|
      v.memory = 1024
    end
  end
  config.vm.define "rexray" do |d|
    d.vm.box = "ubuntu/trusty64"
    d.vm.hostname = "volume"
    d.vm.network "private_network", ip: "10.100.198.201"
    d.vm.provider "virtualbox" do |v|
      v.memory = 1024
    end
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end
end