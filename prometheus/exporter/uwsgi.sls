{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user


uwsgi_exporter_tarball:
  archive.extracted:
    - name: {{ prometheus.exporters.uwsgi.version_path}}
    - source: {{ prometheus.exporters.uwsgi.source }}
    - source_hash: {{ prometheus.exporters.uwsgi.source_hash }}
    - user: {{ prometheus.user }}
    - group: {{ prometheus.group }}
    - archive_format: tar
    - if_missing: {{ prometheus.exporters.uwsgi.version_path }}
    - enforce_toplevel: False

uwsgi_exporter_bin_link:
  file.symlink:
    - name: /usr/bin/uwsgi_exporter
    - target: {{ prometheus.exporters.uwsgi.version_path }}/uwsgi_exporter
    - require:
      - archive: uwsgi_exporter_tarball

uwsgi_exporter_defaults:
  file.managed:
    - name: /etc/default/uwsgi_exporter
    - source: salt://prometheus/files/default-uwsgi_exporter.jinja
    - template: jinja
    - defaults:
        config: {{ prometheus.exporters.uwsgi.args }}

uwsgi_exporter_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/uwsgi_exporter.service
    - source: salt://prometheus/files/uwsgi_exporter.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/uwsgi_exporter.conf
    - source: salt://prometheus/files/uwsgi_exporter.upstart.jinja
{%- endif %}
    - require_in:
      - file: uwsgi_exporter_service

uwsgi_exporter_service:
  service.running:
    - name: uwsgi_exporter
    - enable: True
    - reload: True
    - watch:
      - file: uwsgi_exporter_service_unit
      - file: uwsgi_exporter_defaults
      - file: uwsgi_exporter_bin_link