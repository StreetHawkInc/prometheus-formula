{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user


redis_exporter_tarball:
  archive.extracted:
    - name: {{ prometheus.exporters.redis.version_path}}
    - source: {{ prometheus.exporters.redis.source }}
    - source_hash: {{ prometheus.exporters.redis.source_hash }}
    - user: {{ prometheus.user }}
    - group: {{ prometheus.group }}
    - archive_format: tar
    - if_missing: {{ prometheus.exporters.redis.version_path }}
    - enforce_toplevel: False

redis_exporter_bin_link:
  file.symlink:
    - name: /usr/bin/redis_exporter
    - target: {{ prometheus.exporters.redis.version_path }}/redis_exporter
    - require:
      - archive: redis_exporter_tarball

redis_exporter_defaults:
  file.managed:
    - name: /etc/default/redis_exporter
    - source: salt://prometheus/files/default-redis_exporter.jinja
    - template: jinja
    - defaults:
        config: {{ prometheus.exporters.redis.args }}

redis_exporter_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/redis_exporter.service
    - source: salt://prometheus/files/redis_exporter.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/redis_exporter.conf
    - source: salt://prometheus/files/redis_exporter.upstart.jinja
{%- endif %}
    - require_in:
      - file: redis_exporter_service

redis_exporter_service:
  service.running:
    - name: redis_exporter
    - enable: True
    - reload: True
    - watch:
      - file: redis_exporter_service_unit
      - file: redis_exporter_defaults
      - file: redis_exporter_bin_link
