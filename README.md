# Дипломное задание профессии Специалист по информационной безопасности (Track DevSecOps)


## Задача

Создать безопасный пайплайн для open-source проекта. Он должен включать в себя статический анализатор, динамический анализатор, чекеры безопасности, Security Gateway и документацию процесса.

## Исходные данные
1. Требования к проекту. Проект должен быть с открытым исходным кодом, представлять из себя веб-сервис или сайт с функционалом, использованием баз данных или кеша.

2. Требования к покрытию проекта тестами безопасности. Проект должен проверяться на наличие уязвимостей в коде. Ни один язык программирования или фреймворк не должны быть пропущены для конкретного проекта. Весь процесс должен быть задокументирован и описан с аналитикой выбора инструментов и зон роста.

## Этапы проектирования

## Этап 1. CI/CD

Критерии достижения:

1. Настроенный пайплайн по сборке и доставке программного обеспечения.
2. Использование облачных сервисов для раскатки.
3. Хорошо задокументированный процесс.

### Решение:

1. Платформа для организации CI/CD выбрана GitHub Actions. Сервер для разворачивания предоставлен в виде VPS.
2. В качестве примера для реализации Задачи взят проект https://github.com/appsecco/dvna. Использован один из трех вариантов - официальный образ. Docker.Damn Vulnerable NodeJS Application (DVNA) — это простое приложение NodeJS, демонстрирующее 10 основных уязвимостей по версии OWASP и содержащее рекомендации по устранению и предотвращению этих уязвимостей. Приложение работает на основе часто используемых библиотек, таких как express, passport, sequelize и т. д. С использованием клонирования создан публичный репозиторий Dso_test.

### Настраиваем свое рабочее место:

Клонируем репозиторий https://github.com/appsecco/dvna

```bash
git clone https://github.com/appsecco/dvna; cd dvna
```

Создаем файл с именем vars.env со следующей конфигурацией (для официального репозитория)

```bash
MYSQL_USER=dvna
MYSQL_DATABASE=dvna
MYSQL_PASSWORD=passw0rd
MYSQL_RANDOM_ROOT_PASSWORD=yes
MYSQL_HOST=mysql-db
MYSQL_PORT=3306
```

Запускаем контейнер MySQL

```bash
docker run --rm --name dvna-mysql --env-file vars.env -d mysql:5.7
```

Запускаем приложение, используя официальный образ

```bash
docker run --rm --name dvna-app --env-file vars.env --link dvna-mysql:mysql-db -p 9090:9090 appsecco/dvna
```

Проверяем работоспособность приложения по адресу http://127.0.0.1:9090/

Производим переименование репозитория в Dso_test; Удаляем скрытую директорию .git; Создаем в своей учетной записи на github соответствующий репозиторий Dso_test

Инициализируем git репозиторий в Dso_test

```bash
git init
```

Добавляем содержимое репозитория в первый коммит

```bash
git add -A
git commit -m "первый коммит"
```

Отправляем репозиторий на github

```bash
git push origin main
```



### Настраиваем сервер

Клонируем подготовленный репозиторий на сервер в директорию /root; копируем его в директорию /opt и запускаем сервис.

Запускаем контейнер MySQL

```bash
docker run --rm --name dvna-mysql --env-file vars.env -d mysql:5.7
```

Запускаем приложение, используя официальный образ

```bash
docker run --rm --name dvna-app --env-file vars.env --link dvna-mysql:mysql-db -p 9090:9090 appsecco/dvna
```
В директории /root клонированный репозиторий удаляем и создаем скрипт deploy.sh следующего содержания:

```bash
#!/bin/bash

#Stop docker
cd /opt/dso_test/
sudo docker stop $(sudo docker ps -aq)

# Удаляем service
rm -rf /opt/dso_test
# Clone the repo
cd ~/
git clone git@github.com:alekseypopkov/dso_test.git
cp -rf ~/dso_test /opt/; rm -rf ~/dso_test

# Startup service
cd /opt/dso_test
sudo docker run --rm --name dvna-mysql --env-file vars.env -d mysql:5.7
sudo docker run -d --rm --name dvna-app --env-file vars.env --link dvna-mysql:mysql-db -p 9090:9090 appsecco/dvna

exit
```

Данный скрип запускается с github Action: - останавливает запущенный сервис на сервере; удаляет предыдущую версию сервиса; разворачивает новую и запускает ее.

### Приступаем к настройке github Action

