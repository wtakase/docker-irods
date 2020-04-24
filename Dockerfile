FROM centos:7.7.1908
MAINTAINER wtakase <wataru.takase@kek.jp>

RUN yum install -y git sudo
RUN useradd irods-deploy && \
    echo "irods-deploy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER irods-deploy
ENV HOME /home/irods-deploy
WORKDIR $HOME

ENV IRODS_EXTERNALS $HOME/irods-externals
RUN git clone https://github.com/irods/externals $IRODS_EXTERNALS && \
    cd $IRODS_EXTERNALS && \
    git checkout 4.2.7 && \
    sed -i -r "s/'(rvm reload.*)'$/'bash -l -c \"\1\"'/g" install_prerequisites.py
WORKDIR $IRODS_EXTERNALS
RUN ./install_prerequisites.py
ENV PATH $IRODS_EXTERNALS/cmake3.5.2-0/bin:$IRODS_EXTERNALS/clang3.8-0/bin:$PATH
ENV LD_LIBRARY_PATH $IRODS_EXTERNALS/boost1.60.0-0/lib:$IRODS_EXTERNALS/clang-runtime3.8-0/lib:$LD_LIBRARY_PATH
RUN bash -l -c "make server"

ENV IRODS_SRC_DIR $HOME/irods-src
ENV IRODS_INSTALL_DIR $HOME/irods
RUN git clone https://github.com/irods/irods $IRODS_SRC_DIR && \
    cd $IRODS_SRC_DIR && \
    git checkout 4.2.6 && \
    git submodule update --init && \
    mkdir build
WORKDIR $IRODS_SRC_DIR/build
RUN sudo yum install -y pam-devel unixODBC-devel
RUN cmake -DCMAKE_INSTALL_PREFIX=$IRODS_INSTALL_DIR \
          -DIRODS_EXTERNALS_PACKAGE_ROOT=$IRODS_EXTERNALS ../
RUN make -j`nproc` non-package-install-postgres

WORKDIR $IRODS_INSTALL_DIR/var/lib/irods
RUN sudo yum install -y python2-psutil postgresql-odbc
ENV LD_LIBRARY_PATH $IRODS_INSTALL_DIR/usr/lib:$LD_LIBRARY_PATH

CMD ["python", "./scripts/setup_irods.py"]
