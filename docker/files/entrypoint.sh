#!/usr/bin/env bash

uid=$(id -u)

if [ "${uid}" = "0" ]; then
    # Custom time zone.
    if [ "${TZ}" != "Etc/UTC" ]; then
        cp /usr/share/zoneinfo/${TZ} /etc/localtime
        echo "${TZ}" > /etc/timezone
    fi
    # Custom user group.
    if [ "${CLOUDBERRY_GROUP}" != "gpadmin" ] || [ "${CLOUDBERRY_GID}" != "1001" ]; then
        groupmod -g ${CLOUDBERRY_GID} -n ${CLOUDBERRY_GROUP} gpadmin
    fi
    # Custom user.
    if [ "${CLOUDBERRY_USER}" != "gpadmin" ] || [ "${CLOUDBERRY_UID}" != "1001" ]; then
        java_home_path=$(dirname $(dirname $(readlink -f $(which java))))
        usermod -g ${CLOUDBERRY_GID} -l ${CLOUDBERRY_USER} -u ${CLOUDBERRY_UID} -m -d /home/${CLOUDBERRY_USER} gpadmin
        echo "source /usr/local/cloudberry-db/cloudberry-env.sh" > /home/${CLOUDBERRY_USER}/.bashrc
        echo "export JAVA_HOME=/${java_home_path}" >> /home/${CLOUDBERRY_USER}/.bashrc
        echo 'export PATH="/usr/local/pxf/bin:${PATH}"' >> /home/${CLOUDBERRY_USER}/.bashrc
        echo "export PXF_BASE=${CLOUDBERRY_DATA_DIRECTORY}/pxf" >> /home/${CLOUDBERRY_USER}/.bashrc
        mkdir -m 700 -p /home/${CLOUDBERRY_USER}/.ssh
        mkdir -p /home/${CLOUDBERRY_USER}/pxf
        ssh-keygen -q -f /home/${CLOUDBERRY_USER}/.ssh/id_rsa -t rsa -N ""
    fi
    # Correct user:group.
    chown -R ${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} \
        /home/${CLOUDBERRY_USER} \
        ${CLOUDBERRY_DATA_DIRECTORY} \
        /docker-entrypoint-initdb.d
fi

# Start SSH server.
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi
mkdir -p /run/sshd
/usr/sbin/sshd
sleep 2

# Execute command.
if [ "${uid}" = "0" ]; then
    exec gosu ${CLOUDBERRY_USER} "$@"
else
    exec "$@"
fi
