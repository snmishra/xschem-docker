FROM centos:8 AS xschem-build

COPY . /src

WORKDIR /src

RUN dnf groupinstall -y "Development Tools" && \
    dnf install -y rpmdevtools 'dnf-command(builddep)' git && \
    dnf builddep -y /src/xschem.spec && spectool -g -A xschem.spec

RUN groupadd -g 1001 -r build && useradd --no-log-init -r -m -u 1001 -g build build

USER build

WORKDIR /home/build

RUN rpmdev-setuptree && \
    rpmbuild -D '_sourcedir /src' -ba /src/xschem.spec

FROM centos:8

RUN groupadd -g 1001 -r app && useradd --no-log-init -r -m -u 1001 -g app app

WORKDIR /app

COPY --from=xschem-build /home/build/rpmbuild/RPMS RPMS

COPY start.sh /start.sh

RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --add-repo https://dl.bintray.com/tigervnc/stable/el7/RPMS/ && \
    dnf install -y tigervnc-server tigervnc-server-minimal \
    RPMS/x86_64/xschem*rpm RPMS/noarch/xschem*rpm && \
    rm -rf RPMS && (echo | vncpasswd -f) && chmod +x /start.sh

EXPOSE 5901

USER app
CMD ["/start.sh"]