После успешного завершения предыдущих шагов, приступаем к настройке github Action. Для автоматического запуска при каждой команде push, в директории ./github/workflows, создан файл deploy.yml -  файлы конфигурации для GitHub Actions.

```bash
name: Deploy-test-2
on:
  push:
    branches: [ "main" ]

jobs:

  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    steps:
      - name: SSH Deploy
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            sh ${{ secrets.PATH_TO_SCRIPT }}
```

Файл конфигурации запускает авторизацию на сервере с помощью пары ssh-ключей. Публичный ключ расположен на сервере в директории ./ssh. Приватный ключ помещен в "секрет" в настройках репозитория. В "секрет" помещены - адрес сервера, пользователь для авторизации, путь до Bash-скрипта. После успешной авторизации файл конфигурации запускает Bash-скрипт на сервере. Bash-скрипт выполняет весь процесс обновления приложения.

Сайт доступен по порту 9090 на предоставленном сервере.

## Этап 2. SAST

Критерии достижения:

1. Покрытие кода проверками.
2. Успешные проверки во время сборки.
3. Выгрузка результатов в CI или систему менеджмента уязвимостей.

### Решение:

### Для достижения цели использован CodeQL Action

Этот проект выпущен под лицензией MIT.

CodeQL настроен как расширяемый набор запросов, разработанных сообществом и лабораторией безопасности GitHub для поиска распространенных уязвимостей в исходном коде репозитория.

Базовый интерфейс командной строки CodeQL, используемый в этом действии, лицензирован в соответствии с Условиями использования GitHub CodeQL. Таким образом, это действие можно использовать в проектах с открытым исходным кодом, размещённых на GitHub, а также в частных репозиториях, принадлежащих организациям с включённой расширенной безопасностью GitHub.

Режимы сборки CodeQL

Действие CodeQL поддерживает различные режимы сборки для анализа исходного кода. Доступны следующие режимы сборки:

none: База данных будет создана без создания исходного кода. Доступно для всех интерпретируемых языков и некоторых компилируемых языков.

autobuild: База данных будет создана путём попытки автоматического создания исходного кода. Доступно для всех компилируемых языков.

manual: База данных будет создана путём сборки исходного кода с помощью команды сборки, заданной вручную. Чтобы использовать этот режим сборки, указываем шаги ручной сборки в рабочем процессе между шагами init и analyze. Доступно для всех компилируемых языков.

Какой режим сборки мне следует использовать?
Интерпретируемые языки должны использовать none для режима сборки.

Для скомпилированных языков:

manual Режим сборки обычно даёт наиболее точные результаты, но его сложнее настроить, и анализ займёт немного больше времени.

autobuild Режим сборки проще в настройке, но он будет работать только для проектов с общими этапами сборки, которые можно определить с помощью эвристики в сценариях автоматической сборки. Если autobuild не работает, то вам нужно переключиться на manual или none. Если autobuild работает, то результаты и время выполнения будут такими же, как в режиме manual.

none Режим сборки также проще в настройке и немного быстрее в работе, но есть вероятность, что некоторые оповещения будут пропущены. Это может произойти, если ваш репозиторий генерирует код во время компиляции или если есть какие-либо зависимости, загруженные из реестров, к которым у рабочего процесса нет доступа. none пока не поддерживается в C/C++, Swift, Go или Kotlin.

В своем проекте выбирал режим none.

${{ matrix.language }} - это действие считывает API языков репозитория и добавляет все поддерживаемые языки в матрицу заданий. Дополнительная настройка не требуется.

${{ matrix.build-mode }} - сканирование кода CodeQL для скомпилированных языков. Сканирование кода выполняется с помощью запросов к одной или нескольким базам данных CodeQL. Каждая база данных содержит представление кода на одном языке из нашего репозитория. Для компилируемых языков C/C++, C#, Go, Java, Kotlin и Swift процесс заполнения этой базы данных часто включает создание кода и извлечение данных.

### Создание файла рабочего процесса

В репозитории GitHub добавляем новый ФАЙЛ YAML в каталог github/workflows .
Выберем понятное имя файла, которое четко указывает, для чего предназначен рабочий процесс - codeql.yml

Скопируем и вставляем в него следующее содержимое YML:

