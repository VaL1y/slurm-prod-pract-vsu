# Third-party notices

## Docker cluster foundation

Source: https://github.com/giovtorres/slurm-docker-cluster
Revision: cf399c5e140ae7dda1b1ed7ccfe0d000bb65af6d
Copyright (c) 2024 Giovanni Torres
License: MIT; full original notice: [LICENSES/slurm-docker-cluster-MIT.txt](LICENSES/slurm-docker-cluster-MIT.txt).

The Dockerfile, Compose definition, entrypoint, configurations, RPM macros and
example jobs under base/ are adapted from that project.
Changes include removal of optional Compose services, Lmod/Spack build stages,
a persistent controller-state volume, MariaDB configuration and project naming.
This repository has its own Git history and is not presented as wholly original work.

Dependencies installed by Dockerfile, including Slurm, are separately licensed.
The repository MIT license does not relicense those dependencies or official Slurm documentation.

