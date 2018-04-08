# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM debian:stretch

MAINTAINER Jordan Jethwa

ENV APACHE2_HTTP=REDIRECT \
    ICINGA2_FEATURE_GRAPHITE=false \
    ICINGA2_FEATURE_GRAPHITE_HOST=graphite \
    ICINGA2_FEATURE_GRAPHITE_PORT=2003 \
    ICINGA2_FEATURE_GRAPHITE_URL=http://graphite \
    ICINGA2_USER_FULLNAME="Icinga2" \
    ICINGA2_FEATURE_DIRECTOR="true" \
    ICINGA2_FEATURE_DIRECTOR_KICKSTART="true" \
    ICINGA2_FEATURE_DIRECTOR_USER="icinga2-director"

RUN export DEBIAN_FRONTEND=noninteractive \
     && apt-get update \
     && apt-get upgrade -y \
     && apt-get install -y --no-install-recommends \
          apache2 \
          ca-certificates \
          curl \
          dnsutils \
          gnupg \
          locales \
          lsb-release \
          mailutils \
          mariadb-client \
          mariadb-server \
          php-curl \
          php-ldap \
          php-mysql \
          procps \
          pwgen \
          snmp \
          ssmtp \
          sudo \
          supervisor \
          unzip \
          wget \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

RUN export DEBIAN_FRONTEND=noninteractive \
     && curl -s https://packages.icinga.com/icinga.key \
     | apt-key add - \
     && echo "deb http://packages.icinga.org/debian icinga-$(lsb_release -cs) main" > /etc/apt/sources.list.d/icinga2.list \
     && export DEBIAN_FRONTEND=noninteractive \
     && apt-get update \
     && apt-get install -y --no-install-recommends \
          icinga2 \
          icinga2-ido-mysql \
          icingacli \
          icingaweb2 \
          monitoring-plugins \
          nagios-nrpe-plugin \
          nagios-snmp-plugins \
          nagios-plugins-contrib \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

ARG GITREF_ICINGAWEB2=master
ARG GITREF_DIRECTOR=master
ARG GITREF_MODGRAPHITE=master
ARG GITREF_MODAWS=master

# Temporary hack to get icingaweb2 modules via git
RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2/archive/${GITREF_ICINGAWEB2}.tar.gz" \
    | tar xz --strip-components=2 --directory=/usr/local/share/icingaweb2/modules -f - icingaweb2-${GITREF_ICINGAWEB2}/modules/monitoring icingaweb2-${GITREF_ICINGAWEB2}/modules/doc \
# Icinga Director
    && mkdir -p /usr/local/share/icingaweb2/modules/director/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/${GITREF_DIRECTOR}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
# Icingaweb2 Graphite
    && mkdir -p /usr/local/share/icingaweb2/modules/graphite \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-graphite/archive/${GITREF_MODGRAPHITE}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/graphite -f - icingaweb2-module-graphite-${GITREF_MODGRAPHITE}/ \
# Icingaweb2 AWS
    && mkdir -p /usr/local/share/icingaweb2/modules/aws \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-aws/archive/${GITREF_MODAWS}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/aws -f - icingaweb2-module-aws-${GITREF_MODAWS}/ \
    && wget -q --no-cookies "https://github.com/aws/aws-sdk-php/releases/download/2.8.30/aws.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/aws/library/vendor/aws aws.zip \
    && rm aws.zip \
    && true

ADD content/ /

# Final fixes
RUN true \
    && sed -i 's/vars\.os.*/vars.os = "Docker"/' /etc/icinga2/conf.d/hosts.conf \
    && mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mkdir /etc/icingaweb2 \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && rm -rf \
        /var/lib/mysql/* \
    && chmod u+s,g+s \
        /bin/ping \
        /bin/ping6 \
        /usr/lib/nagios/plugins/check_icmp

EXPOSE 80 443 5665

#########################
### KENTIK-FORK #########
#########################

RUN apt-get update && apt-get install -y \
  libwww-perl \
  libcrypt-ssleay-perl \
  libsys-syslog-perl \
  python-pip \
  python-dev \
  lsof \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

## INTEGRATIONS
ADD https://raw.github.com/PagerDuty/pagerduty-icinga-pl/master/pagerduty_icinga.pl /usr/local/bin/
ADD https://raw.githubusercontent.com/OpenTSDB/opentsdb/master/tools/check_tsd /usr/local/bin/
ADD https://raw.githubusercontent.com/timdaman/check_docker/master/check_docker /usr/local/bin/
COPY extra/send2slack.py /usr/local/bin/

RUN chmod 755 /usr/local/bin/pagerduty_icinga.pl
RUN chmod 755 /usr/local/bin/check_tsd
RUN chmod 755 /usr/local/bin/check_docker
RUN chmod 755 /usr/local/bin/send2slack.py
RUN mkdir -p /etc/icinga2-plugins

# install some other goodies
COPY extra/css-themes/Dark.less /usr/share/icingaweb2/public/css/themes/

# dockerception
RUN mkdir /root/docker.info
COPY * /root/docker.info/

#########################
### KENTIK-FORK #########
#########################

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