```bash
# For most projects, this workflow file will not need changing; you simply need
# to commit it to your repository.
#
# You may wish to alter this file to override the set of languages analyzed,
# or to provide custom queries or build logic.
#
# ******** NOTE ********
# We have attempted to detect the languages in your repository. Please check
# the `language` matrix defined below to confirm you have the correct set of
# supported CodeQL languages.
#
name: "CodeQL Advanced"

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: '27 3 * * 3'

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    # Runner size impacts CodeQL analysis time. To learn more, please see:
    #   - https://gh.io/recommended-hardware-resources-for-running-codeql
    #   - https://gh.io/supported-runners-and-hardware-resources
    #   - https://gh.io/using-larger-runners (GitHub.com only)
    # Consider using larger runners or machines with greater resources for possible analysis time improvements.
    runs-on: ${{ (matrix.language == 'swift' && 'macos-latest') || 'ubuntu-latest' }}
    permissions:
      # required for all workflows
      security-events: write

      # required to fetch internal or private CodeQL packs
      packages: read

      # only required for workflows in private repositories
      actions: read
      contents: read

    strategy:
      fail-fast: false
      matrix:
        include:
        - language: actions
          build-mode: none
        - language: javascript-typescript
          build-mode: none
        # CodeQL supports the following values keywords for 'language': 'actions', 'c-cpp', 'csharp', 'go', 'java-kotlin', 'javascript-typescript', 'python', 'ruby', 'swift'
        # Use `c-cpp` to analyze code written in C, C++ or both
        # Use 'java-kotlin' to analyze code written in Java, Kotlin or both
        # Use 'javascript-typescript' to analyze code written in JavaScript, TypeScript or both
        # To learn more about changing the languages that are analyzed or customizing the build mode for your analysis,
        # see https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning.
        # If you are analyzing a compiled language, you can modify the 'build-mode' for that language to customize how
        # your codebase is analyzed, see https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/codeql-code-scanning-for-compiled-languages
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    # Add any setup steps before running the `github/codeql-action/init` action.
    # This includes steps like installing compilers or runtimes (`actions/setup-node`
    # or others). This is typically only required for manual builds.
    # - name: Setup runtime (example)
    #   uses: actions/setup-example@v1

    # Initializes the CodeQL tools for scanning.
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: ${{ matrix.language }}
        build-mode: ${{ matrix.build-mode }}
        # If you wish to specify custom queries, you can do so here or in a config file.
        # By default, queries listed here will override any specified in a config file.
        # Prefix the list here with "+" to use these queries and those in the config file.

        # For more details on CodeQL's query packs, refer to: https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/configuring-code-scanning#using-queries-in-ql-packs
        # queries: security-extended,security-and-quality

    # If the analyze step fails for one of the languages you are analyzing with
    # "We were unable to automatically build your code", modify the matrix above
    # to set the build mode to "manual" for that language. Then modify this step
    # to build your code.
    # ℹ️ Command-line programs to run using the OS shell.
    # 📚 See https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepsrun
    - if: matrix.build-mode == 'manual'
      shell: bash
      run: |
        echo 'If you are using a "manual" build mode for one or more of the' \
          'languages you are analyzing, replace this with the commands to build' \
          'your code, for example:'
        echo '  make bootstrap'
        echo '  make release'
        exit 1

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3
      with:
        category: "/language:${{matrix.language}}"
```
В приведенной выше композиции рабочего процесса:

Активируется при push возникновении или pull_request возникновении main в ветви, в которой все файлы изменились;

Задания будут выполняться в последней версии Ubuntu для языков из  matrix.language

Определяет strategy javascript-typescript в качестве language.

Действие actions/checkout@v4 Клонирует репозиторий в рабочую директорию для различных задач, таких как сборка, тестирование и развертывание кода. По умолчанию действие клонирует репозиторий, в котором определён рабочий процесс, но его можно настроить для клонирования любого репозитория GitHub.

Действие github/codeql-action/init@v3 GitHub используется для инициализации CodeQL.

Действие github/codeql-action/analyze@v3 GitHub выполняет анализ CodeQL.


### Анализ полученных результатов

CodeQL автоматически загружает результаты на вкладку безопасности репозитория.

Резулютаты доступны на вкладке Security репозитория.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2sast-action1.png)

На представленном скиншоте видно, что Действие отработало в штатном режиме.
Обнаружено 39 открытых уязвимостей кода и 28 закрытых.

По каждой уязвимости можно:
Увидеть место обнаружения.
Уровень уязвимости (ранжирован по наибольшей опасности): Критическая; Высокая; Умеренная; Низкая.
Перейдя по ссылке уязвимости можно ознакомиться с ее описанием и аналитикой.


## Этап 3. DAST

Критерии достижения:

