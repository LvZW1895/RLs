FROM nvidia/cuda:10.1-runtime-ubuntu16.04

LABEL maintainer="StepNeverStop(Keavnn)"\
      source="https://github.com/StepNeverStop/RLs"\
      description="Docker image for runing RLs."\
      email="keavnn.wjs@gmail.com"

# change sources and install apt packages
RUN apt-get update --fix-missing && \
    apt-get clean && \
    apt-get install -y apt-file nano --no-install-recommends wget bzip2 ca-certificates curl git openssh-server \
    libglib2.0-dev libsm6 libxrender1 libxext6 libnvinfer6=6.0.1-1+cuda10.1 libnvinfer-dev=6.0.1-1+cuda10.1 libnvinfer-plugin6=6.0.1-1+cuda10.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd && \
    echo "root:1234" | chpasswd && \
    sed -i 's/prohibit-password/yes/g' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\srequired\spam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# install miniconda3 and change source of pip
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    . /opt/conda/etc/profile.d/conda.sh && \
    conda init bash && \
    conda update conda && \
    conda install -y conda-build && \
    /opt/conda/bin/conda build purge-all

# install my own conda environment
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda create -n rls python=3.6 docopt numpy imageio pyyaml protobuf  pandas openpyxl tqdm && \
    conda activate rls && \
    echo -e "\033[4;41;32m conda activate rls successed. \033[0m" && \
    pip --no-cache-dir install gym grpcio tensorflow-gpu==2.1.0 tensorflow_probability opencv-python && \
    /opt/conda/bin/conda build purge-all && \
    rm -rf ~/.cache/pip/* && \
    # download RLs
    cd ~ && git clone https://github.com/StepNeverStop/RLs.git && cd RLs && \
    python run.py --gym -a dqn -t 2000 -s 100 --prefill-steps 1000 --store-dir '/root/test_rls' && \
    echo -e "\033[4;41;32m run rls successed. \033[0m" && \
    rm -rf /root/test_rls

# 22:ssh 6006:tensorboard 8888:jupyter lab
EXPOSE 22 6006 8888

ENTRYPOINT ["/usr/sbin/sshd","-D"]