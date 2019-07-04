#!/usr/bin/env bash
## https://sadsloth.net/post/install-gvm10beta2/

/etc/init.d/redis-server start && \
gvmd ;\
openvassd ;\
gsad