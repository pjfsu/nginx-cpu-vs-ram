echo "CPU: $(lscpu | grep 'Model name:' | sed 's/Model name:\s*//')"
echo "RAM: $(free -h | awk '/Mem:/ {print $2}')"
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '\"')"
echo "Kernel: $(uname -r)"
