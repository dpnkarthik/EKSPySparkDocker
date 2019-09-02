ARG BASE_CONTAINER=jupyter/scipy-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION 2.4.4
ENV HADOOP_VERSION 2.7

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q ftp://apache.cs.utah.edu/apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}.tgz && \
    tar xzf spark-${APACHE_SPARK_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm spark-${APACHE_SPARK_VERSION}.tgz

RUN ln -s /usr/local/spark-${APACHE_SPARK_VERSION} /usr/local/spark

WORKDIR /usr/local/spark

RUN rm resource-managers/kubernetes/core/pom.xml

COPY pom.xml resource-managers/kubernetes/core/pom.xml

RUN ./dev/make-distribution.sh --name custom-spark --pip --tgz -Phadoop-2.7 -Pkubernetes

ENV GRANT_SUDO yes
USER root
RUN apt update
RUN apt-get install -yq gnupg vim curl


RUN apt-get update && sudo apt-get install -y apt-transport-https
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

RUN curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.8/2019-08-14/bin/linux/amd64/aws-iam-authenticator
RUN chmod +x ./aws-iam-authenticator
RUN mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
RUN echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

# RUN rm $SPARK_HOME/jars/kubernetes-client-4.1.2.jar
# RUN rm $SPARK_HOME/jars/kubernetes-model-4.1.2.jar
# RUN rm $SPARK_HOME/jars/kubernetes-model-common-4.1.2.jar

# ADD https://search.maven.org/remotecontent?filepath=io/fabric8/kubernetes-client/4.4.2/kubernetes-client-4.4.2.jar $SPARK_HOME/jars
# ADD https://search.maven.org/remotecontent?filepath=io/fabric8/kubernetes-model/4.4.2/kubernetes-model-4.4.2.jar $SPARK_HOME/jars
# ADD https://search.maven.org/remotecontent?filepath=io/fabric8/kubernetes-model-common/4.4.2/kubernetes-model-common-4.4.2.jar $SPARK_HOME/jars

RUN pip install awscli