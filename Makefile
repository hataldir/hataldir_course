USER_NAME=hataldir
TOKEN=k2uyd4qfh1iDXTpwg-7-
GITLAB_URL=/gitlab.34.78.244.197.nip.io
USER_PASS=otusgitlab
SEARCH_TOKEN=0c6dd090429c8d2a4192374c44a4de
PROJECT=soy-sound-282710
#PROJECT=docker-275212
CRED=/root/.config/gcloud/legacy_credentials/hataldir@k66.ru/adc.json

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


helm-init:
	@echo "Инициализация helm" ; \
	helm init 
ingress-install:
	@echo "Установка Nginx Ingress" ;\
	helm install stable/nginx-ingress --name nginx

ingress-ip-add:

ingress-ip:
	@echo "IP-адрес nginx ingress" ;\
	INGRESS=`kubectl get svc nginx-nginx-ingress-controller -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	echo $$INGRESS ;\
	export INGRESS=$$INGRESS

gitlab-install:
	@echo "Установка Gitlab с помощью helm" ; \
	cd charts/gitlab ; \
	helm upgrade gitlab . --install ; \

gitlab-pass:
	@echo "Первоначальный пароль gitlab" : \
	kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}'|base64 --decode ; echo

gitlab-ip:
	@echo "IP-адрес веб-интерфейса gitlab" ; \
	kubectl get ingress gitlab-webservice -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo


gke:
	@echo "Создание кластера GKE с помощью terraform" ; \
#	gcloud auth login ;\
	gcloud config set project ${PROJECT} ;\
	export GOOGLE_CREDENTIALS=${CRED} ;\
	cd terraform ; \
	rm terraform.tfstate.* ;\
	terraform init ;\
	terraform apply --auto-approve ;\
	gcloud container clusters get-credentials ${PROJECT}-gke --region europe-west1
# kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $(gcloud config get-value account)

gitlab-init:
	@echo "Создание группы и установка переменных" ;\
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" --header "Content-Type: application/json" --data '{"path": "${USER_NAME}", "name": "${USER_NAME}", "visibility": "public" }'  "http://${GITLAB_URL}/api/v4/groups/" ;\
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=CI_REGISTRY_USER" --form "value=${USER_NAME}" ;\
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=CI_REGISTRY_PASSWORD" --form "value=${USER_PASS}" ;\
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=GITLAB_URL" --form "value=${GITLAB_URL}" ; \
	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=SEARCH_ID" --form "value=3"   # change to 3

gitlab-ip-add:

#gitlab-init2:
#	curl --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "http://${GITLAB_URL}/api/v4/groups/3/variables" --form "key=TOKEN" --form "value=${SEARCH_TOKEN}"

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
	cd src/search_deploy ;\
	git remote remove origin ;\
	git remote add origin http://${GITLAB_URL}/${USER_NAME}/search.git ;\
	git add . ;\
	git commit -m "initial commit" ;\
	git push -u origin master

gitlab-push: gitlab-init gitlab-push-webui gitlab-push-crawler gitlab-push-search
	
prom-install:
	@echo "Установка Prometheus" ;\
	cd charts/prometheus ;\
	helm upgrade prometheus . --install

grafana-install:
	@echo "Установка Grafana" ;\
	cd charts/grafana ;\
	helm upgrade grafana . --install

grafana-pass:
	@echo "Пароль Grafana" ;\
	kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

mongodb-ex:
	cd charts/prometheus-mongodb-exporter ;\
	helm upgrade mongodb-exporter-s . -f values-s.yaml --install ;\
	helm upgrade mongodb-exporter-p . -f values-p.yaml --install

rabbitmq-ex:
	cd charts/prometheus-rabbitmq-exporter ;\
	helm upgrade rabbitmq-exporter-s . -f values-s.yaml --install ;\
	helm upgrade rabbitmq-exporter-p . -f values-p.yaml --install

web: gitlab-install prom-install mongodb-ex rabbitmq-ex grafana-install

search-ip-prod:
	@echo "IP-адрес веб-интерфейса окружения production" ; \
	kubectl get ingress production-webui -n production -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo

search-ip-staging:
	@echo "IP-адрес веб-интерфейса окружения staging" ; \
	kubectl get ingress staging-webui -n staging -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo

search-ip: search-ip-staging search-ip-prod
