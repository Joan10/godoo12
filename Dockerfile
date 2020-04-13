FROM odoo:12.0
MAINTAINER Gotes, S.COOP <info@gotes.org>

USER root
COPY odoo.conf /etc/odoo/odoo.conf
RUN apt-get -y update
RUN apt-get -y install gcc git libxmlsec1-dev pkg-config python3-dev
RUN pip3 install wheel pyOpenSSL zeep
ADD spain-addons /opt/spain-addons
RUN pip3 install -r /opt/spain-addons/requirements.txt 
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb
RUN apt-get clean
USER odoo
