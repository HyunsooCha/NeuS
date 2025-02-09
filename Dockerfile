FROM colmap/colmap:latest
LABEL maintainer "Hyunsoo Cha <729steven@gmail.com>"
LABEL title="Docker for PointAvatar"
LABEL version="0.7"
LABEL description="Docker build of PointAvatar based on torch1.11.0+cu113"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

## Basic Packages
RUN apt-key del 7fa2af80
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub
# The above 5 lines : handling issues of nvidia docker (2022)
RUN sed -i 's/archive.ubuntu.com/ftp.daumkakao.com/g' /etc/apt/sources.list

# Add the Nvidia CUDA repository to the list of package sources
RUN echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y wget vim git gcc curl build-essential

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y ffmpeg libsm6 libxext6 libopenexr-dev x11-apps freeglut3-dev cmake libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-test-dev \
    libeigen3-dev \
    libsuitesparse-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libatlas-base-dev \
    libsuitesparse-dev \
    libprotobuf-dev \
    protobuf-compiler
RUN apt-get -y update && \ 
    apt-get install -y git nano zsh tzdata vim openssh-server sudo ufw curl tmux
RUN sudo apt-get install -y language-pack-en && sudo update-locale

## zsh
SHELL ["/bin/zsh", "-c"]
RUN chsh -s `which zsh`

## oh-my-zsh
RUN sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN apt-get -y install fonts-powerline

## zsh-autosuggestions, zsh-syntax-highlighting을 플러그인에 추가하는 코드
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

## powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
RUN wget -O /root/.p10k.zsh https://www.dropbox.com/s/7i95f3o6sisyqof/.p10k.zsh

RUN perl -pi -w -e 's/plugins=.*/plugins=(git ssh-agent zsh-autosuggestions zsh-syntax-highlighting)/g;' ~/.zshrc
# Set powerlevel10k as the default theme
RUN sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' /root/.zshrc

# Set up the powerlevel10k theme
RUN echo 'source /root/.p10k.zsh' >> /root/.zshrc && \
    echo 'POWERLEVEL10K_DISABLE_CONFIGURATION=true' >> /root/.zshrc

# ## Anaconda3
# RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.zshrc && \
#     echo "conda activate base" >> ~/.zshrc
# ENV PATH /opt/conda/bin:$PATH

# RUN . ~/.zshrc && \
#     conda init zsh && \
#     conda update conda

## SSH
# ssh에서 id:password를 설정합니다. 디폴트로 id = root, password = root으로 했습니다. 
# PermitRootLogin : 디폴트값을 yes로 해줘야 ssh 연결에서 문제가 안생깁니다.
RUN echo 'root:cocoa' |chpasswd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    mkdir /root/.ssh && \
    mkdir /var/run/sshd 

## Install cmake
WORKDIR /root
RUN apt-get remove -y cmake && \ 
    mkdir cmake && cd cmake && \
    wget https://github.com/Kitware/CMake/releases/download/v3.24.2/cmake-3.24.2-linux-x86_64.sh && \
    chmod 777 ./cmake-3.24.2-linux-x86_64.sh && \
    ./cmake-3.24.2-linux-x86_64.sh --skip-license
ENV PATH /home/cmake/bin:$PATH

## ntfy
# RUN python3 -m pip install git+https://github.com/dschep/ntfy.git@master --upgrade
# RUN mkdir -p ~/.config/ntfy
# RUN echo '---\nbackends:\n  - slack_webhook\nslack_webhook:\n  url: "https://hooks.slack.com/services/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"\n  user: "#hyunsoo-ntfy"' > ~/.config/ntfy/ntfy.yml

