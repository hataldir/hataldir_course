## Курсовой проект.

## Тема: Создание процесса непрерывной поставки для приложения с применением Практик CI/CD и быстрой обратной связью

Студент: Лунев Денис

## Описание:

Настроен процесс непрерывной интеграции и непрервыной поставки учебного микросервисного приложения search_engine от express42.
Рабочей платформой для приложения и всех сопутствующих сервисов является кластер Kubernetes в Google Cloud.
Большинство операций для развертывания системы и получения данных выполняется с помощью команды make.


## 1. Разворачивание платформы
 
Кластер создается при помощи terraform.
Конфигурационные файлы - в каталоге terraform. Запуск - make gke.

Далее устанавливается  Helm (make helm-init), ждем его запуска, устанавливаем nginx-ingress  (make ingress-install), ждем его запуска и определяем его ip (make ingress-ip)

(TODO) Адрес прописывается в values.yaml для Prometheus и Grafana.

С помощью Helm устанавливаются Gitlab, Prometheus и Grafana (make web)
Чарты находятся  в каталоге charts. 
Определяется адрес веб-интерфейса Gitlab (make gitlab-ip).

(TODO) Адрес Gitlab прописывается в Makefile и charts/gitlab/values.yaml

## 2. Работа с приложением в Gitlab.

У нас развернут Gitlab, в нем создана группа hataldir и три проекта - crawler, webui и search. Адрес веб-интерфейса - gitlab.GITLAB-IP.nip.io, где GITLAB-IP - ip-адрес, определенный в предыдущем пункте (make gitlab-ip)
Далее необходимо зайти под root/otusgitlab в веб-интерфейс Gitlab, в Settings/Access Tokens получить Access token, внести его в Makefile в переменную TOKEN и выполнить make gitlab-init.

Затем можно выполнить загрузку проектов в Gitlab (make gitlab-push).
Проекты находятся в src/crawler, src/webui и src/search.

Далее снова нужно идти в веб-интерфейс Gitlab и получать еще один токен - в проекте Search в Settings, CI/CD, Pipeline Triggers. Этот токен нужно внести в переменную TOKEN в свойствах группы hataldir.

Теперь в каждом проекте работают пайплайны.

Для crawler и webui пайплайн состоит из следующих стадий:

- build - создание контейнера сервиса

- test - создание контейнера, не запускающего приложение, а выполняющего только тесты

- review - создание отдельного окружения для code review

- cleanup - удаление окружения review (вручную)

-  trigger_deploy - запуск пайплайна проекта search

-  release - заливка контейнера на докерхаб
  
Для search пайплайн выглядит так:

- staging - создание/обновление окружения staging

- production - создание/обновление окружения production (вручную)

После выполнения пайплайнов мы имеем окружения staging и production, доступные извне. Чтобы узнать их адреса, можно выполнить команду make search-ip.

## 3. Мониторинг

Для мониторинга используются prometheus и grafana. Они доступны по адресам prometheus.INGRESS-IP.nip.io и grafana.INGRESS-IP.nip.io, где INGRESS-IP - адрес ingress, определенный в первом пункте (make ingress-ip).
Для мониторинга сервисов развернуты exporters для mongodb и (TODO) rabbitmq.

Пароль для входа в grafana - otusgitlab.
Доступны два дашборда - стандартный для Kubernetes и (TODO) свой для мониторинга приложения.
