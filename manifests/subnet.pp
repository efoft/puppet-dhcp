# @summary
#   This module only supports subnet declaraion with pools. Pools allow to split network into several ranges with different settings.
#
# @param network           Subnetwork address.
# @param netmask           Subnetwork mask.
# @param router            IP address of the network router.
# @param domain            Domain name to assign to clients.
# @param dns_servers       Array of IP addresses of DNS servers. If ddns is used then first element is array must be primary DNS server.
# @param netbios_servers   Optional. Array of addresses of WINS-servers (if used).
# @param failover          If this subnet must be included into cluster configuration.
# @param failover_cluster  The name of cluster, fetched from main class.
# @param ddns              Boolean to say if DDNS updates are used for this subnet.
# @param ddns_zones        Array of zones that are served by the BIND server which are to be updated.
# @param ddns_primary      Reassign used by default first item of *dns_servers* array.
# @param ddns_key_name     Name of the rndc key, fetched from main class.
#
# @param next_server
#   IP address of pxe boot server where boot image resides. Can be defined on the subnet level (here)
#   or otherwise be specific for each pool and defined in a pool.
#
# @param ttl #   Default lease time and max lease time are set to this value.  #   Default: 43200 sec
#
# @param pools
#   Hash must contain the following keys:
#   - start: first IP of the range
#   - end:   last IP of the range
#   Can also contain keys:
#   - static_only: means that pool only serves the clients that are staticly declared
#   - pxe_enable:  override on per pool basis
#   - ttl
#
define dhcp::subnet (
  Stdlib::Ip::Address           $network,
  Stdlib::Ip::Address           $netmask,
  Stdlib::Ip::Address           $router,
  String                        $domain,
  Array[Stdlib::Ip::Address]    $dns_servers,
  Hash                          $pools,
  Array[Stdlib::Ip::Address]    $netbios_servers   = [],
  Boolean                       $failover          = $dhcp::failover,
  String                        $failover_cluster  = $dhcp::failover_cluster,
  Boolean                       $ddns              = false,
  Optional[Array[String]]       $ddns_zones        = undef,
  Optional[Stdlib::Ip::Address] $ddns_primary      = undef,
  String                        $ddns_key_name     = $dhcp::ddns_key_name,
  Numeric                       $ttl               = 43200,
  Boolean                       $pxe_enable        = false,
  Optional[Stdlib::Ip::Address] $next_server       = undef,
  String                        $bootfile_bios     = 'pxelinux.0',
  String                        $bootfile_efi_x64  = 'bootx64.efi',
  String                        $bootfile_efi_ia32 = 'syslinux.efi',
) {

  if $pxe_enable and ! $next_server {
    fail('Parameter next_server is required if pxe_enable is true')
  }

  $_ddns_zones = $ddns_zones ?
  {
    undef   => [$domain],
    default => $ddns_zones
  }

  $_ddns_primary = $ddns_primary ?
  {
    undef   => $dns_servers[0],
    default => $ddns_primary
  }

  if $pxe_enable {
    realize(Concat::Fragment["enable-pxe-in-${dhcp::params::maincfg}"])
  }

  if $ddns {
    realize(Concat::Fragment["enable-ddns-in-${dhcp::params::maincfg}"])

    concat::fragment { "ddns-zones-in-${network}-${netmask}":
      target  => $dhcp::params::maincfg,
      content => template('dhcp/dhcpd.conf_zones.erb'),
      order   => '04',
    }
  }

  concat::fragment { "subnet-${network}-${netmask}":
    target  => $dhcp::params::maincfg,
    content => template('dhcp/dhcpd.conf_subnet.erb'),
    order   => '05',
  }
}
