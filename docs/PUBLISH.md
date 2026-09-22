# Публикация собственного репозитория

Локальный проект уже инициализирован через git init -b main.
Удалённый репозиторий и первый коммит пока не созданы.

## Через сайт GitHub и обычный Git

1. Открыть https://github.com/new под своим аккаунтом.
2. Имя: slurm-learning-lab. Видимость: Public.
3. Не добавлять README, .gitignore или лицензию на сайте: они уже есть локально.
4. Создать пустой репозиторий.
5. В PowerShell выполнить (заменить YOUR_LOGIN своим логином GitHub):

```powershell
cd C:\proizv_practic\slurm-learning-lab
git config --get user.name
git config --get user.email
git add .
git diff --cached --stat
git commit -m "Initialize Slurm learning lab"
git remote add origin https://github.com/YOUR_LOGIN/slurm-learning-lab.git
git push -u origin main
```

Имя и email из Git попадут в метаданные публичного коммита. При желании до
коммита задать для этого проекта email noreply из GitHub Settings → Emails:

```powershell
git config user.email "YOUR_GITHUB_NOREPLY_EMAIL"
```

Git может запросить вход в GitHub через менеджер учётных данных.
Не вставлять токен в URL репозитория или отслеживаемые файлы.

## Если установлен GitHub CLI

GitHub CLI (gh) на момент подготовки не найден. Если установить его самостоятельно,
вместо создания на сайте и команд remote/push после локального коммита можно выполнить:

```powershell
gh auth login
gh repo create slurm-learning-lab --public --source=. --remote=origin --push
```

Выбрать один из способов, не выполнять создание репозитория дважды.

После публикации передать ссылку на репозиторий для дальнейшей работы.
