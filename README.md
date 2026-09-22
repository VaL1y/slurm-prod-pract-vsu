# Slurm Learning Lab

Учебный Docker-кластер для практического изучения [документации Slurm](https://slurm.schedmd.com/documentation.html).

## Структура

- base/ — Dockerfile, Compose, скрипт запуска и конфигурации.
- labs/ — лабораторные по разделам документации; команды и результаты добавляются по мере прохождения.
- LICENSE и LICENSES/ — лицензии проекта и исходной Docker-основы.

| Лабораторная | Документация | Статус |
|---|---|---|
| [Accounting](labs/02-accounting/) | [Accounting](https://slurm.schedmd.com/accounting.html) | Начата: проверена запись задания в sacct |
| [QOS](labs/03-qos/) | [Quality of Service (QOS)](https://slurm.schedmd.com/qos.html) | Не начата |
| [Resource Limits](labs/04-resource-limits/) | [Resource Limits](https://slurm.schedmd.com/resource_limits.html) | Не начата |

## Запуск

Нужны Docker Engine с Linux-контейнерами и Docker Compose v2.
Команды из корня репозитория:

    docker compose -f base/docker-compose.yml build slurmdbd
    docker compose -f base/docker-compose.yml up -d
    docker compose -f base/docker-compose.yml ps
    docker compose -f base/docker-compose.yml exec slurmctld sinfo -N
    docker compose -f base/docker-compose.yml exec slurmctld srun -N2 -n2 hostname
    docker compose -f base/docker-compose.yml exec slurmctld sacct

Состав: MariaDB, slurmdbd, slurmctld и два CPU-узла c1/c2.
Образ Slurm 26.05.2 общий для трёх сервисов Slurm.
Ожидаемый результат проверки: имена двух узлов и завершённое задание в sacct.

Для работы внутри контроллера:

    docker compose -f base/docker-compose.yml exec slurmctld bash

Задания размещаются в /data — общем томе контроллера и вычислительных узлов.
Каталог labs доступен на контроллере как /labs только для чтения.

## Настройки и данные

Параметры Compose можно задать в base/.env по образцу base/.env.example.
Конфигурация Slurm находится в base/config/.
При первом запуске она копируется из образа в том etc_slurm.
Пересборка образа не обновляет существующий том: изменения конфигурации
нужно переносить отдельно с сохранением прежней версии и применять через scontrol reconfigure.

Остановить стенд с сохранением данных:

    docker compose -f base/docker-compose.yml down

Не добавлять -v при обычной остановке: тома содержат базу учёта, состояние
контроллера, конфигурацию и задания. Имена проекта и томов сохраняются между обновлениями.

Узлы делят ресурсы одного Docker-хоста. Профиль task/affinity и
proctrack/linuxproc предназначен для учебных опытов, а не для проверки
жёсткой изоляции памяти. Перед проверкой пользовательских лимитов нужны
обычные пользователи и ассоциации Slurm; вход через exec по умолчанию выполняется как root.

## Лицензия и происхождение

Собственные материалы — [MIT](LICENSE).
Dockerfile, Compose, entrypoint, RPM-макросы и конфигурации адаптированы из
[giovtorres/slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster),
commit cf399c5e140ae7dda1b1ed7ccfe0d000bb65af6d.
Copyright (c) 2024 Giovanni Torres; [исходная лицензия MIT](LICENSES/slurm-docker-cluster-MIT.txt) сохранена.
Из основы удалены дополнительные сервисы, примеры и неиспользуемые настройки.
Slurm и остальные зависимости сохраняют собственные лицензии.