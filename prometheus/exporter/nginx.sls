{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user


nginx_exporter_binary:
  file.managed:
    - name: {{ prometheus.exporters.nginx.version_path}}
    - source: {{ prometheus.exporters.nginx.source }}
    - source_hash: {{ prometheus.exporters.nginx.source_hash }}
    - user: {{ prometheus.user }}
    - group: {{ prometheus.group }}
    - archive_format: tar
    - if_missing: {{ prometheus.exporters.nginx.version_path }}
    - enforce_toplevel: False

nginx_exporter_bin_link:
  file.symlink:
    - name: /usr/bin/nginx_exporter
    - target: {{ prometheus.exporters.nginx.version_path }}/nginx_exporter
    - require:
      - archive: nginx_exporter_tarball

nginx_exporter_defaults:
  file.managed:
    - name: /etc/default/nginx_exporter
    - source: salt://prometheus/files/default-nginx_exporter.jinja
    - template: jinja
    - defaults:
        config: {{ prometheus.exporters.nginx.args }}

nginx_exporter_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/nginx_exporter.service
    - source: salt://prometheus/files/nginx_exporter.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/nginx_exporter.conf
    - source: salt://prometheus/files/nginx_exporter.upstart.jinja
{%- endif %}
    - require_in:
      - file: nginx_exporter_service

nginx_exporter_service:
  service.running:
    - name: nginx_exporter
    - enable: True
    - reload: True
    - watch:
      - file: nginx_exporter_service_unit
      - file: nginx_exporter_defaults
      - file: nginx_exporter_bin_link
