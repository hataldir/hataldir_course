Курсовой проект.

Тема: Создание процесса непрерывной поставки для приложения с применением Практик CI/CD и быстрой обратной связью

Студент: Лунев Денис

Описание:

Настроен процесс непрерывной интеграции и непрервыной поставки учебного микросервисного приложения search_engine от express42.
Рабочей платформой для приложения и всех сопутствующих сервисов является кластер Kubernetes в Google Cloud.

1. Разворачивание платформы
 
Кластер создается при помощи terraform.
Конфигурационные файлы - в каталоге terraform. Запуск - make gke.

Далее устанавливается  Helm (make helm-init)

С его помощью устнавливается nginx-ingress (make ingress-install) и определяется его ip (make ingress-ip)
(TODO) Адрес прописывается в values.yaml для Prometheus и Grafana.

С помощью Helm устанавливается Gitlab (make gitlab-install)
Чарт helm находится  в каталоге charts/gitlab. 
Определяются адрес веб-интерфейса Gitlab (make gitlab-ip) и пароль пользователя root (make gitlab-pass)
(TODO) Адрес Gitlab прописывается в Makefile и charts/gitlab/values.yaml  (make gitlab-ip-add)

Устанавливаются Prometheus и Grafana (make monitor).
Чарты находятся в charts/prometheus и charts/grafana.

2. Работа с приложением в Gitlab.

У нас равернут Gitlab, в нем создана группа hataldir и три проекта - crawler, webui и search. Адрес веб-интерфейса - gitlab.$gitlab-ip.nip.io, где $gitlab-ip - ip-адрес, определенный в предыдущем пункте (make gitlab-ip)
Далее необходимо зайти под root в веб-интерфейс Gitlab, в Settings/Access Tokens получить Access token и внести его в Makefile в переменную TOKEN. Также стоит сменить первоначальный пароль root на более простой.

Затем можно выполнить загрузку проектов в Gitlab (make gitlab-push).
Проекты находятся в src/crawler, src/webui и src/search.

Далее снова нужно идти в веб-интерфейс Gitlab и получать еще один токен - в проекте Search в Settings, CI/CD, Pipeline Triggers. Этот токен тоже нужно внести в Makefile в переменную SEARCH_TOKEN.

Теперь в каждом проекте работают пайплайны.

Для crawler и webui пайплайн состоит из следующих стадий:

build - создание контейнера сервиса
test - создание контейнера, не запускающего приложение, а выполняющего только тесты
review - создание отдельного окружения для code review
cleanup - удаление окружения review (вручную)
trigger_deploy - запуск пайплайна проекта search
release - заливка контейнера на докерхаб
  
Для search пайплайн выглядит так:
staging - создание/обновление окружения staging
production - создание/обновление окружения production (вручную)

После выполнения пайплайнов мы имеем окружения staging и production, доступные извне. Их адреса можно посмотреть в проекте search в Operations, Environments.

3. Мониторинг

Для мониторинга используются prometheus и grafana. Они доступны по адресам prometheus.$ingress-ip.nip.io и grafana.$ingress-ip.nip.io, где $ingress-ip - адрес ingress, определенный в первом пункте (make ingress-ip).
(TODO) Для мониторинга сервисов развернуты exporters для mongodb и rabbitmq.

Пароль для входа в grafana - otusgitlab.
Доступны два дашборда - стандартный для Kubernetes и (TODO) свой для мониторинга приложения.
