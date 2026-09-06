Vagrant.configure("2") do |config|

  # ==========================================
  # IMAGEN BASE
  # ==========================================

  config.vm.box = "bento/ubuntu-24.04"


  # ==========================================
  # FRONTEND
  # ==========================================

  config.vm.define "frontend" do |frontend|

    # Hostname dentro de la VM
    frontend.vm.hostname = "frontend"

    # Red privada
    frontend.vm.network "private_network",
      ip: "192.168.56.11"

    # Configuración de VirtualBox
    frontend.vm.provider "virtualbox" do |vb|
      vb.name = "lab-frontend"
      vb.cpus = 1
      vb.memory = "1024"
    end

    # Provisioning inicial
    frontend.vm.provision "shell",
      path: "scripts/frontend.sh"

  end


  # ==========================================
  # BACKEND
  # ==========================================

  config.vm.define "backend" do |backend|

    # Hostname dentro de la VM
    backend.vm.hostname = "backend"

    # Red privada
    backend.vm.network "private_network",
      ip: "192.168.56.12"

    # Configuración de VirtualBox
    backend.vm.provider "virtualbox" do |vb|
      vb.name = "lab-backend"
      vb.cpus = 1
      vb.memory = "1024"
    end

    # Provisioning inicial
    backend.vm.provision "shell",
      path: "scripts/backend.sh"

  end


  # ==========================================
  # DATABASE
  # ==========================================

  config.vm.define "database" do |database|

    # Hostname dentro de la VM
    database.vm.hostname = "database"

    # Red privada
    database.vm.network "private_network",
      ip: "192.168.56.13"

    # Configuración de VirtualBox
    database.vm.provider "virtualbox" do |vb|
      vb.name = "lab-database"
      vb.cpus = 1
      vb.memory = "1024"
    end

    # Provisioning inicial
    database.vm.provision "shell",
      path: "scripts/database.sh"

  end

end