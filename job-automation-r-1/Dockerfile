FROM r-base:3.5.0

RUN apt-get update
RUN apt-get install -y --fix-missing openjdk-8-jdk libcurl4-openssl-dev
RUN rm /var/lib/apt/lists/* -R

RUN R CMD javareconf

RUN Rscript -e "install.packages('jsonlite')"
RUN Rscript -e "install.packages('rmarkdown')"
RUN Rscript -e "install.packages('readr')"
RUN Rscript -e "install.packages('curl')"
RUN Rscript -e "install.packages('ggplot2')"
RUN Rscript -e "install.packages('rJava')"
RUN Rscript -e "install.packages('mailR')"

RUN wget https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-1-amd64.deb
RUN dpkg -i pandoc-1.19.2.1-1-amd64.deb

COPY scripts /scripts

WORKDIR /scripts

CMD Rscript download_prepare_send.R