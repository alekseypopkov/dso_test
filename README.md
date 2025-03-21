# Дипломное задание профессии Специалист по информационной безопасности (Track DevSecOps)


## Задача

Создать безопасный пайплайн для open-source проекта. Он должен включать в себя статический анализатор, динамический анализатор, чекеры безопасности, Security Gateway и документацию процесса.

## Исходные данные
1. Требования к проекту. Проект должен быть с открытым исходным кодом, представлять из себя веб-сервис или сайт с функционалом, использованием баз данных или кеша.

2. Требования к покрытию проекта тестами безопасности. Проект должен проверяться на наличие уязвимостей в коде. Ни один язык программирования или фреймворк не должны быть пропущены для конкретного проекта. Весь процесс должен быть задокументирован и описан с аналитикой выбора инструментов и зон роста.

## Этапы проектирования

### Этап 1. CI/CD

Критерии достижения:

1. Настроенный пайплайн по сборке и доставке программного обеспечения.
2. Использование облачных сервисов для раскатки.
3. Хорошо задокументированный процесс.

Решение:

1. Платформа для организации CI/CD выбрана GitHub Actions. Сервер для разворачивания предоставлен в виде VPS.
2. В качестве примера для реализации Задачи взят проект https://github.com/appsecco/dvna. Использован один из трех вариантов - официальный образ. Docker.Damn Vulnerable NodeJS Application (DVNA) — это простое приложение NodeJS, демонстрирующее 10 основных уязвимостей по версии OWASP и содержащее рекомендации по устранению и предотвращению этих уязвимостей. Приложение работает на основе часто используемых библиотек, таких как express, passport, sequelize и т. д. С использованием клонирования создан публичный репозиторий Dso_test.
3. Начнем с настройки GitHub Actions. Для автоматического запуска при каждой команде push, в директории ./github/workflows, создан файл deploy.yml -  файлы конфигурации для GitHub Actions. Файл конфигурации запускает авторизацию на сервере с помощью пары ssh-ключей. Публичный ключ расположен на сервере в директории ./ssh. Приватный ключ помещен в "секрет" в настройках репозитория. В "секрет" помещены - адрес сервера, пользователь для авторизации, путь до Bash-скрипта. После успешной авторизации файл конфигурации запускает Bash-скрипт на сервере. Bash-скрипт выполняет весь процесс обновления приложения. Сайт доступен по адресу http://217.18.61.156:9090/

### Этап 2. SAST

Критерии достижения:

1. Покрытие кода проверками.
2. Успешные проверки во время сборки.
3. Выгрузка результатов в CI или систему менеджмента уязвимостей.

Решение:

1. Для достижения цели использован CodeQL Action (codeql.yml) - Это действие запускает ведущий в отрасли механизм семантического анализа кода GitHub, CodeQL, для поиска уязвимостей в исходном коде репозитория. Затем он автоматическизагружает результаты на GitHub, чтобы их можно было отобразить на вкладке безопасности репозитория. CodeQL выполняет расширяемый набор запросов, разработанных сообществом и лабораторией безопасности GitHub для поиска распространенных уязвимостей.
2. Резулютаты доступны на вкладке Security репозитория.


### Этап 3. DAST

Критерии достижения:

1. Покрытие сервиса проверками.
2. Успешные сканы по всем имеющимся методам.
3. Выгрузка результатов в CI или систему менеджмента уязвимостей.

Решение:

1. Для достижения цели использован ZAP Full Scan (zap-scan.yml) - выполнения динамического тестирования безопасности приложений (DAST). Действие «Полное сканирование ZAP» запускает ZAP-паука для сканирования указанной цели (по умолчанию без ограничения по времени), после чего выполняется дополнительное сканирование с помощью AJAX-паука, а затем полное активное сканирование перед отправкой результатов.
2. Отчет проверки хранится в репозитории в виде артефакта. Скачав и распокавав артифакт в виде архива, получаем три отчета в виде файлов json, html и md.


### Этап 4. Security Checks

Критерии достижения:

1. Проверка репозиториев на секреты.
2. Проверка конфигурации или образов.

Решение:

1. Для проверки репозитория на секреты использован Gitleaks (secret-scan.yml) - это инструмент SAST для обнаружения и предотвращения использования жестко заданных секретов, таких как пароли, ключи API и токены, в репозиториях git. Gitleaks — это простое в использовании универсальное решение для обнаружения секретов, прошлых или настоящих, в вашем коде. Включив Gitleaks-Action в свои рабочие процессы GitHub, получаем оповещения об утечке секретов сразу после обнаружения.
2. Для проверки конфигурации или образов использован Validate Configs Github Action (validate-configs.yml) - Config-file-validator будет рекурсивно сканировать указанный путь поиска для следующих типов конфигурационных файлов:
XML-список Apple PList
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

## License

MIT
