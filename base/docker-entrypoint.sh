#!/bin/bash
set -e

# Detect replica number by matching own IP against Docker Compose DNS entries.
# Compose names containers as <project>-<service>-<N>, and Docker's embedded DNS
# resolves these names within the network. We iterate N=1..max and find which
# one resolves to our IP.
# Falls back to the container ID (hostname) if detection fails.
detect_replica_number() {
    local service_name="$1"
    local max_replicas="${2:-64}"
    local my_ip
    my_ip=$(hostname -i 2>/dev/null | awk '{print $1}')

    for i in $(seq 1 "$max_replicas"); do
        local resolved
        resolved=$(getent hosts "${COMPOSE_PROJECT_NAME}-${service_name}-${i}" 2>/dev/null | awk '{print $1}')
        if [ "$resolved" = "$my_ip" ]; then
            echo "$i"
            return 0
        elif [ -z "$resolved" ]; then
            break
        fi
    done

    # Fallback: use container ID
    hostname
    return 1
}

echo "---> Starting the MUNGE Authentication service (munged) ..."
gosu munge /usr/sbin/munged

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the Slurm Database Daemon (slurmdbd) ..."

    # Substitute environment variables in slurmdbd.conf
    envsubst < /etc/slurm/slurmdbd.conf > /etc/slurm/slurmdbd.conf.tmp
    mv /etc/slurm/slurmdbd.conf.tmp /etc/slurm/slurmdbd.conf
    chown slurm:slurm /etc/slurm/slurmdbd.conf
    chmod 600 /etc/slurm/slurmdbd.conf

    # Wait for MySQL using environment variables directly
    until echo "SELECT 1" | mysql -h mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} 2>&1 > /dev/null
    do
        echo "-- Waiting for database to become active ..."
        sleep 2
    done
    echo "-- Database is now active ..."

    exec gosu slurm /usr/sbin/slurmdbd -Dvvv

fi

if [ "$1" = "slurmctld" ]
then

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."

    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."
    exec gosu slurm /usr/sbin/slurmctld -i -Dvvv
fi

if [ "$1" = "slurmd-cpu" ]
then
    echo "---> Waiting for slurmctld to become active before starting dynamic slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    # Derive a sequential node name from the Docker Compose replica number.
    # e.g., slurm-cpu-worker-1 -> c1, slurm-cpu-worker-2 -> c2
    # Falls back to container ID if replica detection fails.
    REPLICA=$(detect_replica_number "cpu-worker")
    NODE_NAME="c${REPLICA}"
    hostname "${NODE_NAME}"

    echo "---> Dynamic CPU worker registering as: ${NODE_NAME}"
    echo "---> Starting slurmd in dynamic registration mode (-Z)..."

    # -Z: dynamic node self-registration with slurmctld
    # Feature=cpu: tag for cpu partition NodeSet matching
    exec /usr/sbin/slurmd -Z -Dvvv \
        --conf "Feature=cpu"
fi

exec "$@"
