FROM --platform=linux/amd64 debian:bullseye-slim
LABEL maintainer="Yan Chirino <support@yanchirino.com>"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG C.UTF-8
ENV ODOO_VERSION 17.0
ENV ODOO_SOURCE_DIR=/opt/odoo

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get clean && apt-get update && apt-get upgrade -y && apt-get install -y \
        --no-install-recommends \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libsqlite3-dev \
        libpq-dev \
        libsasl2-dev \
        libldap2-dev \
        gcc \
        wget \
        libbz2-dev \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        node-less \
        npm \
        git \
        gettext-base \
        xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install python 3.10
# Establece Python 3.10 como la versión predeterminada
RUN wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
RUN tar -xvf Python-3.10.0.tgz && cd Python-3.10.0 && ./configure --enable-optimizations && make -j 4 && make altinstall
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 1
RUN update-alternatives --config python3

RUN apt-get clean && apt-get update && apt-get upgrade -y && apt-get install -y \
        --no-install-recommends \
        python3-dev \
        python3-pip \
        python3-num2words \
        python3-pdfminer \
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
        python3-pylibdmtx \
        && rm -rf /var/lib/apt/lists/*

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

# Instalar y configurar Odoo desde el repositorio de GitHub
RUN git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo ${ODOO_SOURCE_DIR}
RUN echo "alias odoo='python3 /opt/odoo/odoo-bin'" >> ~/.bashrc

# Dependencias de Python necesarias
RUN python3 -m pip install pip==20.3.4
RUN pip install --upgrade setuptools
RUN pip install -r requirements.txt

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
ENV ERP_GEVENT_PORT 8072
ENV ERP_LOG_HANDLER [':INFO']
ENV ERP_CSV_INTERNAL_SEP ,
ENV ERP_XMLRPC True
ENV ERP_XMLRPC_PORT 8069
ENV ERP_XMLRPCS True
ENV ERP_XMLRPCS_PORT 8071

# Set default user when running the container
RUN usermod -aG sudo odoo
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]