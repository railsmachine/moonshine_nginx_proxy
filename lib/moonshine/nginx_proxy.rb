module Moonshine
  module NginxProxy
    
    def nginx
      raise "There's no nginx configuration in config/moonshine.yml or the stage config" if configuration[:nginx].nil?
      recipe :nginx_package
      recipe :nginx_config
      recipe :nginx_service
    end
  
    def nginx_package
      if ubuntu_lucid?
        release_name = "lucid"
      elsif ubuntu_precise?
        release_name = "precise"
      elsif ubuntu_trusty?
        release_name = "trusty"
      end
    
      file "/etc/apt/sources.list.d/nginx.list",
        content: "deb http://nginx.org/packages/mainline/ubuntu/ #{release_name} nginx",
        owner: 'root',
        ensure: :present

      user 'nginx',
        shell: '/bin/false',
        ensure: :present,
        home: "/nonexistant",
        managehome: false

      file "/etc/apt/preferences.d/nginx-900",
        content: template(File.join(File.dirname(__FILE__), '..', '..', 'templates', "nginx-preference")),
        owner: 'root',
        ensure: :present

      exec "download nginx repo key",
        cwd: "/tmp",
        command: "wget http://nginx.org/keys/nginx_signing.key",
        creates: "/tmp/nginx_signing.key"
    
      exec "add nginx repo key",
        command: "sudo apt-key add /tmp/nginx_signing.key",
        require: exec("download nginx repo key"),
        unless: "sudo apt-key list | grep 'nginx signing key'"
    
      exec "nginx apt-get update",
        command: "sudo apt-get update",
        require: [file("/etc/apt/sources.list.d/nginx.list"), exec("add nginx repo key")],
        unless: "sudo dpkg -l | grep nginx"
    
      package "nginx", 
        ensure: :installed,
        require: [exec("nginx apt-get update"), file('/etc/apt/preferences.d/nginx-900')]
    end
  
    def nginx_config
      file "/etc/nginx",
        ensure: :directory,
        owner: "root",
        require: [package("nginx")]
        
      file "/etc/nginx/conf.d",
        ensure: :directory,
        owner: "root",
        require: file("/etc/nginx")
      
      file "/etc/nginx/conf.d/default.conf",
        ensure: :absent,
        notify: service('nginx')
        
      file "/etc/nginx/conf.d/example_ssl.conf",
        ensure: :absent,
        notify: service('nginx')
    
      file "/etc/nginx/nginx.conf",
        content: template(File.join(File.dirname(__FILE__), '..', '..', 'templates', "nginx.conf.erb")),
        require: [package("nginx"), file("/etc/nginx")],
        notify: service('nginx')
      
      file "/etc/nginx/conf.d/backends.conf",
        content: template(File.join(File.dirname(__FILE__), '..', '..', 'templates', "backends.conf.erb")),
        require: [package("nginx"), file("/etc/nginx/conf.d")],
        notify: service('nginx')
    
      file "/etc/nginx/conf.d/moonshine.conf",
        content: template(File.join(File.dirname(__FILE__), '..', '..', 'templates', "nginx_moonshine.conf.erb")),
        require: [package("nginx"), file("/etc/nginx/conf.d")],
        notify: service('nginx')
    
      if configuration[:nginx][:servers].nil? || configuration[:nginx][:servers].empty?
        raise "You must have at least one frontend server to proxy. Set :nginx: :servers: to an array in your Moonshine configuration."
      end
    
      configuration[:nginx][:servers].each do |server|
        file "/etc/nginx/conf.d/frontend.#{server[:port]}.conf",
          content: template(File.join(File.dirname(__FILE__), '..', '..', 'templates', "nginx_server.conf.erb"), binding),
          owner: 'root',
          notify: [service("nginx"), user('nginx')]
      end
    
    end
  
    def nginx_service
      service 'nginx',
        enable: true,
        provider: :upstart,
        ensure: :running,
        require: package("nginx")
    end
    
  end
end