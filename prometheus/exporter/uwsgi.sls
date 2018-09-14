{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user


uwsgi_exporter_tarball:
  archive.extracted:
    - name: {{ prometheus.exporters.uwsgi.install_dir }}
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

/etc/default/uwsgi_exporter:
  file.touch: []


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
    - template: jinja
    - defaults:
        args: {{ prometheus.exporters.uwsgi.args }}

uwsgi_exporter_service:
  service.running:
    - name: uwsgi_exporter
    - enable: True
    - reload: True
    - watch:
      - file: uwsgi_exporter_service_unit
      - file: uwsgi_exporter_bin_link
