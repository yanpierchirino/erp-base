FROM debian:bullseye-slim
MAINTAINER Yan Chirino <support@yanchirino.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8


# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get clean && apt-get update && apt-get upgrade -y && apt-get install -y \
        --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        gettext-base \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION master
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_16.1alpha1.latest_all.deb \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./tmpl.conf /etc/odoo/

RUN ["chmod", "+x", "./entrypoint.sh"]

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt for users addons
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/src-addons \
    && mkdir -p /mnt/vendor-addons/OCA \
    && chown -R odoo /mnt
VOLUME ["/var/lib/odoo", "/mnt"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY ./wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN ["chmod", "+x", "/usr/local/bin/wait-for-psql.py"]

# Default environments
ENV ERP_ADDONS_PATH /mnt
ENV ERP_DATA_DIR /var/lib/odoo
ENV ERP_SERVER_WIDE_MODULES web,base
ENV ERP_LONGPOLLING_PORT 8072
ENV ERP_LOG_HANDLER [':INFO']
ENV ERP_CSV_INTERNAL_SEP ,
ENV ERP_XMLRPC True
ENV ERP_XMLRPC_PORT 8069
ENV ERP_XMLRPCS True
ENV ERP_XMLRPCS_PORT 8071

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]