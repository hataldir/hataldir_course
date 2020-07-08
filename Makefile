USER_NAME=hataldir
TOKEN=x1QxErmyePz4z8P2wnq2
GITLAB_URL=gitlab.34.77.107.70.nip.io
USER_PASS=otusgitlab
SEARCH_TOKEN=9294ea2a5f6bade5665343bf9f0287

#default: all

build_crawler:
	export USER_NAME=${USER_NAME} ; \
        cd src/search_engine_crawler ; \
        docker build -t ${USER_NAME}/crawler:latest .

build_webui:
	export USER_NAME=${USER_NAME} ; \
        cd src/search_engine_ui ; \
        docker build -t ${USER_NAME}/webui:latest .

build: build_crawler build_webui

push_crawler:
	docker push ${USER_NAME}/crawler
push_webui:
	docker push ${USER_NAME}/webui

push: push_crawler push_webui


helm-install:
	echo "Установка приложения с помощью helm" ; \
	cd src/search_deploy/search ; \
	helm install --name search .

helm-delete:
	cd src/search_deploy/search ; \
	helm delete search --purge

helm-upgrade:
	cd src/search_deploy/search ; \
	helm upgrade search .

helm-init:
	echo "Инициализация helm" ; \
	helm init 
	echo "Установка Nginx Ingress" ;\
	helm install stable/nginx-ingress --name nginx


gitlab-install:
	echo "Установка Gitlab с помощью helm" ; \
	cd charts/gitlab ; \
	helm install --name gitlab . ; \

gitlab-pass:
	echo "Первоначальный пароль gitlab" : \
	kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo

gitlab-ip:
	echo "IP-адрес веб-интерфейса gitlab" ; \
	kubectl get ingress gitlab-webservice -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo


gke:
	echo "Создание кластера GKE с помощью terraform" ; \
	cd terraform ; \
	terraform apply --auto-approve ;\
	gcloud container clusters get-credentials docker-275212-gke --region europe-west1

gitlab-init:
	echo "Создание группы и установка переменных"

# change groups/3 to groups/1
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" --header "Content-Type: application/json" --data '{"path": "${USER_NAME}", "name": "${USER_NAME}", "visibility": "public" }'  "http://${GITLAB_URL}/api/v4/groups/"
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/3/variables" --form "key=CI_REGISTRY_USER" --form "value=${USER_NAME}"
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/3/variables" --form "key=CI_REGISTRY_PASSWORD" --form "value=${USER_PASS}"
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/3/variables" --form "key=GITLAB_URL" --form "value=${GITLAB_URL}"
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/3/variables" --form "key=SEARCH_ID" --form "value=6"   # change to 3

gitlab-ip-add:

gitlab-init2:
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/3/variables" --form "key=TOKEN" --form "value=${SEARCH_TOKEN}"

gitlab-push-webui:
	cd src/search_engine_ui ;\
	git remote remove origin ;\
	git remote add origin http://${GITLAB_URL}/${USER_NAME}/webui.git ;\
	git add . ;\
	git commit -m "initial commit" ;\
	git push -u origin master

gitlab-push-crawler:
	cd src/search_engine_crawler ;\
	git remote remove origin ;\
	git remote add origin http://${GITLAB_URL}/${USER_NAME}/crawler.git ;\
	git add . ;\
	git commit -m "initial commit" ;\
	git push -u origin master

gitlab-push-search:
	cd charts/search ;\
	git remote remove origin ;\
	git remote add origin http://${GITLAB_URL}/${USER_NAME}/search.git ;\
	git add . ;\
	git commit -m "initial commit" ;\
	git push -u origin master

gitlab-push: gitlab-init gitlab-push-webui gitlab-push-crawler gitlab-push-search
	
prom-install:
	echo "Установка Prometheus" ;\
	cd charts/prometheus ;\
	helm upgrade prometheus . --install

grafana-install:
	echo "Установка Grafana" ;\
	cd charts/grafana ;\
	helm upgrade grafana . --install

grafana-pass:
	echo "Пароль Grafana" ;\
	kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

mongodb-ex:
	cd charts/prometheus-mongodb-exporter ;\
	helm upgrade mongodb-exporter-s . -f values-s.yaml --install ;\
	helm upgrade mongodb-exporter-p . -f values-p.yaml --install

rabbitmq-ex:
	cd charts/prometheus-rabbitmq-exporter ;\
	helm upgrade rabbitmq-exporter-s . -f values-s.yaml --install ;\
	helm upgrade rabbitmq-exporter-p . -f values-p.yaml --install

monitor: prom-install mongodb-ex rabbitmq-ex grafana-install



ingress-ip-add:

ingress-ip:
	echo "IP-адресс nginx ingress" ;\
	kubectl get svc nginx-nginx-ingress-controller -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo

search-ip-prod:
	echo "IP-адрес веб-интерфейса окружения production" ; \
	kubectl get ingress production-webui -n production -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo

search-ip-staging:
	echo "IP-адрес веб-интерфейса окружения staging" ; \
	kubectl get ingress staging-webui -n staging -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo

search-ip: search-ip-staging search-ip-prod
