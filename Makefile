USER_NAME=hataldir
#TOKEN=k2uyd4qfh1iDXTpwg-7-
TOKEN=hx3ZWBSTGzBKxNPyFUzo
#GITLABURL=/gitlab.34.78.244.197.nip.io
GITLAB_URL=gitlab.35.241.233.180.nip.io
USER_PASS=otusgitlab
SEARCH_TOKEN=0c6dd090429c8d2a4192374c44a4de
PROJECT=melodic-stone-285404
#PROJECT=soy-sound-282710
#PROJECT=docker-275212
#CRED=/root/.config/gcloud/legacy_credentials/hataldir@k66.ru/adc.json
CRED=/root/.config/gcloud/legacy_credentials/verash1985@gmail.com/adc.json

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

ingress-ip:
	@echo "IP-адрес nginx ingress" ;\
	INGRESS=`kubectl get svc nginx-nginx-ingress-controller -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	echo $$INGRESS ;\
	export INGRESS=$$INGRESS ;\
	sed -i "s/grafana.[0-9.]*.nip.io/grafana.$$INGRESS.nip.io/" charts/grafana/values.yaml ;\
	sed -i "s/prometheus.[0-9.]*.nip.io/prometheus.$$INGRESS.nip.io/" charts/prometheus/values.yaml

gitlab-install:
	@echo "Установка Gitlab с помощью helm" ; \
	cd charts/gitlab ; \
	helm upgrade gitlab . --install ; \
#	kubectl delete secret gitlab-gitlab-initial-root-password
#	kubectl create secret generic gitlab-gitlab-initial-root-password --from-literal=password=otusgitlab

gitlab-upgrade:
	@cd charts/gitlab ; \
	helm upgrade gitlab . --install ; \

gitlab-pass:
	@echo "Первоначальный пароль gitlab" ; \
	kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode; echo 

gitlab-ip:
	@echo "IP-адрес веб-интерфейса gitlab" ; \
	GITLABIP=`kubectl get ingress gitlab-webservice -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	echo $$GITLABIP ;\
	export GITLABIP=$$GITLABIP ;\
	sed -i "s/domain: [0-9.]*.nip.io/domain: $$GITLABIP.nip.io/" charts/gitlab/values.yaml ;\
	sed -i "s/GITLAB_URL=gitlab.[0-9.]*.nip.io/GITLAB_URL=gitlab.$$GITLABIP.nip.io/" Makefile

gitlab-url:
	@echo "Веб-интерфейс Gitlab:" ;\
	GITLABIP=`kubectl get ingress gitlab-webservice -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	export GITLABIP=$$GITLABIP ;\
	echo "http://gitlab.$$GITLABIP.nip.io"

gke:
	@echo "Создание кластера GKE с помощью terraform" ; \
#	gcloud auth login ;\
	gcloud config set project ${PROJECT} ;\
	export GOOGLE_CREDENTIALS=${CRED} ;\
	cd terraform ; \
	sed -i "s/project_id = \"[a-z0-9-]*\"/project_id = \"${PROJECT}\"/" terraform.tfvars ;\
	rm terraform.tfstate.* ;\
	terraform init ;\
	terraform apply --auto-approve ;\
	gcloud container clusters get-credentials ${PROJECT}-gke --region europe-west1
# kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $(gcloud config get-value account)

gitlab-init:
	@echo "Создание группы и установка переменных" ;\
	curl -k --request POST --header "PRIVATE-TOKEN: ${TOKEN}" --header "Content-Type: application/json" --data '{"path": "${USER_NAME}", "name": "${USER_NAME}", "visibility": "public" }'  "https://${GITLAB_URL}/api/v4/groups/" ;\
	curl -k --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "https://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=CI_REGISTRY_USER" --form "value=${USER_NAME}" ;\
	curl -k --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "https://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=CI_REGISTRY_PASSWORD" --form "value=${USER_PASS}" ;\
	curl -k --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "https://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=GITLAB_URL" --form "value=${GITLAB_URL}" ; \
	curl -k --request POST --header "PRIVATE-TOKEN: ${TOKEN}" "https://${GITLAB_URL}/api/v4/groups/2/variables" --form "key=SEARCH_ID" --form "value=3"   # change to 3

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
	PROD=`kubectl get ingress production-webui -n production -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	echo "http://$$PROD"

search-ip-staging:
	@echo "IP-адрес веб-интерфейса окружения staging" ; \
	STAGE=`kubectl get ingress staging-webui -n staging -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	echo "http://$$STAGE"

search-ip-mon:
	@echo "IP-адреса системы мониторинга" ;\
    	INGRESS=`kubectl get svc nginx-nginx-ingress-controller -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo` ;\
	export INGRESS=$$INGRESS ;\
	echo "http://grafana.$$INGRESS.nip.io" ;\
	echo "http://prometheus.$$INGRESS.nip.io" ;\

show-ip: search-ip-staging search-ip-prod search-ip-mon

log: elastic fluentd kibana
#	@echo "Установка ELK" ;\
#	cd charts/elastic-stack ;\
#	helm upgrade elastic-stack . --install


elastic:
	@echo "Установка Elasticsearch" ;\
	cd charts/elasticsearch ;\
	helm upgrade elasticsearch . --install
fluentd:
	@echo "Установка Fluentd" ;\
	cd charts/fluentd ;\
	helm upgrade fluentd . --install
kibana:
	@echo "Установка Kibana" ;\
	cd charts/kibana ;\
	helm upgrade kibana . --install

wait:	
	@echo "Ожидание" ;\
	sleep 60

wait2:	
	@echo "Ожидание" ;\
	sleep 60

wait3:	
	@echo "Ожидание" ;\
	sleep 120

wait4:	
	@echo "Ожидание" ;\
	sleep 60

install:	gke helm-init wait ingress-install wait2 ingress-ip web wait3 gitlab-ip gitlab-upgrade wait4 gitlab-pass gitlab-url
#go to webinterface, write token
#make gitlab-push
#go to web, run pipelines
#make show-ip

