# linux_install_script
Script to run after fresh linux install

This scrtip sets the timezone to Est, install dotfile, and XCP-NG tools. It also install topgrade to fully update the system.

### Clone the repo and run setup.sh
```
git clone "https://github.com/acebmxer/linux_install_script.git"
cd linux_install_script && chmod +x setup.sh && bash setup.sh
```

### With out Docker
wget https://raw.githubusercontent.com/acebmxer/linux_install_script/main/setup_without_docker.sh && chmod +x setup_without_docker.sh && bash setup_without_docker.sh

### With Docker
wget https://raw.githubusercontent.com/acebmxer/linux_install_script/main/setup_with_docker.sh && chmod +x setup_with_docker.sh && bash setup_with_docker.sh

### Install Docker
wget https://raw.githubusercontent.com/acebmxer/linux_install_script/main/install_docker.sh && chmod +x install_docker.sh && bash install_docker.sh
