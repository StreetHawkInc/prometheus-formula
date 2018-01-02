{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user

postgres_exporter_tarball:
  archive.extracted:
    - name: {{ prometheus.exporters.postgres.install_dir }}
    - source: {{ prometheus.exporters.postgres.source }}
    - source_hash: {{ prometheus.exporters.postgres.source_hash }}
    - user: {{ prometheus.user }}
    - group: {{ prometheus.group }}
    - archive_format: tar
    - if_missing: {{ prometheus.exporters.postgres.version_path }}

postgres_exporter_bin_link:
  file.symlink:
    - name: /usr/bin/postgres_exporter
    - target: {{ prometheus.exporters.postgres.version_path }}/postgres_exporter
    - require:
      - archive: postgres_exporter_tarball

postgres_exporter_defaults:
  file.managed:
    - name: /etc/default/postgres_exporter
    - source: salt://prometheus/files/default-postgres_exporter.jinja
    - template: jinja
    - defaults:
        args: {{ prometheus.exporters.postgres.args }}

postgres_exporter_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/postgres_exporter.service
    - source: salt://prometheus/files/postgres_exporter.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/postgres_exporter.conf
    - source: salt://prometheus/files/postgres_exporter.upstart.jinja
{%- endif %}
    - require_in:
      - file: postgres_exporter_service

postgres_exporter_service:
  service.running:
    - name: postgres_exporter
    - enable: True
    - reload: True
    - watch:
      - file: postgres_exporter_service_unit
      - file: postgres_exporter_defaults
      - file: postgres_exporter_bin_link
