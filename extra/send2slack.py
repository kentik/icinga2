#!/usr/bin/env python
# This script sends an Icinga message to Slack. Set the message icon based
# on Icinga service or host state.

import os
import sys
import json
import ConfigParser
import requests
impo

class Slack:
    config = None
    url = None

    def __init__(self, config):
        self.config = config
        self.url = self.get_url()

    def get_url(self):
        if 'SLACKAPITOKEN' in os.environ:
            token = os.environ['SLACKAPITOKEN']
        else:
            try:
              token = self.config.get('config', 'SLACKAPITOKEN')
            except ConfigParser.NoOptionError:
              print str(err)
        if token == None:
            sys.exit('The variable SLACKAPITOKEN must be defined in environment or send2slack.conf.')
        return 'https://hooks.slack.com/services/%s' % (token)

    def post(self, payload):
        try:
            res = requests.post(self.url, data=json.dumps(payload))
        except Exception as e:
            sys.stderr.write(
                'Error Delivering Message:\n\t{0}'.format(e.message))
            sys.exit(2)
        if not res.ok:
            sys.stderr.write('Error. Response:\n\t{0}'.format(res.text))
        return


class Icinga:
    service_state = 'OK'
    service_icon = ':greencheck:'
    host_name = 'UnspecifiedHost'
    host_state = 'UP'
    service_display_name = 'UnspecifiedService'
    service_output = 'Unspecified output to send2slack.py'
    icinga_host = None
    icinga_url = None
    channel = 'monitoringnoise'
    config = None


    def __init__(self, config):
        self.config = config
        self.set_defaults()
        self.channel

    def set_defaults(self):
        # Set  defaults
        if 'SERVICESTATE' in os.environ:
            self.service_state = os.environ['SERVICESTATE']
        if 'HOSTNAME' in os.environ:
            self.host_name = os.environ['HOSTNAME']
        if 'HOSTSTATE' in os.environ:
            self.host_state = os.environ['HOSTSTATE']
        if 'SERVICEDISPLAYNAME' in os.environ:
            self.service_display_name = os.environ['SERVICEDISPLAYNAME']
        if 'SERVICEOUTPUT' in os.environ:
            self.service_output = os.environ['SERVICEOUTPUT']
        if 'ICINGAHOST' in os.environ:
            self.icinga_host = os.environ['ICINGAHOST']
        else:
           try:
              self.icinga_host = self.config.get('config', 'ICINGAHOST')
           except ConfigParser.NoOptionError, err:
              print str(err)
        if self.icinga_host == None:
            sys.exit('The variable ICINGAHOST must be defined in environment or send2slack.conf.')
        if 'SLACKCHANNEL' in os.environ:
            self.icinga_host = os.environ['SLACKCHANNEL']
        else:
           try:
              self.icinga_host = self.config.get('config', 'SLACKCHANNEL')
           except ConfigParser.NoOptionError, err:
              print str(err)
              print "Using default channel #%s" % self.channel
        return

    def get_state_icon(self):
        icon = {
            'CRITICAL': ':redsiren:',
            'WARNING': ':warning:',
            'OK': ':greencheck:',
            'UNKNOWN': ':grey_question:',
            'DOWN': ':chart_with_downwards_trend:'
        }
        if self.host_state == "DOWN":
            self.service_icon = get_state_icon(os.environ['HOSTSTATE'])
        return icon.get(self.service_state, ':slack:')

    def get_icinga_url(self):
        print(self.icinga_host)
        return ("https://%s/icingaweb2/monitoring/list/hosts#!/icingaweb2/monitoring/host/show?host=%s" % (self.icinga_host, self.host_name))

    def get_payload(self):
        payload = {
            'channel': '#' + self.channel,
            'username': 'Icinga on %s' % self.icinga_host,
            'icon_emoji': ':icinga:',
            'text': "%s  <%s|%s> %s : %s" % (
                self.get_state_icon(),
                self.get_icinga_url(),
                self.host_name,
                self.service_display_name,
                self.service_output,
            )
        }
        return payload

config = ConfigParser.ConfigParser()
config.readfp(open(r'/etc/icinga2-plugins/send2slack.conf'))
slack = Slack(config)
icinga = Icinga(config)
slack.post(icinga.get_payload())
