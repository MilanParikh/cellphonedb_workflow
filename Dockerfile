FROM python:3.8

SHELL ["/bin/sh", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV CELLPHONEDB_RELEASE_PATH=/opt/cellphonedb/releases
ENV R_OS_IDENTIFIER=debian-11
ENV R_VERSION=4.1.3
ENV LD_LIBRARY_PATH="/opt/R/${R_VERSION}/lib/R/lib:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-11-openjdk-amd64/lib/server"

# install OS packages
RUN apt-get update && \
    apt-get install -yq git wget gdebi-core build-essential software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
    apt-get update -y && apt-get install google-cloud-cli -y

# # install R
RUN wget -q "https://cdn.rstudio.com/r/${R_OS_IDENTIFIER}/pkgs/r-${R_VERSION}_1_amd64.deb" && \
    gdebi -n r-${R_VERSION}_1_amd64.deb && \
    rm -rf gdebi r-${R_VERSION}_1_amd64.deb && \
    ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript && \
    Rscript -e "install.packages(c('ggplot2','pheatmap'), repos='https://packagemanager.rstudio.com/all/latest')" 

# install CellphoneDB
RUN pip3 install cellphonedb --no-cache-dir && \
    cellphonedb database download

RUN ln -s /usr/bin/python3 /usr/bin/python