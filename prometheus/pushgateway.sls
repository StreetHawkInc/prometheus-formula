{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user

pushgateway_tarball:
  archive.extracted:
    - name: {{ prometheus.pushgateway.install_dir }}
    - source: {{ prometheus.pushgateway.source }}
    - source_hash: {{ prometheus.pushgateway.source_hash }}
    - archive_format: tar
    - if_missing: {{ prometheus.pushgateway.version_path }}

pushgateway_bin_link:
  file.symlink:
    - name: /usr/bin/pushgateway
    - target: {{ prometheus.pushgateway.version_path }}/pushgateway
    - require:
      - archive: pushgateway_tarball

pushgateway_defaults:
  file.managed:
    - name: /etc/default/pushgateway
    - source: salt://prometheus/files/default-pushgateway.jinja
    - template: jinja
    - defaults:
        config_file: {{ prometheus.pushgateway.args.config_file }}
        storage_path: {{ prometheus.pushgateway.args.storage.path }}

pushgateway_storage_path:
  file.directory:
    - name: {{ prometheus.pushgateway.args.storage.path }}
    - user: {{ prometheus.user }}
    - group: {{ prometheus.group }}
    - makedirs: True
    - watch:
      - file: pushgateway_defaults

pushgateway_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/pushgateway.service
    - source: salt://prometheus/files/pushgateway.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/pushgateway.conf
    - source: salt://prometheus/files/pushgateway.upstart.jinja
{%- endif %}
    - watch:
      - file: pushgateway_defaults
    - require_in:
      - file: pushgateway_service

pushgateway_service:
  service.running:
    - name: pushgateway
    - enable: True
    - reload: True
    - watch:
      - file: pushgateway_service_unit
      - file: pushgateway_bin_link
