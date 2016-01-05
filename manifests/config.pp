# == Class consul::config
#
# This class is called from consul::init to install the config file.
#
# == Parameters
#
# [*config_hash*]
#   Hash for Consul to be deployed as JSON
#
# [*purge*]
#   Bool. If set will make puppet remove stale config files.
#
class consul::config(
  $config_hash,
  $purge = true,
) {

  if $consul::init_style {

    case $consul::init_style {
      'upstart' : {
        file { '/etc/init/consul.conf':
          mode    => '0444',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.upstart.erb'),
          notify  => $consul::notify_service,
        }
        file { '/etc/init.d/consul':
          ensure => link,
          target => '/lib/init/upstart-job',
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
          notify => $consul::notify_service,
        }
      }
      'systemd' : {
        file { '/lib/systemd/system/consul.service':
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.systemd.erb'),
        } ~>
        exec { 'consul-systemd-reload':
          command     => 'systemctl daemon-reload',
          path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
          refreshonly => true,
          notify      => $consul::notify_service,
        }
      }
      'sysv' : {
        file { '/etc/init.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.sysv.erb'),
          notify  => $consul::notify_service,
        }
      }
      'debian' : {
        file { '/etc/init.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.debian.erb'),
          notify  => $consul::notify_service,
        }
      }
      'sles' : {
        file { '/etc/init.d/consul':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.sles.erb'),
          notify  => $consul::notify_service,
        }
      }
      'launchd' : {
        file { '/Library/LaunchDaemons/io.consul.daemon.plist':
          mode    => '0644',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul/consul.launchd.erb'),
          notify  => $consul::notify_service,
        }
      }
      default : {
        fail("I don't know how to create an init script for style ${consul::init_style}")
      }
    }
  }

  file { $consul::config_dir:
    ensure  => 'directory',
    owner   => $consul::user,
    group   => $consul::group,
    purge   => $purge,
    recurse => $purge,
    notify  => $consul::notify_service,
  } ->
  file { "${consul::config_dir}/extras":
    ensure  => 'directory',
    owner   => $consul::user,
    group   => $consul::group,
    purge   => $purge,
    recurse => $purge,
    notify  => Class['consul::reload_service'],
  } ->
  file { 'consul config.json':
    ensure  => present,
    path    => "${consul::config_dir}/config.json",
    owner   => $consul::user,
    group   => $consul::group,
    mode    => $consul::config_mode,
    content => consul_sorted_json($config_hash, $consul::pretty_config, $consul::pretty_config_indent),
    notify  => $consul::notify_service,
  }

}
