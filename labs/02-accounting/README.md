# Accounting

## Настроить учёт

1. Проверка действующих настроек учёта
scontrol show config | grep -E '^[[:space:]]*(ClusterName|AccountingStorageType|AccountingStorageHost|AccountingStoragePort|AccountingStorageEnforce|JobAcctGatherType|JobAcctGatherFrequency)[[:space:]]*='
Команда scontrol show config выводит действующую конфигурацию контроллера. Символ | передаёт вывод команде grep. Флаг -E включает расширенные регулярные выражения; перечисленные через | имена параметров задают отбираемые строки, а [[:space:]]* допускает наличие пробельных символов.



2. Проверка доступности системы учёта и регистрации кластера
sacctmgr show cluster format=Cluster,ControlHost,ControlPort
Команда sacctmgr предназначена для управления системой учёта. Подкоманда show cluster запрашивает зарегистрированные кластеры. Параметр format задаёт отображаемые столбцы: имя кластера, адрес контроллера и его порт.



3. Отправка контрольного задания и проверка очереди

sbatch --job-name=accounting-check --time=00:01:00 --wrap="sleep 30"

Команда sbatch отправляет пакетное задание. Параметр --job-name задаёт его название, --time ограничивает время выполнения одной минутой, --wrap указывает выполняемую команду. Команда sleep 30 выполняет ожидание продолжительностью 30 секунд.

squeue

Команда отображает задания, ожидающие запуска или выполняющиеся в данный момент. После завершения контрольное задание исчезнет из очереди.


4. Проверка записи в системе учёта

sacct -j 2 --format=JobID,JobName,User,State,ExitCode,Elapsed

Параметр -j выбирает задание по идентификатору (допустимо и без него). Параметр --format задаёт отображаемые поля: идентификатор, название, пользователь, состояние, код завершения и длительность выполнения.

Строки .batch относятся к пакетным шагам; знак + означает, что название не поместилось в столбец.

5. Настройка сбора показателей использования ресурсов
Ранее параметр JobAcctGatherType имел значение (null). Для включения сбора показателей необходимо изменить конфигурацию Slurm.

vi /etc/slurm/slurm.conf

Исправляем строку на:
JobAcctGatherType=jobacct_gather/linux

Параметр JobAcctGatherType выбирает механизм сбора показателей. Значение jobacct_gather/linux включает сбор средствами Linux.

scontrol reconfigure
Подкоманда reconfigure запрашивает перечитывание конфигурации Slurm.


6. Проверка
vi /data/resource-test.py

import time

data = bytearray(64 * 1024 * 1024)
finish = time.monotonic() + 65

while time.monotonic() < finish:
    sum(range(100000))

print("Вычисление завершено")

Программа выделяет 64 МиБ памяти и выполняет вычисления приблизительно 65 секунд. Продолжительность выбрана так, чтобы превысить установленный интервал сбора показателей — 30 секунд. Переменная data удерживает выделенную память до завершения программы.

sbatch --job-name=resource-test --ntasks=1 --cpus-per-task=1 --time=00:02:00 --wrap="python3 /data/resource-test.py"

sacct -j 6 --format=JobID,State,Elapsed,AllocCPUS,TotalCPU,MaxRSS
Поле	Значение
Elapsed	Продолжительность выполнения
AllocCPUS	Число выделенных CPU
TotalCPU	Суммарное процессорное время, использованное заданием или шагом
MaxRSS	Максимальное зафиксированное потребление резидентной памяти среди задач шага


scontrol show config | grep SelectType
Команда показывает плагин распределения ресурсов SelectType и его параметры SelectTypeParameters.
scontrol show node c1
Команда выводит характеристики узла, включая число CPU, ядер и аппаратных потоков на ядро (ThreadsPerCore).

Значение AllocCPUS=2 обусловлено выделением ресурсов с точностью до ядра (SelectTypeParameters=CR_CORE_MEMORY). Согласно топологии узла, каждое ядро содержит два аппаратных потока (ThreadsPerCore=2). Выделение двух логических CPU не означает их полную загрузку: фактическое суммарное процессорное время задания составило 65,094 секунды при продолжительности выполнения 66 секунд.
проверены подключение к SlurmDBD, регистрация кластера, сохранение истории и сбор показателей ресурсов.

## создание проекта и добавление обычного пользователя

1. 
sacctmgr show account
Подкоманда show account выводит проекты, зарегистрированные в системе учёта. Проект Slurm (account) объединяет пользователей и задания для учёта и назначения ограничений.
sacctmgr show association format=Cluster,Account,User
Подкоманда show association выводит ассоциации. Параметр format оставляет три столбца: кластер, проект и пользователь. Строка с пустым полем User относится к самому проекту.

Сейчас зарегистрированы только проект root и ассоциация пользователя root с этим проектом в кластере linux.

sacctmgr add account training Cluster=linux
| Параметр | Назначение |
| `training` | Имя создаваемого проекта |
| `Cluster=linux` | Кластер, в котором создаётся ассоциация проекта |
| `Description` | Описание проекта |
| `Organization` | Организация, к которой относится проект |

Перед созданием пользователя test необходимо выбрать свободный UID. На контроллере, вычислительных узлах и сервере SlurmDBD этот пользователь должен иметь одинаковый идентификатор.
Команда getent passwd 1001 ищет пользователя с UID 1001 в системной базе пользователей.
Команда getent group 1001 проверяет, занят ли указанный идентификатор группы.
Дальше для удобства создания одинакового пользователя используем скрипт:
$containers = docker compose -f base/docker-compose.yml ps -q slurmctld slurmdbd cpu-worker

foreach ($container in $containers) {
    docker exec $container groupadd -g 1001 test
    docker exec $container useradd -m -u 1001 -g test -s /bin/bash test
    docker exec $container id test
}
Powershell

for /f %c in ('docker compose -f base/docker-compose.yml ps -q slurmctld slurmdbd cpu-worker') do docker exec %c groupadd -g 1001 test
for /f %c in ('docker compose -f base/docker-compose.yml ps -q slurmctld slurmdbd cpu-worker') do docker exec %c id test
cmd

7. Регистрация пользователя в Slurm

sacctmgr add user test Account=training
Подкоманда add user регистрирует пользователя в системе учёта Slurm.
ПараметрНазначениеtestИмя пользователя, совпадающее с именем пользователя LinuxAccount=trainingПроект, к которому добавляется пользовательCluster=linuxКластер для создаваемой ассоциацииDefaultAccount=trainingПроект, используемый по умолчанию при отправке заданий
sacctmgr show user test format=User,DefaultAccount
Команда выводит имя пользователя и его проект по умолчанию.
sacctmgr show association where user=test format=Cluster,Account,User
Условие where user=test выбирает ассоциации пользователя test




