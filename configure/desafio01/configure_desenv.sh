#!/bin/bash

. lib_configure.sh

STEP git config --system push.default simple
STEP git config --system color.ui auto

LOCALUSER="jose"
GIT_FILE="/home/"$LOCALUSER"/.gitconfig"

if ! RUN git config --file "$GIT_FILE" user.email ; then
	STEP touch "$GIT_FILE"
	STEP chown "${LOCALUSER}.${LOCALUSER}" "$GIT_FILE"
	STEP chmod 644 "$GIT_FILE"

	PROMPT "Digite o valor para git/user.name" || exit 1
	GIT_USERNAME="$REPLY"
	PROMPT "Digite o valor para git/user.email" || exit 1
	GIT_USEREMAIL="$REPLY"

	echo "Git/user.name  = $GIT_USERNAME"
	echo "Git/user.email = $GIT_USEREMAIL"
	CONFIRM "Desejar atualizar o arquivo .gitconfig com os valores acima?"
	case $? in
		2) exit 1 ;; # EOF
		1) true ;; 
		0)
			STEP git config --file "$GIT_FILE" user.name  "$GIT_USERNAME"
			STEP git config --file "$GIT_FILE" user.email "$GIT_USERMAIL"
			;;
	esac
fi

CFG_JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"

STEP yum -y install java-1.8.0-openjdk-devel rabbitmq-server mariadb

ADD_LINE "/etc/profile.d/jasf.sh" "export JAVA_HOME=${CFG_JAVA_HOME}" "^export JAVA_HOME="
ADD_LINE "/etc/profile.d/jasf.sh" "export PATH=\$PATH:/dados/bin"

# STEP curl -f https://raw.githubusercontent.com/hercules-team/augeas/master/lenses/erlang.aug -o /usr/share/augeas/lenses/dist/erlang.aug
# STEP curl -f https://raw.githubusercontent.com/hercules-team/augeas/master/lenses/rabbitmq.aug -o /usr/share/augeas/lenses/dist/rabbitmq.aug

STEP systemctl enable rabbitmq-server
STEP systemctl start  rabbitmq-server

file="/dados/bin/rabbitmqadmin"
if [ ! -x "$file" ] ; then
	STEP rabbitmq-plugins enable rabbitmq_management
	STEP systemctl daemon-reload
	STEP systemctl restart rabbitmq-server
	RUN curl -f http://localhost:15672/cli/rabbitmqadmin -o "$file" || {
		RUN rm -f "$file"
		DIE "Impossível baixar o arquivo"
	}
	STEP chmod +x "$file"
fi

echo "IMPORTANTE: em /etc/rabbitmq/rabbitmq.conf inserir a linha: {disk_free_limit, 50000000}"

OK "Concluído!"
