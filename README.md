# Slurm Learning Lab

Учебный проект для последовательного изучения [официальной документации Slurm](https://slurm.schedmd.com/documentation.html).
Один раздел документации — одна лабораторная с командами, конфигурацией и собственными результатами.

## Состояние проекта

Подготовлена структура и адаптирован Docker-стенд. Проверен разбор Compose.
Образы пока не собраны, службы не запущены, лабораторные не пройдены.
Каталоги ниже содержат планы и журналы для заполнения; это не готовые отчёты.

## Структура

    base/                       Dockerfile, Compose, конфигурации, примеры
    labs/
      00-quick-start-user/       Quick Start User Guide
      01-quick-start-admin/      Quick Start Administrator Guide
      02-accounting/             Accounting
      03-qos/                    Quality of Service (QOS)
      04-resource-limits/        Resource Limits
    templates/lab/              шаблон новой лабораторной
    docs/                       порядок работы и подготовка отчёта
    LICENSE                     MIT для собственных материалов
    LICENSES/                   лицензии заимствованных материалов
    THIRD_PARTY_NOTICES.md       происхождение Docker-основы

В Git хранятся рецепты сборки образов, а не бинарные Docker-образы.
Для новых тем добавляются каталоги в labs и строки в каталог ниже.

## Каталог

| Каталог | Страница документации | Статус |
|---|---|---|
| [00 — основы пользователя](labs/00-quick-start-user/) | [Quick Start User Guide](https://slurm.schedmd.com/quickstart.html) | Запланировано |
| [01 — основы администратора](labs/01-quick-start-admin/) | [Quick Start Administrator Guide](https://slurm.schedmd.com/quickstart_admin.html) | Запланировано |
| [02 — учёт](labs/02-accounting/) | [Accounting](https://slurm.schedmd.com/accounting.html) | Запланировано |
| [03 — QOS](labs/03-qos/) | [Quality of Service (QOS)](https://slurm.schedmd.com/qos.html) | Запланировано |
| [04 — лимиты](labs/04-resource-limits/) | [Resource Limits](https://slurm.schedmd.com/resource_limits.html) | Запланировано |

Для производственной практики выбраны Accounting, QOS и Resource Limits.
Quick Start — подготовка. Сначала согласовать выбранные ссылки с преподавателем
и убедиться, что они не заняты другими студентами.

## Начало работы

Нужны Git, Docker Engine с Linux-контейнерами, Docker Compose v2, терминал и редактор.
На Windows подходит Docker Desktop. Внешний терминал может быть PowerShell,
команды внутри контейнера выполняются в Bash.

    cd base
    docker version
    docker compose config --quiet
    docker compose build slurmdbd
    docker compose up -d
    docker compose ps
    docker compose exec slurmctld bash

Подробности и критерии первого запуска: [base/README.md](base/README.md).
Затем последовательно проходить каталог лабораторных.
[Как вести лабораторную и отчёт](docs/WORKFLOW.md).

Публикация: [создать свой публичный репозиторий](docs/PUBLISH.md).

## Лицензия и источники

Собственные скрипты и материалы — [MIT](LICENSE).
База адаптирована из [giovtorres/slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster);
его MIT-уведомление сохранено в [LICENSES](LICENSES/slurm-docker-cluster-MIT.txt).
Подробности — [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
Slurm и остальные устанавливаемые программы сохраняют собственные лицензии.
