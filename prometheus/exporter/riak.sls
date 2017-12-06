{% from "prometheus/map.jinja" import prometheus with context %}

include:
  - prometheus.user

riak_exporter_pip:
  pip.installed:
    - name: https://github.com/anti1869/riak_exporter.git

riak_exporter_defaults:
  file.managed:
    - name: /etc/default/rabbitmq_exporter
    - source: salt://prometheus/files/default-riak_exporter.jinja
    - template: jinja
    - defaults:
        config: {{prometheus.exporters.riak.args}}

riak_exporter_service_unit:
  file.managed:
{%- if grains.get('init') == 'systemd' %}
    - name: /etc/systemd/system/riak_exporter.service
    - source: salt://prometheus/files/riak_exporter.systemd.jinja
{%- elif grains.get('init') == 'upstart' %}
    - name: /etc/init/riak_exporter.conf
    - source: salt://prometheus/files/riak_exporter.upstart.jinja
{%- endif %}
    - require_in:
      - file: riak_exporter_service

riak_exporter_service:
  service.running:
    - name: riak_exporter
    - enable: True
    - reload: True
    - watch:
      - file: riak_exporter_service_unit
      - file: riak_exporter_defaults
      - pip: riak_exporter_pip
