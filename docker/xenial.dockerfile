FROM buildpack-deps:xenial as builder
MAINTAINER Xuejie Xiao <xxuejie@gmail.com>

RUN apt-get update && apt-get install -y git autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev python3 python3-dev

WORKDIR /source
COPY ./ .

ENV CFLAGS_FOR_TARGET_EXTRA "-Os -DCKB_NO_MMU -D__riscv_soft_float -D__riscv_float_abi_soft"

RUN mkdir -p /riscv
RUN cd /source && ./docker/check_git
RUN cd /source && git rev-parse HEAD > /REVISION
RUN cd /source && ./configure --prefix=/riscv --with-arch=rv64imac --with-python && make -j$(nproc)

FROM buildpack-deps:xenial
MAINTAINER Xuejie Xiao <xxuejie@gmail.com>
COPY --from=builder /riscv /riscv
COPY --from=builder /REVISION /riscv/REVISION
RUN apt-get update && apt-get install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev cmake python3-pip && apt-get clean

RUN wget -P ~ https://git.io/.gdbinit
RUN pip3 install pygments

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly-2020-06-01 -y
ENV PATH=/root/.cargo/bin:$PATH
# Install RISC-V target
RUN rustup target add riscv64imac-unknown-none-elf

ENV RISCV /riscv
ENV PATH "${PATH}:${RISCV}/bin"
CMD ["riscv64-unknown-elf-gcc", "--version"]