## Alias
RUN echo "function gitupdate() { \
    git pull; \
    echo '[INFO] pulling complete!'; \
    git add .; \
    echo '[INFO] adding complete!'; \
    if [ -z \"\$1\" ]; \
    then \
        today=\`date +%m-%d-%Y\`; \
        time=\`date +%H:%M:%S\`; \
        git commit -m \"update \$time \$today\"; \
    else \
        git commit -m \"\$1\"; \
    fi; \
    echo '[INFO] commiting complete!'; \
    git push origin main; \
    echo '[INFO] pushing complete!'; \
}; \
alias githard='git reset --hard HEAD && git pull'; \
alias gitsoft='git reset --soft HEAD^ '; \
alias gitcache='git rm -r --cached .'; \
alias ca='conda activate'; \
alias czsh='code ~/.zshrc'; \
alias szsh='source ~/.zshrc'; \
alias ta='tmux attach -t'; \
alias tl='tmux ls'; \
alias tn='tmux new -s'; \
function ffi2v() { \
    ffmpeg -i \$1 -c:v libx264 -profile:v high -pix_fmt yuv420p \$2; \
}; \
function ffv2i() { \
    ffmpeg -i \$1 -qscale:v 2 \$2; \
}; \
function ffglob() { \
    ffmpeg -framerate \$1 -pattern_type glob -i \$2 -c:v libx264 -profile:v high -pix_fmt yuv420p \$3; \
}; \
alias wn='watch -d -n 0.5 nvidia-smi'; \
alias gpu0='CUDA_VISIBLE_DEVICES=0'; \
alias gpu1='CUDA_VISIBLE_DEVICES=1'; \
alias gpu2='CUDA_VISIBLE_DEVICES=2'; \
alias gpu3='CUDA_VISIBLE_DEVICES=3'; \
alias gpu4='CUDA_VISIBLE_DEVICES=4'; \
alias gpu5='CUDA_VISIBLE_DEVICES=5'; \
alias gpu6='CUDA_VISIBLE_DEVICES=6'; \
alias gpu7='CUDA_VISIBLE_DEVICES=7'; \
alias ram='watch -d -n 0.5 free -h'; \
alias caphere='sudo du -h --max-depth=1'; \
alias python='ntfy done python'" >> ~/.zshrc

## CUB
# RUN curl -LO https://github.com/NVIDIA/cub/archive/1.10.0.tar.gz \
#     && tar xzf 1.10.0.tar.gz \
#     && export CUB_HOME=$PWD/cub-1.10.0 \
#     && echo "export CUB_HOME=$PWD/cub-1.10.0" >> ~/.zshrc

# ENV CUB_HOME /root/cub-1.10.0
# ENV PATH /usr/local/cuda-11.3/bin:$PATH
# ENV LD_LIBRARY_PATH /usr/local/cuda-11.3/lib64:$LD_LIBRARY_PATH
# ENV FORCE_CUDA 1
# ENV CUDA_HOME /usr/local/cuda-11.3
# ENV TORCH_CUDA_ARCH_LIST="8.6+PTX"
# RUN echo "export PATH='/usr/local/cuda-11.3/bin:$PATH'" >> ~/.zshrc
# RUN echo "export LD_LIBRARY_PATH='/usr/local/cuda-11.3/lib64:$LD_LIBRARY_PATH'" >> ~/.zshrc

## Install PyTorch3D
# RUN pip install ninja
# WORKDIR /root/GitHub/
# RUN git clone https://github.com/zhengyuf/pytorch3d.git
# WORKDIR /root/GitHub/pytorch3d
# RUN git checkout point-avatar
# RUN pip install -e .

# RUN pip install functorch==0.1.1 \
#         functorch==0.1.1 \
#         imageio==2.22.0 \
#         lpips==0.1.4 \
#         matplotlib==3.6.0 \
#         opencv-python==4.6.0.66 \
#         Pillow==9.2.0 \
#         pyhocon==0.3.59 \
#         scikit-image==0.19.3 \
#         scipy==1.9.1 \
#         trimesh==3.15.1 \
#         chumpy==0.70 \
#         wandb==0.12.9 \
#         protobuf==3.20.0 \
#         numpy==1.23.3 \
#         pandas==1.5.1 \
#         natsort

# ## set up the working directory
# WORKDIR /root/GitHub

EXPOSE 22

CMD ["zsh"]