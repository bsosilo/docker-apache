FROM ubuntu:bionic
MAINTAINER bsosilo <bsosilo@solusiti.com>

ENV OS_LOCALE="en_US.UTF-8"
RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}
ENV LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} \
    DEBIAN_FRONTEND=noninteractive

ENV APACHE_CONF_DIR=/etc/apache2 \
    PHP_CONF_DIR=/etc/php/5.6 \
    PHP_DATA_DIR=/var/lib/php \
    WINEDEBUG=fixme-all \
    WINEARCH=win32 \
    DISPLAY=:100
    
COPY entrypoint.sh /sbin/entrypoint.sh

RUN	\
	BUILD_DEPS='software-properties-common gnupg cabextract apt-transport-https' \
  && dpkg-reconfigure locales \
	&& apt-get install --no-install-recommends -y $BUILD_DEPS \
	&& add-apt-repository -y ppa:ondrej/php \
	&& add-apt-repository -y ppa:ondrej/apache2 \
	&& apt-get update \
  && apt-get install -y curl wget apache2 libapache2-mod-php5.6 php5.6-cli php5.6-readline php5.6-mbstring php5.6-zip php5.6-intl php5.6-xml php5.6-json php5.6-curl php5.6-gd php5.6-interbase php-pear \
  # Wine 32 bit, fonts and Xvfb install
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y --install-recommends wine32 xvfb \
  && wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb \
  && dpkg -i ttf-mscorefonts-installer_3.6_all.deb \
  && winecfg \
  && cp -R /root/.wine /var/www \
  && chown -R www-data:www-data /var/www/.wine \
  # Apache settings
  && cp /dev/null ${APACHE_CONF_DIR}/conf-available/other-vhosts-access-log.conf \
  && rm ${APACHE_CONF_DIR}/sites-enabled/000-default.conf ${APACHE_CONF_DIR}/sites-available/000-default.conf \
  && a2enmod rewrite php5.6 headers expires \
	# Cleaning
	&& apt-get purge -y --auto-remove $BUILD_DEPS \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	# Forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/apache2/access.log \
	&& ln -sf /dev/stderr /var/log/apache2/error.log \
	&& chmod 755 /sbin/entrypoint.sh \
	&& chown www-data:www-data ${PHP_DATA_DIR} -Rf

COPY ./configs/apache2.conf ${APACHE_CONF_DIR}/apache2.conf
COPY ./configs/app.conf ${APACHE_CONF_DIR}/sites-enabled/app.conf
COPY ./configs/php.ini  ${PHP_CONF_DIR}/apache2/conf.d/custom.ini

WORKDIR /var/www/html

EXPOSE 80 443

# By default, simply start apache.
CMD ["/sbin/entrypoint.sh"]