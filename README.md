Munin---Plugin-ESX
==================

This is plugins ESX for Munin.

##Requirements

You have to install VmWare SDK for Perl 4.1 (you have to create an account ; last release is V5.1 but I haven't test it, you can do it at your own risks).

    https://my.vmware.com/fr/group/vmware/details?productId=230&downloadGroup=SDKPERL41
    
VmWare Documentation : http://www.vmware.com/support/developer/viperltoolkit/viperl41/doc/vsp_4_41_vsperl_install.pdf


For SDK, install these package :

    apt-get install make libclass-methodmaker-perl libcrypt-ssleay-perl install libuuid-perl libssl-dev perl-doc liburi-perl libxml-libxml-perl libcrypt-ssleay-perl ia32-libs
    
Note : Maybe I have forgotten some package requierement, please use vmware documentation if you have problems.

You have to install some CPAN lib :

    sudo cpan -i LWP::UserAgent
    sudo cpan -i Net::Ping

##Installation

Note : Install script is a test, you can try to use it but there is no warranty that it will work. I prefer manual install like this bellow :

    mkdir /opt/munin-esx
    mkdir /opt/munin-esx/plugins
    cp get_ressource /opt/munin-esx/
    cp plugins/* /opt/munin-esx/plugins/
    ln -s /opt/munin-esx/plugins/* /etc/munin/plugins/*
    
Second step is to test get_ressource script, just launch it like that :

    ./get_ressource --address 192.168.1.200 --user admin --password pwd
    
Use address, user and user's password of your VCenter.
This should take few seconds. When it finish, look at /tmp/ dir :

    grep dump | ls /tmp
    
If you have some dump_host_192.168.1.201.dump like file, this is working ! Else look at your syslog :

    grep ESX_RESSOURCE /var/log/syslog
    
If you have any "SERVER:192.168.1.201:UNREACHABLE", please verify your VCenter's server IP. If it is the correct IP, verify that you have installed CPAN lib "Net::Ping".
If it's installed and that don't work, you have to disable some source code in get_ressource script.

So, comment this in file head (line 105 to 126, normally) :

    #my $ping = Net::Ping->new("tcp", 1);
    #if ($ping->ping($address)) {
    #        my $ua  = LWP::UserAgent->new();    
    #        my $req = HTTP::Request->new(GET => "https://".$address);
    #        my $res = $ua->request($req);
    #        if (${$res}{_rc} == "404") {
    #                setlogsock('unix');
    #                openlog('ESX_RESSOURCE', '', 'user');
    #                syslog('info', "VCENTER:$address:UNREACHABLE");
    #                closelog;
    #                cleanup($dump_vm, $dump_host, $dump_datastore, $dump_time, $dump_log, $dump_link_counterId, $dump_link_host, $dump_link_host_cluster, $dump_link_vm, $dump_link_vm_host, $dump_link_vm_cluster);
    #    	exit;
    #                }
    #        }
    #else {
    #        setlogsock('unix');
    #        openlog('ESX_RESSOURCE', '', 'user');
    #        syslog('info', "SERVER:$address:UNREACHABLE");
    #        closelog;
    #        cleanup($dump_vm, $dump_host, $dump_datastore, $dump_time, $dump_log, $dump_link_counterId, $dump_link_host, $dump_link_host_cluster, $dump_link_vm, $dump_link_vm_host, $dump_link_vm_cluster);
    #	exit;
    #        }


Now you have to edit munin.conf file and add :

    [esx.com;vcenter]
      address 127.0.0.1
      use_node_name no

("esx" is the domain you want and "vcenter" the machine name printed on Munin's web GUI).
If you want to print something like :

    vcenter.esx.com

And not just "vcenter", use syntax like it :

    [vcenter.esx.com]
      address 127.0.0.1
      use_node_name no

Now, create new file in /etc/munin/plugin-conf.d/ :

    vi /etc/munin/plugin-conf.d/esx

And add this :

    [esx_*]
    timeout 60
    env.address 192.168.1.1                  #your VCenter IP
    env.user administrateur                  #your VCenter user
    env.password lfgaedtf                    #your VCenter user's password
    env.path /tmp/                           #path where dump will be generated
    env.collector /opt/munin-esx/            #absolute path where get_resource script is located
    env.hostname vcenter                     #you plugins hostname
    
Note : for hostname env variable, if you use "esx.com;vcenter" syntax in munin.conf use "env.hostname vcenter", else use "env.hostname vcenter.esx.com".

Now, just restart your Munin-node :

    sudo service munin-node restart
    
It should works now, if you have any issues, please drop it : https://github.com/TriDni/Munin---Plugin-ESX/issues



    


