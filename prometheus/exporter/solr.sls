{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user

solr_exporter_tarball:
  archive.extracted:
    - name: {{ prometheus.exporters.solr.install_dir }}
    - source: {{ prometheus.exporters.solr.source }}
    - source_hash: {{ prometheus.exporters.solr.source_hash }}
    - user: {{ prometheus.user }}
    - group: {{ prometheus.group }}
    - archive_format: tar
    - if_missing: {{ prometheus.exporters.solr.version_path }}

solr_exporter_bin_link:
  file.symlink:
    - name: /usr/bin/solr_exporter
    - target: {{ prometheus.exporters.solr.version_path }}/solr_exporter
    - require:
      - archive: solr_exporter_tarball

solr_exporter_defaults:
  file.managed:
    - name: /etc/default/solr_exporter
    - source: salt://prometheus/files/default-solr_exporter.jinja
    - template: jinja
    - defaults:
        scrape_uri: {{ prometheus.exporters.solr.args.scrape_uri }}

solr_exporter_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/solr_exporter.service
    - source: salt://prometheus/files/solr_exporter.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/solr_exporter.conf
    - source: salt://prometheus/files/solr_exporter.upstart.jinja
{%- endif %}
    - require_in:
      - file: solr_exporter_service

solr_exporter_service:
  service.running:
    - name: solr_exporter
    - enable: True
    - reload: True
    - watch:
      - file: solr_exporter_service_unit
      - file: solr_exporter_defaults
      - file: solr_exporter_bin_link
