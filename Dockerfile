ARG ubuntu_ver=22.04

FROM ubuntu:$ubuntu_ver

ENV TZ UTC
ENV PRINTER lpr1
ENV USER_NAME lpadm
ENV USER_PASSWD lpadm

RUN <<EOT sh
  set -ex
  export DEBIAN_FRONTEND=noninteractive
  apt -y update
  apt -y install tzdata supervisor

  # Networking utilities
  apt -y install inetutils-ping net-tools ncat

  # Scanning/Printer related stuff
  apt -y install hplip
  cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.ubuntu

  # apache related stuff
  apt -y install apache2 haserl cron logrotate
  tee /etc/apache2/conf-available/mysite.conf <<-_EOF_
	  <Directory /www/>
	    Options Indexes FollowSymlinks
	    AllowOverride All
	    Options +ExecCGI
	    AddHandler cgi-script .cgi
	    Require all granted
	  </Directory>
	_EOF_
  sed -i -e 's|/var/www/html|/www|' /etc/apache2/sites-available/000-default.conf
  a2enconf mysite.conf
  a2dismod mpm_event
  a2enmod mpm_prefork
  a2enmod cgi

EOT

RUN <<EOT sh
  # Clean-up
  rm -rf /var/lib/apt/lists/*

EOT

ADD files.tar.gz /
EXPOSE 631/tcp 632/tcp 80/tcp
CMD [ "/startup.sh" ]