1. Покрытие сервиса проверками.
2. Успешные сканы по всем имеющимся методам.
3. Выгрузка результатов в CI или систему менеджмента уязвимостей.

### Решение:

### Для достижения цели использован ZAP Full Scan

  ZAP Full Scan - выполнение динамического тестирования безопасности приложений (DAST). Действие «Полное сканирование ZAP» запускает ZAP-паука для сканирования указанной цели (по умолчанию без ограничения по времени), после чего выполняется дополнительное сканирование с помощью AJAX-паука, а затем полное активное сканирование перед отправкой результатов.

### Создание файла рабочего процесса

В репозитории GitHub добавляем новый ФАЙЛ YAML в каталог github/workflows .
Выберем понятное имя файла, которое четко указывает, для чего предназначен рабочий процесс - zap-scan.yml

Скопируем и вставляем в него следующее содержимое YML:

```bash
name: OWASP ZAP Scan

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  zap_scan:
    runs-on: ubuntu-latest
    name: Scan the webapplication
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          ref: main

      - name: ZAP Scan
        uses: zaproxy/action-full-scan@v0.12.0
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          docker_name: 'ghcr.io/zaproxy/zaproxy:stable'
          target: ${{ secrets.PATH_TO_SERVICE }}
          cmd_options: '-a'
```

В приведенной выше композиции рабочего процесса:

Активируется при push возникновении или pull_request возникновении main в ветви, в которой все файлы изменились;

Задания будут выполняться в последней версии Ubuntu.

Действие actions/checkout@v4 Клонирует репозиторий в рабочую директорию для различных задач, таких как сборка, тестирование и развертывание кода. По умолчанию действие клонирует репозиторий, в котором определён рабочий процесс, но его можно настроить для клонирования любого репозитория GitHub.

Действие zaproxy/action-full-scan@v0.12.0. Сканирование URL-адреса веб-приложения. Это может быть общедоступное веб-приложение или локально доступный URL.

«ghcr.io/zaproxy/zaproxy» — это имя образа Docker, который используется по умолчанию в действии GitHub для запуска стабильной версии инструмента ZAP.

Использованы два секрета: secrets.GITHUB_TOKEN - это токен доступа к установке GitHub App, который можно использовать для аутентификации от имени приложения, установленного в репозитории;
secrets.PATH_TO_SERVICE - путь до нашего сайта.


Важно: действие выполняет атаки на целевой сайт, поэтому следует сканировать только те цели, для которых есть разрешение на тестирование.


### Анализ полученных результатов

Отчет проверки хранится в репозитории в виде артефакта.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2dast-action.png)

На представленном скиншоте видно, что Действие отработало в штатном режиме. Внизу обведен созданный артефакт.
Скачав и распаковав артифакт в виде архива, получаем три отчета в виде файлов json, html и md.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2dast-action1.png)

В HTML-отчёте ZAP (report_html.html) указывается, какая проблема обнаружена, на каком HTTP-запросе, а также решение этой проблемы. Кроме того, в документе могут быть приведены ссылки на ресурсы.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2dast-action2.png)

## Этап 4. Security Checks

Критерии достижения:

1. Проверка репозиториев на секреты.
2. Проверка конфигурации или образов.

### Решение:

### 1. Проверка репозиториев на секреты - Gitleaks

Для проверки репозитория на секреты использован Gitleaks  - это инструмент SAST для обнаружения и предотвращения использования жестко заданных секретов, таких как пароли, ключи API и токены, в репозиториях git. Gitleaks — это простое в использовании универсальное решение для обнаружения секретов в коде. Включив Gitleaks-Action в свои рабочие процессы GitHub, получаем оповещения об утечке секретов сразу после обнаружения.

### Создание файла рабочего процесса

В репозитории GitHub добавляем новый ФАЙЛ YAML в каталог github/workflows .
Выберем понятное имя файла, которое четко указывает, для чего предназначен рабочий процесс - secret-scan.yml

Скопируем и вставляем в него следующее содержимое YML:

```bash
name: gitleaks
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:
  schedule:
    - cron: "0 4 * * *" # run once a day at 4 AM
jobs:
  scan:
    name: gitleaks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE}} # Only required for Organizations, not personal accounts.
```

В приведенной выше композиции рабочего процесса:

Активируется при push возникновении или pull_request возникновении main в ветви, в которой все файлы изменились; Как задание cron - по расписанию.

Задание будет выполняться в последней версии Ubuntu.

