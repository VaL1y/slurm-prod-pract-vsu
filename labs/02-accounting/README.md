# Accounting

[Документация](https://slurm.schedmd.com/accounting.html).

Изучаем SlurmDBD, проекты (accounts), пользователей, ассоциации и историю заданий.
Пока проверено выполнение задания на двух узлах и его запись в базе:

    srun -N2 -n2 hostname
    sacct --format=JobID,JobName,User,State,ExitCode

Получен вывод c1 и c2; задание hostname завершилось с состоянием COMPLETED и кодом 0:0.
Следующий этап — просмотр и настройка объектов учёта через sacctmgr.