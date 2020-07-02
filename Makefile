USER_NAME=hataldir

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
	cd charts/search ; \
	helm install --name search .

helm-delete:
	cd charts/search ; \
	helm delete search --purge

helm-upgrade:
	cd charts/search ; \
	helm upgrade search .

helm-init:
	echo "Инициализация helm" ; \
	helm init 

search-ip:
	echo "IP-адрес веб-интерфейса приложения" ; \
	kubectl get ingress search-webui -ojsonpath='{.status.loadBalancer.ingress[0].ip}'; echo


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




      