Действие actions/checkout@v4 Клонирует репозиторий в рабочую директорию для различных задач, таких как сборка, тестирование и развертывание кода. По умолчанию действие клонирует репозиторий, в котором определён рабочий процесс, но его можно настроить для клонирования любого репозитория GitHub.

Действие gitleaks/gitleaks-action@v2 часть конфигурации рабочего процесса GitHub, которая использует инструмент Gitleaks для обнаружения конфиденциальной информации в коде.

Использованы два секрета: secrets.GITHUB_TOKEN - это токен доступа к установке GitHub App, который можно использовать для аутентификации от имени приложения, установленного в репозитории;
secrets.GITLEAKS_LICENSE - Лицензия требуется только для организаций, а не для личных аккаунтов.

### Анализ полученных результатов

На представленном ниже скиншоте видно, что Действие отработало в штатном режиме - Утечек не обнаружено. Внизу обведен созданный артефакт - gitleaks-results.sarif.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2gitleaks-action.png)


### 2. Проверка конфигурации или образов.

Для проверки конфигурации или образов использован Validate Configs Github Action - будет рекурсивно сканировать указанный путь поиска для следующих типов конфигурационных файлов:

ML-список Apple PList
CSV - файл
EDITORCONFIG ( РЕДАКТОР )
ENV
HCL
ХОКОН
INI
JSON
Свойства
ТОМЛ
XML
YAML

Каждый файл будет проверен на правильность синтаксиса, а результаты собраны в отчет, в котором будет указан путь к файлу и его статус: недействителен или действителен. Если файл недействителен, будет отображена ошибка с указанием номера строки и столбца, в которых она возникла.

### Создание файла рабочего процесса

В репозитории GitHub добавляем новый ФАЙЛ YAML в каталог github/workflows .
Выберем понятное имя файла, которое четко указывает, для чего предназначен рабочий процесс - validate-configs.yml

Скопируем и вставляем в него следующее содержимое YML:

```bash
name: "Validate Configs"

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: '27 3 * * 3'

jobs:
  validate-config-files:
    runs-on: ubuntu-latest
    steps:
        - uses: kehoecj/validate-configs-action@v4.0.1
          with:
              depth: 0
              reporter: "json"
```

В приведенной выше композиции рабочего процесса:

Активируется при push возникновении или pull_request возникновении main в ветви, в которой все файлы изменились; Как задание cron - по расписанию.

Задание будет выполняться в последней версии Ubuntu.

Действие kehoecj/validate-configs-action@v4.0.1 это действие GitHub, которое позволяет проверять файлы конфигурации с помощью инструмента config-file-validator

### Анализ полученных результатов

На представленном ниже скиншоте видно, что Действие отработало в штатном режиме. Ошибки не обнаружены.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2validate-action.png)


### Dependabot

Dependabot — инструмент, который автоматизирует процесс обновления зависимостей, помогает оставаться в курсе последних выпусков и исправлений безопасности.

Чтобы включить Dependabot в репозитории на GitHub, нужно выполнить следующие шаги:

Перейти на главную страницу репозитория на GitHub.

Нажать на вкладку «Настройки». Если её нет, нужно выбрать выпадающее меню, затем нажать на «Настройки».

В разделе «Безопасность» на боковой панели выбрать «Безопасность кода».

В разделе «Безопасность кода», справа от предупреждений Dependabot, нажать на кнопку «Включить» для предупреждений Dependabot, обновлений безопасности Dependabot и обновлений версий Dependabot

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2dependabot-action.png)

Dependabot – инструмент, который отслеживает уязвимости в зависимостях кода и открывает запросы на их обновление до минимально необходимой версии. Инструмент загружает файлы зависимостей и ищет устаревшие или небезопасные требования. Если какая-то зависимость устарела, Dependabot открывает отдельные запросы на получение обновлений для каждой из них. Разработчик контролирует прохождение всех тестов, сканирует журнал изменений и заметки о выпуске, а затем нажимаете кнопку слияния.


На представленном ниже скиншоте видим страницу оповещения Dependabot.

![alt text](https://github.com/alekseypopkov/dso_test/blob/main/png/2dependabot-action1.png)


### Зоны роста

Зоны роста для всех инструментов вижу (как минимум) в осуществлении настройки оповещения в телеграм канал.

В разделе - Проверка конфигурации или образов: - настроить инструмент проверки Docker образов; доработать инструмент Validate Configs Github Action для формирования файла отчета json.


## License

MIT
