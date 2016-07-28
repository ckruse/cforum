# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial32"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder ".", "/vagrant"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL

  config.vm.provision :shell, inline: <<-SHELL
cat <<'EOF' > /etc/hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
127.0.0.1 localhost unbuntu-xenial
EOF
  SHELL

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks", "site-cookbooks"]

    chef.add_recipe "apt"
    chef.add_recipe "build-essential"
    chef.add_recipe "nodejs"
    chef.add_recipe "ruby_build"
    chef.add_recipe "ruby_rbenv::system"
    chef.add_recipe "vim"
    chef.add_recipe "postgresql::server"
    chef.add_recipe "postgresql::client"
    chef.add_recipe "postgresql::contrib"

    # Install Ruby 2.2.1 and Bundler
    # Set an empty root password for MySQL to make things simple
    chef.json = {
      rbenv: {
        rubies: ["2.3.1"],
        global: "2.3.1",
        gems: {
          "2.3.1" => [
            { name: "bundler" }
          ]
        }
      },
      postgresql: {
        enable_pgdg_apt: true,
        version: '9.5',
        dir: "/etc/postgresql/9.5/main",
        config: {
          data_directory: "/var/lib/postgresql/9.5/main",
          hba_file: "/etc/postgresql/9.5/main/pg_hba.conf",
          ident_file: "/etc/postgresql/9.5/main/pg_ident.conf",
          external_pid_file: "/var/run/postgresql/9.5-main.pid",
          ssl_key_file: "/etc/ssl/private/ssl-cert-snakeoil.key",
          ssl_cert_file: "/etc/ssl/certs/ssl-cert-snakeoil.pem",
        },
        client: { packages: ["postgresql-client-9.5"] },
        server: { packages: ["postgresql-9.5", "postgresql-server-dev-9.5"] },
        contrib: { packages: ["postgresql-contrib-9.5"] },
        password: { postgres: '' },
        pg_hba: [
          {type: 'local', db: 'all', user: 'all', addr: nil, method: 'trust'},
          {type: 'host', db: 'all', user: 'all', addr: '127.0.0.1/32', method: 'trust'},
          {type: 'host', db: 'all', user: 'all', addr: '::1/128', method: 'trust'}
        ],
        service_actions: ["enable", "start"]
      }
    }
  end

  config.vm.provision :shell, inline: <<-SHELL
psql -U postgres -tc "SELECT * FROM pg_catalog.pg_user WHERE usename = 'ubuntu'" | grep -q 1 || \
  createuser -U postgres -s ubuntu
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'cforum_development'" | grep -q 1 || \
  createdb -U ubuntu cforum_development
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'cforum_test'" | grep -q 1 || \
  createdb -U ubuntu cforum_test

cd /vagrant
sudo -u ubuntu -i bash -c 'cd /vagrant && bundle install'
sudo -u ubuntu -i bash -c 'cd /vagrant && rake db:migrate'
sudo -u ubuntu -i bash -c 'cd /vagrant && rake db:seed'
  SHELL
end
