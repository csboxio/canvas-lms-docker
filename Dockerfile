# syntax=docker/dockerfile

ARG NODE_VERSION=20
ARG RUBY_VERSION=3.1
ARG CANVAS_HOME=/opt/canvas

FROM node:${NODE_VERSION}-bookworm-slim AS node

FROM ruby:${RUBY_VERSION}-bookworm AS builder

ARG YARN_VERSION=1.22.21
ARG CANVAS_HOME

ENV NODE_OPTIONS=--openssl-legacy-provider

COPY --from=node /usr/local/bin/node /usr/local/bin
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN <<EOF
ln -s /usr/local/bin/node /usr/local/bin/nodejs
ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

apt-get update
apt-get install -y --no-install-recommends \
    libidn-dev \
    libxmlsec1-dev

npm update -g npm
npm install -g yarn@${YARN_VERSION}

git clone -b prod --depth 1 https://github.com/instructure/canvas-lms.git ${CANVAS_HOME}
EOF

WORKDIR ${CANVAS_HOME}

RUN <<EOF
yarn config set network-timeout 600000
yarn config set network-concurrency 1
yarn install --pure-lockfile --ignore-optional
# https://github.com/instructure/canvas-lms/issues/2311
yarn add @instructure/outcomes-ui -W

bundle install
bundle exec rake canvas:compile_assets_dev

rm -rf \
    .git \
    .github \
    .storybook \
    .vscode \
    Courses \
    build \
    doc \
    docker-compose \
    hooks \
    inst-cli \
    jest \
    log/* \
    node_modules \
    patches \
    tmp/* \
    ui \
    ui-build
rm \
    .codeclimate.yml \
    .devcontainer.json \
    .dive-ci \
    .dockerignore \
    .editorconfig \
    .eslintignore \
    .eslintrc.js \
    .git-blame-ignore-revs \
    .gitignore \
    .gitmessage \
    .groovylintrc.json \
    .i18nignore \
    .i18nrc \
    .irbrc \
    .lintstagedrc.js \
    .npmrc \
    .nvmrc \
    .prettierrc \
    .rspec \
    .rubocop.yml \
    .sentryignore \
    .stylelintrc \
    CONTRIBUTING.md \
    COPYRIGHT \
    Dockerfile* \
    Jenkinsfile* \
    LICENSE \
    README.md \
    SECURITY.md \
    bower.json \
    code_of_conduct.md \
    config/*.yml.* \
    docker-compose* \
    gulpfile.js \
    issue_template.md \
    jest.config.js \
    karma.conf.js \
    package.json \
    rspack.config.js \
    tsconfig.json \
    vitest.*.ts \
    yarn.lock
EOF

COPY canvas ${CANVAS_HOME}

FROM ruby:${RUBY_VERSION}-slim-bookworm AS runner

ARG CANVAS_HOME
ARG CANVAS_USER=canvas

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends \
    git \
    libbrotli1 \
    libidn12 \
    libpq5 \
    libsqlite3-0 \
    libxmlsec1-openssl
apt-get clean
rm -rf /var/lib/apt/lists/*

groupadd ${CANVAS_USER}
useradd -g ${CANVAS_USER} -d ${CANVAS_HOME} ${CANVAS_USER}
EOF

COPY --from=builder --chown=${CANVAS_USER} ${GEM_HOME} ${GEM_HOME}
COPY --from=builder --chown=${CANVAS_USER} ${CANVAS_HOME} ${CANVAS_HOME}

WORKDIR ${CANVAS_HOME}

USER ${CANVAS_USER}

ENV RUBYLIB=${CANVAS_HOME}

EXPOSE 3000

CMD [ "RAILS_ENV=production", "bundle", "exec", "rails", "server", "-b", "0.0.0.0" ]