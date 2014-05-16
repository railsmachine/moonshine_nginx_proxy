# moonshine_nginx_proxy

A moonshine plugin that installs, configures and manages [nginx](http://nginx.org) for use as a load balancer.  It supports:

* http
* https
* SPDY (only on Ubuntu 12.04 and greater)

Though it works and we're using it in production, we consider this plugin **beta** and only recommend you using it if you know what you're doing.

We're still experimenting with monitoring and don't have any recommendations on that at this time.

## Some Notes on SSL & SPDY

### Certificate Chains

If your certificate provider also provided a chain certificate, you need to combine them with your SSL certificate, following [these instructions](http://nginx.com/resources/admin-guide/nginx-ssl-termination), which are basically:

* <code>cat server.crt bundle.crt > server.combined.crt
* Use that as the value for <code>ssl_certificate</code>.

### SPDY

[SPDY](http://www.chromium.org/spdy) is a new (and still developing) standard for speeding up the serving of secure web pages.  In our testing, it reduced the load time of our pages by almost half.  Your results will definitely vary depending on how many external resources you load, whether they're coming from a SPDY-enabled server or CDN and a million other factors, but it's definitely interesting and worth trying out. 

There are a few caveats.  The main one is that it only works on Ubuntu 12.04 and up.  Ubuntu 10.04 uses an older version of OpenSSL that doesn't provide the features needed for SPDY.  If you're on 10.04, SPDY will be disabled no matter what option you have set.

The other one, and it's a big one, is that the standard is developing and developing quickly. The nginx folks have been quick to implement the new versions, but who knows where it will go and what will change - another reason this plugin is considered beta.

How do you test it?  Get the [SPDY Indicator](https://chrome.google.com/webstore/detail/spdy-indicator/mpbpobfflnpcgagjijhmgnchggcjblin) plugin for Chrome and when you've got SPDY working, you'll see a little green lightning bolt in the address bar.


## Configuration

Configuring nginx is a little complicated, and only recommended for multi-server deployments at this point (though it could be used for balancing unicorn or puma instances on a single server - but we haven't tested it).  

We use the configuration builders model from [moonshine_multi_server](https://github.com/railsmachine/moonshine_multi_server), but as an example, here's what the configuration would look like if you put everything in config/moonshine.yml:

```yaml
:nginx:
  :gzip: on
  :worker_processes: 1
  :worker_connections: 1024
  :servers:
  - :port: 80
    :domain_names: 
      - railsmachine.com
      - "*.railsmachine.com"
    :backend: app-servers
  - :port: 443
    :use_ssl: true
    :use_spdy: false
    :backend: app-servers
    :domain_names:
      - railsmachine.com
      - "*.railsmachine.com"
    :ssl_certificate: /srv/app/shared/config/ssl/cert.crt
    :ssl_certificate_key: /srv/app/shared/config/ssl/cert.key
  :backends:
    - :name: app-servers
      :balance_mode: least_conn
      :servers:
        - 10.0.10.2
        - 10.0.10.3
        - 10.0.10.4
  :error_pages:
    400: 400.html
    500: 500.html
    502: 503.html
    503: 503.html
    504: 503.html
```

Are we missing features or configuration options?  Fix it and submit a pull request!

***

Unless otherwise specified, all content copyright &copy; 2014, [Rails Machine, LLC](http://railsmachine.com)