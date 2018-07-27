#!/bin/bash

. lib_configure.sh

CFG_JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"

STEP yum -y install java-1.8.0-openjdk-devel rabbitmq-server

ADD_LINE "/etc/profile.d/jasf.sh" "export JAVA_HOME=${CFG_JAVA_HOME}" "^export JAVA_HOME="
ADD_LINE "/etc/profile.d/jasf.sh" "export PATH=\$PATH:/dados/bin"

# STEP curl -f https://raw.githubusercontent.com/hercules-team/augeas/master/lenses/erlang.aug -o /usr/share/augeas/lenses/dist/erlang.aug
# STEP curl -f https://raw.githubusercontent.com/hercules-team/augeas/master/lenses/rabbitmq.aug -o /usr/share/augeas/lenses/dist/rabbitmq.aug

STEP systemctl enable rabbitmq-server
STEP systemctl start  rabbitmq-server

if ! RUN type -p "rabbitmqadmin" ; then
	STEP rabbitmq-plugins enable rabbitmq_management
	STEP systemctl daemon-reload
	STEP systemctl restart rabbitmq-server
	file="/dados/bin/rabbitmqadmin"
	RUN curl -f http://localhost:15672/cli/rabbitmqadmin -o "$file" || {
		RUN rm -f "$file"
		DIE "Impossível baixar o arquivo"
	}
	STEP chmod +x "$file"
fi

echo "IMPORTANTE: em /etc/rabbitmq/rabbitmq.conf inserir a linha: {disk_free_limit, 50000000}"

OK "Concluído!"
