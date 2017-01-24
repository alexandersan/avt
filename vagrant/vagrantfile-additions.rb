# -*- mode: ruby -*-
# vi: set ft=ruby :

def install_plugins(plugins)
  plugins.each do |plugin|
    needs_restart = false
    unless Vagrant.has_plugin? plugin
      system "vagrant plugin install #{ plugin }"
      needs_restart = true
    end
    exec "vagrant #{ ARGV.join ' ' }" if needs_restart
  end
end

def fix_tty_error(config)
  config.vm.provision "fix-tty-error", type: "shell", privileged: true, inline: <<-'SHELL'
    grep -q -E '^mesg n$' /root/.profile && {
      sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile
      echo 'Ignore the previous error about stdin not being a tty. Fixing it now...'
    } || true
  SHELL
end

def setup_guest_vm(config)

  # Parallels Desktop provider (preferred)
  #
  config.vm.provider "parallels" do |v|
    v.linked_clone = true
    v.update_guest_tools = false
    v.check_guest_tools = false
    v.customize ["set", :id, "--longer-battery-life", "off"]
  end

  # VirtualBox provider
  #
  config.vm.provider "virtualbox" do |v|
  end

  # LibVirt provider
  #
  config.vm.provider "libvirt" do |libvirt|
    libvirt.driver = "kvm"
    libvirt.cpu_feature name: 'avx', policy: 'disable'
    libvirt.cpu_feature name: 'avx2', policy: 'disable'
  end

end

def os_check(vms)
  host = RbConfig::CONFIG['host_os']
  # Give VM 1/N system memory & access to all cpu cores on the host
  if host =~ /darwin/
    cpus = `sysctl -n hw.ncpu`.to_i - 1
    # sysctl returns Bytes and we need to convert to MB
    mem = ( `sysctl -n hw.memsize`.to_i / 1024 / 1024 - 1024 ) / vms
  elsif host =~ /linux/
    cpus = `nproc`.to_i - 1
    # meminfo shows KB and we need to convert to MB
    mem = ( `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 - 1024 ) / vms
  else # sorry Windows folks, I can't help you
    cpus = `wmic cpu get NumberOfCores`.split("\n")[2].to_i - 1
    mem = ( `wmic OS get TotalVisibleMemorySize`.split("\n")[2].to_i / 1024 - 1024 ) / vms
  end
  return { "cpus" => cpus, "mem" => mem }
end
