FROM rust:1.70 as build

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

RUN USER=root cargo new --bin wasm-opt-action
WORKDIR /wasm-opt-action

COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

RUN cargo build --release
RUN rm src/*.rs

COPY ./src ./src

RUN rm -r ./target/release/deps/
RUN cargo build --release

FROM debian:bullseye-slim

# Define binaryen version as build argument with a default value
ARG BINARYEN_VERSION=122

RUN apt-get update
RUN apt-get install -y wget

RUN mkdir binaryen
RUN wget -qO- https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/binaryen-version_${BINARYEN_VERSION}-x86_64-linux.tar.gz | tar xvz -C ./binaryen binaryen-version_${BINARYEN_VERSION} --strip=1
ENV PATH $PATH:/binaryen/bin

COPY --from=build /wasm-opt-action/target/release/wasm-opt-action .
COPY LICENSE-BINARYEN .
ENV PATH $PATH:/
RUN chmod +x /wasm-opt-action

ENTRYPOINT ["wasm-opt-action"]
