# == Class consul::service
#
# This class is meant to be called from consul
# It ensure the service is running
#
class consul::run_service {

  $init_selector = $consul::init_style ? {
    'launchd' => 'io.consul.daemon',
    default   => 'consul',
  }

  if $consul::manage_service == true {
    service { 'consul':
      ensure   => $consul::service_ensure,
      name     => $init_selector,
      enable   => $consul::service_enable,
      # make the provider explicit to work around what appears to be a bug
      # in Puppet on Ubuntu 15.10.  TODO: try this without explicitly
      # specifying the provider after packages are released by Puppetlabs
      # for Puppet on Ubuntu 15.10 or later
      provider => $consul::init_style,
    }
  }

  if $consul::join_wan {
    exec { 'join consul wan':
      cwd       => $consul::config_dir,
      path      => [$consul::bin_dir,'/bin','/usr/bin'],
      command   => "consul join -wan ${consul::join_wan}",
      unless    => "consul members -wan -detailed | grep -vP \"dc=${consul::config_hash_real['datacenter']}\" | grep -P 'alive'",
      tries     => 6,  # consul commands fail if it hasn't completed startup
      try_sleep => 5,
      subscribe => Service['consul'],
    }
  }

}
