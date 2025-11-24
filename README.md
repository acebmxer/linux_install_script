# linux_setup_script
Script to run after fresh linux install

This scrtip sets the timezone to Est, install dotfile, and XCP-NG tools. It also install topgrade to fully update the system.

### Clone the repo and run setup.sh
```
git clone "https://github.com/acebmxer/linux_setup_script.git"
cd linux_setup_script && chmod +x setup.sh && bash setup.sh
```
### Force a light theme (works even if the terminal is dark
SETUP_THEME=light ./setup.sh

### Force a dark theme
SETUP_THEME=dark ./setup.sh

# 

### With out Docker
wget https://raw.githubusercontent.com/acebmxer/linux_setup_script/main/setup_without_docker.sh && chmod +x setup_without_docker.sh && bash setup_without_docker.sh

### With Docker
wget https://raw.githubusercontent.com/acebmxer/linux_setup_script/main/setup_with_docker.sh && chmod +x setup_with_docker.sh && bash setup_with_docker.sh

### Install Docker
wget https://raw.githubusercontent.com/acebmxer/linux_setup_script/main/install_docker.sh && chmod +x install_docker.sh && bash install_docker.sh
