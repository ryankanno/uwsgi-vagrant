node default {
    class { "users": stage => "pre" }
    class { "python": stage => "py" }
    class { "application": }
}

stage { "pre": before => Stage["py"] }
class users {

    package { 
        'build-essential': ensure => latest;
        'libshadow': ensure => latest, provider => 'gem', require => Package["build-essential"];
    }
    
    group { "app":
        ensure => present,
        gid => 2000 
    }

    user { "uwsgi-app":
        ensure => present,
        gid => "app",
        groups => ["adm", "root"],
        managehome => true,
        password => '',
        shell => "/bin/bash",
        require => [Group["app"], Package["libshadow"]]
    }

    file { "/var/www":
        ensure => "directory",
        owner  => "vagrant",
        group  => "app",
        mode   => 755,
        require => Group["app"]
    }

    file { "/var/www/apps":
        ensure => "directory",
        owner  => "uwsgi-app",
        group  => "app",
        mode   => 755,
        require => [ Group["app"], User["uwsgi-app"] ] 
    }
}

stage { "py": before => Stage["main"] }
class python {
    package {
        "python-dev": ensure => "2.7.3-0ubuntu2";
        "python": ensure => "2.7.3-0ubuntu2";
        "python-setuptools": ensure => installed;
        "python-virtualenv": ensure => installed;
        "virtualenvwrapper": ensure => installed;
    }
}

class application {
    package {
        'git-core': ensure => installed;
        'uwsgi': ensure => installed;
        'uwsgi-plugin-python': ensure => installed, require => Package["uwsgi"];
        'libmysqlclient-dev': ensure => installed;
    }
    class { 'nginx': }
    class { 'mysql::server':
        config_hash => { 'root_password' => '' }
    }

    sudoers::user { uwsgi-app:
      ensure => present,
      nopasswd => true,
      commands => "ALL",
      require => [User["uwsgi-app"]]
    }
}
