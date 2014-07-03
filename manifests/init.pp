# vsftpd module
#
# == Parameters
#
#
#
#
class vsftpd (
  # initial trigger only
  $bool_listen = hiera('vsftpd::bool_listen', true),
  $bool_listen_ipv6 = hiera('vsftpd::bool_listen_ipv6', false),

  $bool_passive = hiera('vsftpd::bool_passive', true),

  $bool_chroot = hiera('vsftpd::bool_chroot', true),

  $bool_vuser = hiera('vsftpd::bool_vuser', false),

  $bool_log = hiera('vsftpd::bool_log', true),
  ) {
  ## set some value
  $anon_root = hiera('vsftpd::anon_root', '/srv/ftp/pub')
  $local_root = hiera('vsftpd::local_root', '/srv/ftp/pub')

  $listen = $bool_listen ? {
    true => 'YES',
    false => 'NO',
  }

  if $bool_listen {
    $listen_port = hiera('vsftpd::listen_port', '2121')
  }

  $listen_ipv6 = $bool_listen_ipv6 ? {
    true => 'YES',
    false => 'NO',
  }

  if $bool_passive {
    $pasv_max_port = hiera('vsftpd::pasv_max_port', '60100')
    $pasv_min_port = hiera('vsftpd::pasv_min_port', '60000')
    $pasv_address = hiera('vsftpd::pasv_address', undef)
  } else {
    $connect_from_port_20 = 'YES'
  }

  if $bool_chroot {
    $chroot_local_user = 'YES'
    $secure_chroot_dir = hiera('vsftpd::secure_chroot_dir', '/var/run/vsftpd/empty')
  }

  if $bool_vuser {
    $local_enable = 'YES'
    $guest_enable = 'YES'
    $guest_username = hiera('vsftpd::guest_username', 'ftp')
    $pam_service_name = hiera('vsftpd::pam_service_name', 'vsftpd')
    $main_config_dir = hiera('vsftpd::main_config_dir', '/etc/vsftpd')
    $user_config_dir = hiera('vsftpd::user_config_dir', 'vsftpd_user_conf')
    $vsftpd_db_file = hiera('vsftpd::vsftpd_db_file', 'vsftpd_login')
    $vsftpd_pwd_file = hiera('vsftpd::vsftpd_pwd_file', 'vsftpduser')
    $anon_umask = hiera('vsftpd::anon_umask', '022')
  }

  if $bool_log {
    $xferlog_enable = 'YES'
    $vsftpd_log_file = hiera('vsftpd::vsftpd_log_file', '/var/log/vsftpd.log')
  }

  package { 'vsftpd':
    ensure => installed,
  }

  service { 'vsftpd':
    require => Package['vsftpd'],
    ensure => running,
    enable => true,
  }

  exec { '/etc/init.d/vsftpd restart':
    alias => 'vsftpd_restart',
    require => Service['vsftpd'],
    refreshonly => true,
  }

  file { '/etc/vsftpd.conf':
    require => Package['vsftpd'],
    notify  => Exec['vsftpd_restart'],
    content  => template('vsftpd/vsftpd.conf.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  if $bool_vuser {
    package { 'libpam-modules':
      ensure => installed,
    }

    package { 'libpam-pwdfile':
      ensure => installed,
    }

    ## pam setting
    file { "/etc/pam.d/${pam_service_name}":
      require => Package['vsftpd'],
      content => template('vsftpd/vsftpd-pam.erb'),
      mode => '0644',
      owner => 'root',
      group => 'root',
    }

    ## directory
    file { "${main_config_dir}":
      alias => 'vsftpd-confd',
      require => Package['vsftpd'],
      ensure => directory,
      mode => '0644',
      owner => 'root',
      group => 'root',
    }

    ## directory
    file { "${main_config_dir}/${user_config_dir}":
      require => File['vsftpd-confd'],
      ensure => directory,
      mode => '0644',
      owner => 'root',
      group => 'root',
      recurse => true,
    }

    ## TODO: user configs
  }
  }
