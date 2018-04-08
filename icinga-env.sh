DEBIAN_SYS_MAINT_PASSWORD=icinga

## icinga add-ons + features
ICINGA2_FEATURE_GRAPHITE=false
ICINGA2_FEATURE_GRAPHITE_HOST=graphite
ICINGA2_FEATURE_GRAPHITE_PORT=2003
ICINGA2_FEATURE_GRAPHITE_URL=http://graphite.com
ICINGA2_FEATURE_GRAPHITE_METADATA=true

## forces internal nrpe to run
ICINGA2_FORCE_NRPE_V2=true

## other features to enable
ICINGA2_FEATURE_ENABLE_PERFDATA=true
ICINGA2_FEATURE_ENABLE_STATUSDATA=true

## icinga api credentials
ICINGA_API_PASSWORD=icingaadmin
DIRECTOR_KICKSTART=false

## for icinga web-portal login
ICINGAWEB2_ADMIN_USER=icingaadmin
ICINGAWEB2_ADMIN_PASS=icinga

## for icinga portal->db access
DEFAULT_MYSQL_HOST=mysql
DEFAULT_MYSQL_USER=icinga2
DEFAULT_MYSQL_PASS=testypassword

## custom environment variables
GOOGLE_APPLICATION_CREDENTIALS=/secrets/svc-monitoring.key.json

## mysql db default permissions
MYSQL_ROOT_PASSWORD=someotherfancypassword
MYSQL_USER=icinga2
MYSQL_PASSWORD=testypassword
