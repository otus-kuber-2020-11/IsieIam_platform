# IsieIam_platform
IsieIam Platform repository

<details>
<summary>Домашнее задание к лекции №2 (Знакомство с Kubernetes, основные понятия и архитектура)
</summary>

### Предзадание:
 - создана ветка kubernetes-prepare, в ней:
 - добавлен .travis.yml
 - добавлен шаблон для описания PR
 - добавлен .github/auto_assign.yml
 - создан PR к ветке main

### Задание:
 - установлен minikube (sudo -E minikube start --driver=none)
 - minikube ssh для выбранного способа старта не работает, т.к. vm как таковой нет, в вышестоящем запуске миникуб запускается в docker
 - установлен k8s dashboard и k9s

```
Для получения token для dashboard использовать:
kubectl get secrets -n kubernetes-dashboard
kubectl describe secret kubernetes-dashboard-token-**** -n kubernetes-dashboard
```

 - Проверено удаление системных подов: выжили не все - storage-provisioner сгинул навсегда.

```
coredns-f9fd979d6-48jsj - контролируется replica-set
kube-proxy-c4zf9 - контролируется DaemonSet/kube-proxy
Остальные поды контролируются - Node/isie-virtualbox, они являются static pods и контролируются kubelet, доп инфо тут:
  https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/
их yml хранятся в /etc/kubernetes/manifest/
```

 - Создан dockerfile для запуска nginx, в него помещен измененный дефолтный конфиг и простой homework.html для тестов.
 - В dockerfile добавлены команды для запуска nginx от пользователя с uid 1001, самого nginx на 8000 порту и root каталогом /app
 - Собран и запушен в hub.docker.com образ.

```
для сборки и пуша использовать:
sudo docker build -t isieiam/nginx-test:1.0 .
sudo docker push isieiam/nginx-test:1.0
```

 - Написан web-pod.yaml и применен в миникуб

```
для установки пода из файла:
kubectl apply -f web-pod.yaml
для получения yaml пода:
kubectl get pod web -o yaml
альтернативно - вывод описания пода
kubectl describe pod web
```

 - Добавлен к под-у web init контейнер, который скачивает статику с https://tinyurl.com/otus-k8s-intro и которое через volume попадает к nginx в его рутовую директорию.

```
для проверки и проброса порта наружу:
kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
```

 - Hipster-shop - склонирован репо, собран и запушен в hub.docker.com frontend

```
для сборки и пуша фронта:
sudo docker build -t isieiam/hipster-front:1.0 .
sudo docker push isieiam/hipster-front:1.0
генерация манифестов средствами kubectl:
kubectl run frontend --image isieiam/hipster-front:1.0 --restart=Never --dry-run=true -o yaml > frontend-pod.yaml
```

### Задание со *:

> Выясните причину, по которой pod frontend находится в статусе Error

Причина в том что он не может найти переменные окружения:

```
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set
```

> Создайте новый манифест frontend-pod-healthy.yaml...В результате, после применения исправленного манифеста pod frontend должен находиться в статусе Running...Поместите исправленный манифест frontend-pod-healthy.yaml в директорию kubernetes-intro

Добавлены переменные окружения из https://github.com/GoogleCloudPlatform/microservices-demo/blob/master/kubernetes-manifests/frontend.yaml. 
Создан frontend-pod-healthy.yaml - в результате под запускается - все ок.

</details>

<details>
<summary>Домашнее задание к лекции №3 (Механика запуска и взаимодействия контейнеров в Kubernetes)
</summary>

### Задание:
- Развернут кластер через kind
- Проверено создание на практике replica-set
- Проверена на практике работа с deployment
- Проверено на практике использование probes
- Развернут node-exporter через daemonset на всех нодах кластера, включая master

> Руководствуясь материалами лекции опишите произошедшую ситуацию, почему обновление ReplicaSet не повлекло обновление запущенных pod? 

ответ из лекции: потому что ReplicationController "НЕ проверяет соответствие запущенных Podов шаблону"

- Вспомогательные команды:

```
- получить поды по метке:
kubectl get pods -l app=frontend
- получить реплики:
kubectl get rs
- масштабирование реплики
kubectl scale replicaset frontend --replicas=3
- отследить развертывание реплики по метке:
kubectl apply -f frontend-replicaset.yaml | kubectl get pods -l app=frontend -w
- откат deployment-a:
kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -l app=paymentservice -w
```

### Задание со * №1:

> С использованием параметров maxSurge и maxUnavailable самостоятельно реализуйте два следующих сценария развертывания:

```
Аналог blue-green:
1. Развертывание трех новых pod
2. Удаление трех старых pod
Reverse Rolling Update:
1. Удаление одного старого pod
2. Создание одного нового pod
```

Созданы:
- paymentservice-deployment-bg.yaml
- paymentservice-deployment-reverse.yaml

### Задание со * №2:

> Найдите в интернете или напишите самостоятельно манифест node-exporter-daemonset.yaml для развертывания DaemonSet с Node Exporter

- в инете найдено здесь https://github.com/shevyf/prom_on_k8s_howto/blob/master/node-exporter-daemonset.yml
- актуализировано под текущую версию api и убраны некоторые навороты - см node-exporter-daemonset.yaml
- метрики собираются

### Задание со **:

>Найдите способ модернизировать свой DaemonSet таким образом, чтобы Node Exporter был развернут как на master, так и на worker нодах (конфигурацию самих нод изменять нельзя)

Пример можно найти в мануале: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

```
tolerations: # this toleration is to have the daemonset runnable on master nodes remove it if your masters can't run pods
  - key: node-role.kubernetes.io/master
    effect: NoSchedule
```

Параметр добавлен в node-exporter-daemonset.yaml

</details>

<details>
<summary>Домашнее задание к лекции №4 (Безопасность и управление доступом)
</summary>

### Задание:

- Изучено https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- сделаны задания:

#### Задание №1
- Создать Service Account bob, дать ему роль admin в рамках всего кластера
- Создать Service Account dave без доступа к кластеру

#### Задание №2
- Создать Namespace prometheus
- Создать Service Account carol в этом Namespace
- Дать всем Service Account в Namespace prometheus возможность делать get, list, watch в отношении Pods всего кластера

#### Задание №3
- Создать Namespace dev
- Создать Service Account jane в Namespace dev
- Дать jane роль admin в рамках Namespace dev
- Создать Service Account ken в Namespace dev
- Дать ken роль view в рамках Namespace dev

#### Шпаргалка:
- ClusterRole не принадлежит ни одному namespace
- ClusterRole - роль на весь кластер
- Role - роль только на неймспейс
- И с ролями надо внимательно - могут существовать одноименные роли на кластер и в неймспейсе
- FAQ по биндингу:

```
apiVersion: rbac.authorization.k8s.io/v1
# Этот биндинг дает ползователю "jane" роль pod-reader  в "default" неймспейсе
# Роль  "pod-reader" должна в этом неймспейсе существовать.
kind: RoleBinding
metadata:
  name: read-pods    # придумываем название биндингу
  namespace: default # создаем биндинг именно в default
subjects:            # кому даем права
                     # можно указать нескользо "subject"
- kind: User
  name: jane         # имя пользователя регистрозависимое
  apiGroup: rbac.authorization.k8s.io
roleRef:             # указываем одну роль которую дадим верхним пользователям или сервисаккаунтам
  kind: Role         # либо  Role, либо ClusterRole
  name: pod-reader   # должно быть имя существующей Role или ClusterRole
  apiGroup: rbac.authorization.k8s.io
```

</details>

<details>
<summary>Домашнее задание к лекции №5 (Сетевая подсистема Kubernetes)
</summary>

### Задание:

- ветка kubernets-network, рабочий каталог kubernetes-network
- добавлены и проверена работоспособность readinessProbe и livenessProbe в web-pod.yml
- создан deployment под наше приложение web, добавлена strategy, с параметрами maxSurge и maxUnavailable есть пример в прошлой Д/З в задании с *
- изучены service c clusterip, а также наложение его создания на iptables
- переключен kube-proxy на ipvs, установлен и настроен metallb, изучено применение service loadbalancer

```
Для получения прямого доступа с локальной машины до сервисов
узнаем ip minikube: minikube ip (192.168.49.2)
при создании указывали подсетку для ext адресов или смотрим ext адрес у нужного нам сервиса 
и дальше прописываем маршрут на локальной машине для доступа к сервисам ip route add 172.17.255.0/24 via 192.168.49.2

Альтернативно можно пробрасывать любые порты на сущности вида pod, deployment, service:
kubectl port-forward service/web-svc-lb 5555:5555
kubectl port-forward deployment/web 5555:8000
```

- Установлен Ingress-COntroller в виде nginx с использованием metallb (никогда так делать больше не буду, чет слишком сложно)
- Создан headless сервис и ingress для нашего сервиса (web-svc-headless.yaml, web-ingress.yaml )


### Самопроверка:

>Вопрос для самопроверки:
>1. Почему следующая конфигурация валидна, но не имеет смысла?

```
livenessProbe:
 exec:
 command:
 - 'sh'
 - '-c'
 - 'ps aux | grep my_web_server_process'
```

С точки зрения проверки работоспопобсноти сайта - наличие процесса веб-сервера не гарантирует работоспособность сайта.
Grep: the grep manual at the exit status section report: EXIT STATUS The exit status is 0 if selected lines are found, and 1 if not found.
Т.е. grep вернет 0 если процесс есть и не 1 если его нет.

>2. Бывают ли ситуации, когда она все-таки имеет смысл?

Бывают - например когда у нас какое-нибудь легаси приложение или когда в одном контейнере надо мониторить допустим два процесса(entrypoint отвечает за основное), а liveness смотрит допустим на второе и падение второго тоже критично.

### Задание со * №1:

> 1. Сделайте сервис LoadBalancer , который откроет доступ к CoreDNS снаружи кластера (позволит получать записи через внешний IP). Например, nslookup web.default.cluster.local 172.17.255.10 .
> 2. Поскольку DNS работает по TCP и UDP протоколам - учтите это в конфигурации. Оба протокола должны работать по одному и тому же IPадресу балансировщика.
> 3. Полученные манифесты положите в подкаталог ./coredns

Релизовано, см ./kubernetes-network/ext-coredns-svc.yaml

Правда есть момент - сам сервис позволяет резолвить как имена так и обратный просмотр, но что интересно, у меня имена резолвились только в виде ip_address.web.default.cluster.local, почему они так генерились непонятно.

Подсказка: см https://metallb.universe.tf/usage/#ip-address-sharing

### Задание со * №2: Ingress для Dashboard

> Добавьте доступ к kubernetes-dashboard через наш Ingress-прокси:
> 1. Cервис должен быть доступен через префикс /dashboard ).
> 2. Kubernetes Dashboard должен быть развернут из официального манифеста. Актуальная ссылка есть в .
> 3. Написанные вами манифесты положите в подкаталог ./dashboard

Установлен kubernetes-dashboard: https://github.com/kubernetes/dashboard

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.1.0/aio/deploy/recommended.yaml
```

Написан манифест: ./kubernetes-network/dashboard/dashboard-ingress.yaml Проверена работоспособность - все ок.

Для выковыривания токена можно использовать, подставив нужное имя пода: 

```
kubectl describe secret kubernetes-dashboard-token-t5qnb -n kubernetes-dashboard
```

### Задание со * №3: Canary для Ingress

> Перенаправление части трафика на выделенную группу подов должно происходить по HTTP-заголовку.
> Естественно, что вам понадобятся 1-2 "канареечных" пода. 
> Написанные манифесты положите в подкаталог ./canary

В каталоге ./kubernetes-network/canary созданы два типа файлов: deployment, service, ingress для main приложения и для canary.

Выполняем kubectl apply -f ./ в каталоге canary. В реузльтате получаем два приложения.

Основной интерес представляе web-ingress-canary.yaml - в нем задаются основные параметры канарейки:

```
    nginx.ingress.kubernetes.io/canary: "true"                  # включает режим канарейки для nginx для нашего правила
    nginx.ingress.kubernetes.io/canary-by-header: "canary"      # вариант №1: задаем header имя по которому будем проверять идти нам в канарейку или нет
    nginx.ingress.kubernetes.io/canary-by-header-value: "true"  #             задаем header значение
    #nginx.ingress.kubernetes.io/canary-weight: "50"            # вариант №2: задаем в % соотношении запросов между промом и канарейкой кого и ск-ко - не совместимо с вариантом №1
```

Проверить что canary работает, т.е. на него идет трафик для нашего приложения - можно на выводе index.html по host name - там будет имя пода: main для основного приложения, canary для канарейки.

Подробности по настройке можно найти тут: https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md#canary

### Доп инфо:

- на 20 версии кубера и докера заработало minikube ssh
- для запуска minikube: minikube start --vm-driver=docker  (причем по дефолту теперь оно запускается с vm в виде docker)
- Остановка: minikube stop
- Удаление кластера: minikube delete
- Установка дашборда: minikube dashboard
- Установка ингресса: minikube addons enable ingress
- Получение адреса minikube: minikube ip

</details>

<details>
<summary>Домашнее задание к лекции №6 (Хранение данных в Kubernetes: Volumes, Storages, Statefull-приложения)
</summary>

### Задание:

- Запущен кластен через kind
- Установлен MinIO (https://min.io) statefulset и service с использованием их манифестов:

```
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platformsnippets/master/Module-02/Kuberenetes-volumes/minio-statefulset.yaml
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platformsnippets/master/Module-02/Kuberenetes-volumes/minio-headless-service.yaml
```

- Манифесты сохранены в каталог: ./kubernetes-volumes
- Замучаны pv и pvc в разных способах создания и удаления, а также применения политик.
- Изучено как это хранится на диске с учетом stadard плагина kind и minikube
- Для запуска minio можно использовать: kubectl port-forward statefulsets/minio 9000:9000
- Опробовано использование самого minio
- На будущее есть некая то ли фича, то ли баг(по крайней мере офф документации k8s поведение явно противоречит, то это же плагин :) ):

>Интересный момент поймал на kind(да и minikube также ведет себя) с volume(домашка с minio): 
>если попытаться удалить PV(policy deleted) при существующем PVC, PV перейдет в terminated 
>как описано например тут https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storage-object-in-use-protection), 
>но когда удалить PVC после этого, PV удалится, но данные по факту останутся в каталоге докера(в volumes) несмотря на политику. 
>Если же удалить изначально PVC, то и PV и данные удалятся(считаем что сам ss minio во всех случаях уже убит).  

### Задание со *

>В конфигурации нашего StatefulSet данные указаны в открытом виде, что не безопасно.
> Поместите данные в и настройте конфигурацию на их использование.

Написан манифест для secret. Сами secret закодированы base64. В существующие манифест statefulset добавлено использование secret.

</details>


<details>
<summary>Домашнее задание к лекции №7 (Шаблонизация манифестов. Helm и его аналоги (Jsonnet, Kustomize))
</summary>

### Задание:

- В этом задании есть небольшая инструкция по google cloud platform.(само облако осталось с прошлого курса)
- Создан k8s в GCP
- Обновлен helm3 до актуальной версии.

```
т.к. часть версий helm чартов из старого репа, то обзовем:
старые: helm repo add stable-old https://charts.helm.sh/stable
новые:  helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

- Установлен nginx ingress через helm:

```
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable-old/nginx-ingress --wait \
 --namespace=nginx-ingress \
 --version=1.41.3
```

- Установлен cert manager через helm:

```
kubectl create namespace cert-manager
# ставим дополнения:
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.crds.yaml -n cert-manager
# ставим сам менеджер
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.1.0
# доп инфо:
https://habr.com/ru/company/flant/blog/496936/
```

- Установлены clusterissures для автоматической выдачи сертификатов используя let's encrypt - см kubernetes-templating/cert-manager. Один файл для прода(реальный сертификат), второй для stage(фейковый сертификат от LE)

```
Для использования потом в ингрессе этих issuer необходимо добавить аннотации и секрет - как на примере ниже(в секрет поместится полученный сертификат):
  tls:
    enabled: true
    secretName: "harbor.35.192.45.27.nip.io"
    #secretName: ""
  ingress:
    hosts:
      core: harbor.35.192.45.27.nip.io
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"
      cert-manager.io/cluster-issuer: "letsencrypt-production"
      cert-manager.io/acme-challenge-type: http01
```

- Установлен chartmuseum, на нем проверена корректная выдача сертификата - все ок.

```
kubectl create ns chartmuseum
helm upgrade --install chartmuseum stable-old/chartmuseum --wait \
 --namespace=chartmuseum \
 --version=2.13.2 \
 -f kubernetes-templating/chartmuseum/values.yaml

helm ls -n chartmuseum
```

### Задание со * №1: chartmuseum

>Научитесь работать с chartmuseum
>Опишите в PR последовательность действий, необходимых для добавления туда helm chart's и их установки с использованием chartmuseum как репозитория

Набор команд для использования chartmuseum ниже, вспомогательные ссылки: 
- https://chartmuseum.com/docs/#uploading-a-chart-package
- https://stackoverflow.com/questions/48577211/fail-to-upload-chart-to-chartmuseum

Тренироваться будем на чартах реддита с прошлых заданий:

```
# Для начала ставим плагин позволяющий пушить в какой-либо хелм репо:
helm plugin install https://github.com/chartmuseum/helm-push.git
# создаем пакет чарта (на выходе получим архив такой же как и при сборе зависимостей)
helm package .
# добавляем музей как репо для хелма:
helm repo add my-chartmuseum https://chartmuseum.34.68.65.51.nip.io
# пушим
helm push reddit/ my-chartmuseum
# обновляем:
helm repo update
# проверяем:
helm search repo reddit
NAME                 	CHART VERSION	APP VERSION	DESCRIPTION                   
my-chartmuseum/reddit	0.1.0        	           	OTUS sample reddit application
# и при необходимости можно поставить:
helm upgrade --install reddit my-chartmuseum/reddit
```

### Самостоятельное задание  №1: harbor

- Добавляем репо: helm repo add harbor https://helm.goharbor.io
- Создаем namespace: kubectl create ns harbor
- Устанавливаем, перед этим подготовив кастомные переменные:

```
helm upgrade --install harbor harbor/harbor --wait \
 --namespace=harbor \
 -f kubernetes-templating/harbor/values.yaml
```

- Реквизиты по умолчанию - admin/Harbor12345
- Был какой непонятный глюк что сервис не пускал себя с паролем при включенном tls, спустя неделю при тех же настройках все запустилось.

### Задание со * №2: Используем helmfile

> Опишите установку nginx-ingress, cert-manager и harbor в helmfile
> Приложите получившийся helmfile.yaml и другие файлы (при их наличии) в директорию kubernetes-templating/helmfile

- Написан файл: kubernetes-templating/helmfile/helmfile.yaml
- Для установки богатства из файла достаточно использовать helmfile sync в каталоге с файлом, единственно потом придется запустить повторно проставив корректный ext-ip ингресса(т.к. используется внешний сервис для генерации dns по ip).
- Есть момент: если существуют какие-то одноименные ресурсы оно выдаст ошибку и не поставится (например crd от cred-manager), но это справедливо и для любой установки любого чарта к существующим ресурсам в k8s.


### Задание: Создаем свой helm chart

- создан helm-chart для hipster-shop, запущен, работает(для gcp чтобы пробросить nodeport - надо зайти в gui найти сервис и там будет команда для forwarding).
- вынесен frontend в отдельный чарт - проверена работоспособность через  ingress - все ок.
- параметризован чарт frontend и добавлен в зависимости к основному чарту hipster-shop (не забываем, что из чарта HS фронтенд удален)
- Шпаргалка:

```
# создаем namespace для магазина:
kubectl create ns hipster-shop
# основная команда helm для разворачивания:
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
# обновить зависимости для чарта:
helm dep update kubernetes-templating/hipster-shop
# ставим чарт с переопределением входных значений (в данном случае они же и являются дефолтными :))
helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop -f kubernetes-templating/frontend/values.yaml
# удалить релиз:
helm delete frontend --namespace hipster-shop
```

### Задание со * №3: 

>Выберите сервисы, которые можно установить как зависимости, используя community chart's. Например, это может быть Redis.

- Вынесен redis из чарта hipster-shop и переведен на community чарт - в файле chart.yaml указана зависимость на внешний чарт с redis.
- добавлены доп переменные для redis(для упрощения запуска) и для сервиса cartservice(параметризован адрес redis) - см kubernetes-templating/hipster-shop/values.yaml
- удален deployment и service от redis из основного файла hipster-shop
- проверена работоспособность - все ок.

### Необязательное задание: Работа с helm-secrets

плагин переехал на новое место, то ставим плагин для секретов: 

```
helm plugin install https://github.com/jkroepke/helm-secrets
```

Инструкция по подготовке и шифрованию секретов:

```
генерим ключ:
gpg --full-generate-key
спросит пароль на закрытый и будет храиться где-то в домашнем каталоге - путь будет в выводе, как и имя ключа (много-много символов)
Для зашифровки:
sops -e -i --pgp 22CF5819B008C76172A3E90E9AD1DCB723941D38 secrets.yaml
Для расшифровки:
# helm secrets
helm secrets view secrets.yaml
# sops
sops -d secrets.yaml
и нужно будет ввести пароль закрытого ключа.
```

использование:

```
helm secrets upgrade --install frontend kubernetes-templating/frontend --namespace
hipster-shop \
 -f kubernetes-templating/frontend/values.yaml \
 -f kubernetes-templating/frontend/secrets.yaml
```

### Проверка: залить все чарты в harbor

- Мануал по подключению harbor как чарт репо: https://goharbor.io/docs/1.10/working-with-projects/working-with-images/managing-helm-charts/
- создан kubernetes-templating/repo.sh для добавления репо харбора.
- Далее как с музеем:

```
# добавляем репо (дублирую sh, чтобы не искать), кстати в отличие от музея - харбор хочет авторизацию и chartrepo обязательный путь после имени хоста
helm repo add templating --username=admin --password=Harbor12345 https://harbor.35.192.45.27.nip.io/chartrepo
helm push hipster-shop/ templating
helm push frontend/ templating
helm repo update
helm search repo hipster-shop
```

### Задание: kubecfg

- установлен kubecfg
- вынесены из основного чарта hipster-shop длва сервиса: paymentservice и shippingservice (deployment и service)
- создан services.jsonnet шаблон для генерации компонентов двух сервисов
- чем хорош jsonnet - им удобно генерить компоненты большого множества почти одинаковых сервисов, во всех остальных случаях это боль - достаточно посмотреть на файл.
- kubecfg/jsonnet очень сильно зависят от версии k8s и соответствующего ей версии библиотеки libsonnet - если не сходятся - можно легко нарваться на несовместимость версий сущностей k8s.
- библиотека libsonnet взята с какой-то ветки и положена локально, т.к. удаленно не скачивалось.
- для проверки указанных шаблонов: kubecfg show services.jsonnet
- для установки: kubecfg update services.jsonnet --namespace hipster-shop

### Задание со * №4:

>Выберите еще один микросервис из состава hipster-shop и попробуйте использовать другое решение на основе jsonnet, например Kapitan или qbec.

Не делал.

### Самостоятельное задание  №2: Kustomize

>Отпилите еще один (любой) микросервис из all-hipstershop.yaml.yaml и самостоятельно займитесь его kustomизацией.

- отпилен recommendationservice
- созданы yaml для kusomize: kubernetes-templating/kustomize base и override
- в override сделаны две кастомизации: dev и prod 
- dev - по сути является недостающим кусочком для текущей установки hipster-shop. Для установки: kubectl apply -k kubernetes-templating/kustomize/overrides/dev
- prod отличается namespace, label и префиксом
- для просмотра результатов кастомизированных yaml: kubectl kustomize overrides/dev
- доп инфо можно найти тут: https://kubectl.docs.kubernetes.io/references/kustomize/

</details>

<details>
<summary>Домашнее задание к лекции №8 (Custom Resource Definitions. Operators)
</summary>

### Задание:

- Написаны CustomResource и CustomResourceDefinition для mysql оператора
- В crd добавлено описание обязательных полей.
- Внимание, для 20 версии k8s формат crd в kubernetes-operators/deploy/crd.yaml уже deprecated и например validation в таком виде не работает. Рядом лежит crd16.yml, который работает корректно.
- Написана часть логики mysql оператора при помощи python KOPF (каталог kubernetes-operators/build) (кратко за логику отвечает py скрипт, который в рядом лежащие шаблоны подставляет значения от cr)
- Применены crd, запущен оператор/применены его манифесты из deploy каталога/ применер CR (в deploy/deploy-operator.yml указать нужный образ с оператором)
- Есть два варианта запуска, первый дебажный через явный локальный запуск оператора и второй честный с использованием докер образа с оператором.
- Для проверки в дебажном режиме:

```
# применяем crd
kubectl apply -f deploy/crd.yml
# запускаем оператор в каталоге build (для работы не забыть pip3 install kopf/kubernetes)
kopf run mysql-operator.py
# скрипт запустится и в консольке будут его логи
# далее применяем cr
kubectl apply -f deploy/cr.yml
```

- Для проверки по-честному:

```
# применяем crd
kubectl apply -f deploy/crd.yml
# проставляем нужный образ (isieiam/mysql-operator:1.0 или готовый из ДЗ) и применяем соответствующие манифесты:
kubectl apply -f deploy/service-account.yml
kubectl apply -f deploy/role.yml
kubectl apply -f deploy/role-binding.yml
kubectl apply -f deploy/deploy-operator.yml

# далее применяем cr
kubectl apply -f deploy/cr.yml
```
- При этом можем посмотреть на job-ы(видим что restore фелится с ошибкой, т.к. не может найти файлик бекапа, но так и задумано):

```
kubectl get jobs.batch
```

- Для проверки что все работает как надо:

```
#посмотреть что за объекты у нас создались:
kubectl get crd
kubectl get mysqls.otus.homework
kubectl describe mysqls.otus.homework mysql-instance

# для удобства помещаем имя пода в переменную окружения
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
# создаем табличку в нашей созданной оператором бд и закидываем туда две строчки данных
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test (id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
# проверяем содержимое:
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database

# проверяем удаление:
kubectl delete mysqls.otus.homework mysql-instance
# PV для mysql должен был удалиться, проверяем
kubectl get pv
# и проверяем что в момент удаления у нас выполнился бекап - джоб должен был отработать
kubectl get jobs.batch

# а теперь самое интересное, создаем инстанс еще раз:
kubectl apply -f deploy/cr.yml

#и смотрим job:
kubectl get jobs.batch
# мы должны увидеть что restore job запустился: он взял бд из бекапа и затолкал его в вновь созданный pv и мы можем проверить это:
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
```
- для проверки в выводе должно быть что-то такое:

```
:~/otus/IsieIam_platform/kubernetes-operators(kubernetes-operators)$ kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           3s         102s
restore-mysql-instance-job   1/1           3m31s      3m37s
:~/otus/IsieIam_platform/kubernetes-operators(kubernetes-operators)$ export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
:~/otus/IsieIam_platform/kubernetes-operators(kubernetes-operators)$ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

- внимание - для 20 версии k8s оператор не может удалить PV, чистый тест возможен например на 16:

```
minikube start --vm-driver=docker --kubernetes-version=v1.16.1
```
### Задание со * :

>Исправить контроллер, чтобы он писал в status subresource
>Добавить в контроллер логику обработки изменений CR

не делал - уровень моего кунг-фу в python пока недостаточен для этого :)


</details>

<details>
<summary>Домашнее задание к лекции №9 (Мониторинг компонентов кластера и приложений, работающих в нем)
</summary>

### Задание:

- Выбран 4 уровень :) (Can i play, daddy?), т.к. лучше в Wolfenstein на death incarnate, чем в k8s :D
- взят актуальный чарт уже kube-prometheus-stack: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- актуализированы values (kubernetes-monitoring/kube-prometheus-stack): включены ingress, настроены хосты для alertmanager, prometheus, grafana на mydomain.com
- ключевой момент, подсмотренный в лекции: необходимо поставить переменную serviceMonitorSelectorNilUsesHelmValues: false  иначе prom будет смотреть только те servicemonitor, у которых есть label поставленные от релиза helm.
- задеплоен чарт prom-a в кластер (в качестве k8s был взят minikube)

```
# шпаргалка по minikube
minikube start --vm-driver=docker
minikube addons enable ingress
minikube stop
minikube delete

# установка прома:
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -f kubernetes-monitoring/kube-prometheus-stack/values.yaml
```

- взят с первой ДЗ nginx, добавлен в конфиг параметр для его статуса, сбилжен образ isieiam/nginx-test:2.0
- взяты deployment, service, ingress с предыдущей ДЗ с canary для деплоя nginx из пункта выше.
- для доступа в локальный hosts прописаны имена хостов из ингресса и сервисы доступны по адресам:

```
http://prometheus.mydomain.com
http://alertmanager.mydomain.com
http://grafana.mydomain.com
сайт на nginx c логотипом otus: http://ingress.local
страница статуса nginx:         http://ingress.local/basic_status
```
- написаны deployment, service и service monitor для nginx prometheus exporter (доп инфо: https://github.com/nginxinc/nginx-prometheus-exporter)
- что делает exporter - у него параметром указан адрес сервиса nginx и он с nginx-вой страницы со статусом берет метрики и выдает прому в удобоваримом виде.
- для установки nginx и nginx-prometheus-exporter можно использовать kubectl apply -f . в каталоге kubernetes-monitoring/
- С репа nginx-prometheus-exporter взят дашборд для графаны: https://github.com/nginxinc/nginx-prometheus-exporter/tree/master/grafana
- Выглядит оно след образом:
![nginx exporter dashboard](./kubernetes-monitoring/screen/grafana_2021-01-07_18-42-39.png)

</details>

<details>
<summary>Домашнее задание к лекции №10 (Сервисы централизованного логирования для компонентов Kubernetes и приложений)
</summary>

### Задание:

- Создан кластер в gcp (1 нода в default, 3 в infra pool-ах)
- для трех нод в infra добавлены taints, можно либо в gui либо в консоли, на примере kind(запрет на shedule подов на эту ноду):

```
kubectl taint nodes kind-worker2 node-role=infra:NoSchedule
kubectl taint nodes kind-worker3 node-role=infra:NoSchedule
kubectl taint nodes kind-worker4 node-role=infra:NoSchedule
```

- установлен в ns microservices-demo hipster-shop
- подготовлены values для чарта EFK,с учетом требований по tolerations и установлен EFK в infra-pool
- донастроен fluentbit для отправки логов по адресу в  elastic с доп modify на удаление лишних полей
- установлен nginx ingress в кластер также в infra-pool 
- установлен prometheus-stack и elk exporter для сбора метрик elastic в проме.
- импортирован дашборд https://grafana.com/grafana/dashboards/4358 для elastic в графану
- проверена отработка мониторинга при отключении нод из infra pool
- настроено попадание логов nginx в elastic (достаточно в fluentbit прописать tolerations, чтобы он установился и на те ноды где живет nginx ingress)
- отформатированы логи nginx в json, в его values добавлены параметры, описанные по ссылка ниже:

```
https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-escape-json
https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-upstream
```

- для nginx добавлена настройка для serviceMonitor для отправки метрик в сторону prometheus
- созданы визуализации(по общему кол-ву и по кодам ответов) и дашборд для nginx в kibana(единственное отличие от методички в названии label:  kubernetes.labels.app_kubernetes_io/name : ingress-nginx)
- дашборд и визуализации экспортированы в kubernetes-logging/export.ndjson

![nginx ingress kibana dashboard](./kubernetes-logging/screen/kibana_ingress.png)

- установлен Loki и promtail через helm чарт, отдельно вынесены его values
- добавлен datasource loki в values для prometheus-stack в additional datasource у grafana(файл prometheus-operator.values.yaml добавлен в каталог, но по сути он от prometheus-stack лежащего рядом, а не от prom-operator)
- создан дашборд для nginx-ingress в grafana, содержащий логи nginx, ingress request volume, ingress success rate и срок истечения сертфииката
- дашборд выгружен в nginx-ingress.json, хотя дашборд https://github.com/kubernetes/ingress-nginx/blob/master/deploy/grafana/dashboards/nginx.json - достаточно интересный для использования :)

![nginx ingress grafana dashboard](./kubernetes-logging/screen/grafana_ingress.png)

### Задания со *:
- не делал

### Полезные команды:

```
#Устанавливаем nginx-ingress
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --wait --namespace=nginx-ingress -f ingress.values.yaml

# интересный параметр -o wide для поиска подов с учетом имен нод где они разместились
kubectl get pods -n microservices-demo -o wide

# ставим еластик
helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability -f elasticsearch.values.yaml
helm upgrade --install kibana elastic/kibana --namespace observability -f kibana.values.yaml
helm upgrade --install fluent-bit stable-old/fluent-bit --namespace observability -f fluentbit.values.yaml

# ставим пром и экспортер для еластика:
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -f kube-prometheus-stack/values.yaml --namespace observability
helm upgrade --install elasticsearch-exporter stable-old/elasticsearch-exporter --set es.uri=http://elasticsearch-master:9200 --set serviceMonitor.enabled=true --namespace=observability

# ставим локи
# старый чарт
helm upgrade --install loki loki/loki-stack --namespace observability -f loki.values.yaml
# новый чарт
helm upgrade --install loki grafana/loki --namespace=observability -f loki.values.yaml
```

</details>

<details>
<summary>Домашнее задание к лекции №15 (GitOps и инструменты поставки)
</summary>

### Задание:

- Зарегался на gitlab - проект с microservice-demo: https://gitlab.com/isieiam/microservices-demo
- helm чарты взяты готовые из демонстрационного репа: https://gitlab.com/express42/kubernetes-platform-demo/microservices-demo/
- Для создания кластера в gce:

```
# Установка с Istio(так не работает, текущий istio, который дает google не совместим с актуальной версией flagger - набор метрик istio разный):
gcloud beta container clusters create otus-cluster \
    --addons=Istio --istio-config=auth=MTLS_PERMISSIVE \
    --cluster-version=1.17.16-gke.1600 \
    --machine-type=n1-standard-2 \
    --num-nodes=4 \
    --zone=us-central1-c

# Установка без Istio
gcloud beta container clusters create otus-cluster \
    --cluster-version=1.17.16-gke.1600 \
    --machine-type=n1-standard-2 \
    --num-nodes=4 \
    --zone=us-central1-c

# для настройки локального kubectl
gcloud container clusters get-credentials otus-cluster --zone us-central1-c --project mytest-302917
где otus-cluster - имя кластера, project - проект созданный в gce
```

- Собраны докер образы всех микросервисов, для упрощения сборки и пуша можно воспользоваться простеньким скриптом: kubernetes-gitops/build-all.sh
- Установлен в кластер flux: https://docs.fluxcd.io/en/1.18.0/tutorials/get-started.html

```
# Добавляем repo helm-a
helm repo add fluxcd https://charts.fluxcd.io
helm repo update

# Ставим crd:
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
# Создаем namespace и ставим сам flux и helm-оператор для него (выполнять в каталоге kubernetes-gitops, где лежат кастомные values)
kubectl create namespace flux
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux

# ВНИМАНИЕ!!! - именно в values указано на какой репо смотрит flux для синхронизации

# Качаем себе консольную утилиту flux-а
wget https://github.com/fluxcd/flux/releases/download/1.21.1/fluxctl_linux_amd64

# получаем ssh ключик для flux-а и далее его кидаем в наш репо, который мониторится flux-ом
fluxctl identity --k8s-fwd-ns flux

# принудительная синхронизация репа и сервисов в k8s
fluxctl --k8s-fwd-ns flux sync

# Если посмотреть логи flux, то там будут видны все попытки синка, для примера создание namespace
ts=2021-02-07T17:57:24.106873143Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=639.97353ms err=null output="namespace/microservices-demo created"
```

- Проверено обновление сервиса через flux при появлении образа с новым тегом в docker-registry. Причем при текущих настройках работает не только инкремент версии образа, но и удаление тега из репа и откат на предыдущую версию.
Из интересного стоит обратить внимание на выбор тегов образов - задаются регуляркой, т.е. можно не все теги брать на автоматический синк.
- Принцип работы flux: он мониторит репо и каталог, указанные в настройках. При этом он сам поставит и namespace и смотрит за своими yaml, лежащими в releases и имеющих тип:

```
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
```
- Магия flux: при нахождении обновления(не важно в какую сторону), также и правит тег образа в самом репо где лежат его релизы.
- Когда flux находит изменение, то в логах будет следующее(смотрим на front, он единственный кто поменялся):

```
ts=2021-02-07T18:45:05.744203654Z caller=release.go:79 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="starting sync run"
ts=2021-02-07T18:45:06.241820999Z caller=release.go:353 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="running upgrade" action=upgrade
ts=2021-02-07T18:45:06.302887418Z caller=helm.go:69 component=helm version=v3 info="preparing upgrade for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.312008041Z caller=helm.go:69 component=helm version=v3 info="resetting values to the chart's original version" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.609795672Z caller=helm.go:69 component=helm version=v3 info="performing update for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.681725276Z caller=helm.go:69 component=helm version=v3 info="creating upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.701746662Z caller=helm.go:69 component=helm version=v3 info="checking 4 resources for changes" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.708246374Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Service \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.757950126Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend-hipster\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.763248675Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Gateway \"frontend-gateway\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.773521541Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for VirtualService \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:06.775903703Z caller=helm.go:69 component=helm version=v3 info="Deleting \"frontend\" in microservices-demo..." targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:07.104205333Z caller=helm.go:69 component=helm version=v3 info="updating status for upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-07T18:45:07.135411421Z caller=release.go:364 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="upgrade succeeded" revision=f7c4ad7b45349843881883009c276bad1e67cd64 phase=upgrade
```

- Написаны flux-релизы для всех сервисов демки (сервисы поднимутся с первого раза не все и это норм, зафейлится loadgenerator т.к. в текущих настройках он мониторит фронт с внешнего url и при условии, что  ingress или istio при этом нет).
- Отдельно установлен Istio: качаем с https://istio.io/latest/docs/setup/getting-started/ его архив и далее

```
# Ставим истио в кластер - namespace он создаст сам
istioctl install --set profile=default -y
# доставляем prometheus, именно в него istio будет заливать свои метрики, которые в том числе нужны для работы канарейки
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.9/samples/addons/prometheus.yaml -n istio-system
```
- У istio есть интересная настройка, которая явно задаётся при создании его через gce addon --istio-config=auth=MTLS_PERMISSIV - она отвечает за то какой вид трафик разрешает istio между подами.
Подробно об этом здесь: https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/
- Обратить внимание, что в yaml файле namespace - указан параметр   labels:  istio-injection: enabled - это нужно для того, чтобы подселить istio в каждый наш сервис.
Если посмотреть список подов - то видно будет что в каждом из них стало по 2 контейнера: один сам сервис, второй sidecar контейнер с istio(но автоматом подселение не произойдет, только при пересоздании подов).
- Istio может играть роль ингресса, для этого сервису(который мы хотим вставить наружу) нужно создать две доп сущности: gateway и virtualservice - см на примере frontend.
- Для того чтобы посмотреть ext адрес istio: kubectl get gateway -n microservices-demo
- Установлен Flagger( оператор Kubernetes, созданный для автоматизации canarydeployments):

```
# Добавляем репо
helm repo add flagger https://flagger.app
helm repo update

# ставим crd
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml

# ставим флаггер и вот тут самая магия: здесь указан прометей, который мы поставили вместе с istio - именно с него он будет брать метрики istio
helm upgrade --install flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090
```

- Canary релиз через flagger: создается отдельная сущность flagger - см yaml canary в каталоге frontend https://gitlab.com/isieiam/microservices-demo/-/blob/master/deploy/charts/frontend/templates/canary.yaml

```
# Более подробная инфо: https://docs.flagger.app/how-it-works#canary-custom-resource

# смотрим на canary
kubectl get canary -n microservices-demo
NAMESPACE NAME STATUS WEIGHT LASTTRANSITIONTIME
microservices-demo frontend Initializing 0 2020-02-09T22:23:00Z

# когда он создается, то основной сервис получает приписку primary
kubectl get pods -n microservices-demo -l app=frontend-primary
NAME READY STATUS RESTARTS AGE
frontend-primary-649f9c4579-jgv8h 2/2 Running 0 2m56s
```

- При установленном canary если обновить образ сервиса, то согласно конфигу канарейки часть запросов пойдут на нее и дальше согласно настройкам, доля канарейки будет повышаться и в конце концов она поменяется с текущим primary. 
Но для использования этого в проме - метрики должны быть достаточны для определния живости сервиса. В нашем примере используется просто анализ кодов ответов на запросы.

```
# Если выполнить:
kubectl describe canary frontend -n microservices-demo
# то увидим как менялась доля канарейки (в нашем случае по настройкам на canary сразу шло 50% трафика)
Events:
  Type     Reason  Age                From     Message
  ----     ------  ----               ----     -------
  Warning  Synced  23m                flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less then desired generation
  Normal   Synced  22m (x2 over 23m)  flagger  all the metrics providers are available!
  Normal   Synced  22m                flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  8m2s               flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  7m2s               flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  7m2s               flagger  Advance frontend.microservices-demo canary weight 50
  Normal   Synced  6m2s               flagger  Advance frontend.microservices-demo canary weight 100
  Normal   Synced  5m2s               flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  4m2s               flagger  Routing all traffic to primary
  Normal   Synced  3m2s               flagger  Promotion completed! Scaling down frontend.microservices-demo
```

- Есть один хитрый момент: для используемых настроек и метрик нужно чтобы был трафик на сервис - если его не будет - то нечего анализировать и канарейка просто умрет :)
- Откуда берутся метрики flagger-а: см https://flagger.app/intro/faq.html#metrics - где видно как он генерит свои стандартные метрики на основе метрик istio. При этом можно создавать и свои кастомные метрики.
- При этом - выше это метрики, которые используются для настройки canary, но если посмотреть prometheus у flagger есть и свои статусные метрики связанные с самими сущностями canary, например:
![flagger own metrics](./kubernetes-gitops/screens/flagger_canary.png)

Одна метрика: зеленая - это primary сервис, красная, это canary, видно что в какой-то момент, их доля изменилась сначала на 50%(такие настройки в конфиге canary), а потом и на 100%.

<details>
<summary>Полный вывод по canary</summary>

```
isie@isie-VirtualBox:~/otus/IsieIam_platform/kubernetes-gitops(kubernetes-gitops)$ kubectl get canaries -n microservices-demo
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2021-02-13T19:42:08Z

============================
isie@isie-VirtualBox:~/otus/IsieIam_platform/kubernetes-gitops(kubernetes-gitops)$ kubectl describe canary frontend -n microservices-demo
Name:         frontend
Namespace:    microservices-demo
Labels:       <none>
Annotations:  helm.fluxcd.io/antecedent: microservices-demo:helmrelease/frontend
API Version:  flagger.app/v1beta1
Kind:         Canary
Metadata:
  Creation Timestamp:  2021-02-13T19:21:49Z
  Generation:          1
  Resource Version:    18778
  Self Link:           /apis/flagger.app/v1beta1/namespaces/microservices-demo/canaries/frontend
  UID:                 8f026823-7775-4588-b920-cb058879cc45
Spec:
  Analysis:
    Interval:    1m
    Max Weight:  100
    Metrics:
      Interval:               1m
      Name:                   request-success-rate
      Threshold:              99
    Step Weight:              50
    Threshold:                2
  Progress Deadline Seconds:  60
  Service:
    Gateways:
      frontend-gateway
    Hosts:
      front.34.122.52.80.xip.io
    Port:  80
    Retries:
      Attempts:         3
      Per Try Timeout:  1s
      Retry On:         gateway-error,connect-failure,refused-stream
    Target Port:        8080
    Traffic Policy:
      Tls:
        Mode:  DISABLE
  Target Ref:
    API Version:  apps/v1
    Kind:         Deployment
    Name:         frontend
Status:
  Canary Weight:  0
  Conditions:
    Last Transition Time:  2021-02-13T19:42:08Z
    Last Update Time:      2021-02-13T19:42:08Z
    Message:               Canary analysis completed successfully, promotion finished.
    Reason:                Succeeded
    Status:                True
    Type:                  Promoted
  Failed Checks:           0
  Iterations:              0
  Last Applied Spec:       67794895c9
  Last Transition Time:    2021-02-13T19:42:08Z
  Phase:                   Succeeded
  Tracked Configs:
Events:
  Type     Reason  Age                From     Message
  ----     ------  ----               ----     -------
  Warning  Synced  23m                flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less then desired generation
  Normal   Synced  22m (x2 over 23m)  flagger  all the metrics providers are available!
  Normal   Synced  22m                flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  8m2s               flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  7m2s               flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  7m2s               flagger  Advance frontend.microservices-demo canary weight 50
  Normal   Synced  6m2s               flagger  Advance frontend.microservices-demo canary weight 100
  Normal   Synced  5m2s               flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  4m2s               flagger  Routing all traffic to primary
  Normal   Synced  3m2s               flagger  Promotion completed! Scaling down frontend.microservices-demo
```

</details>

### Задания со *:

- не делал, но часть для себя отметил (в частности пощупать argocd)

</details>

<details>
<summary>Домашнее задание к лекции №18 (Хранилище секретов для приложений. Vault)
</summary>

### Задание:

- Установлен кластер gcp

```
# установка кластер из 3 нод
gcloud beta container clusters create otus-cluster \
    --cluster-version=1.18.12-gke.1210 \
    --machine-type=n1-standard-2 \
    --num-nodes=3 \
    --zone=us-central1-c
# получение текущих кредов кластера
gcloud container clusters get-credentials otus-cluster --zone us-central1-c --project mytest-302917
```
#### Установка:
- Установлены consul и сам vault: consul является хранилищем для vault-а

```
# добавляем реп hashicorp
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
# install consul
https://github.com/hashicorp/consul-helm
helm install consul hashicorp/consul --set global.name=consul
# install vault
https://www.vaultproject.io/docs/platform/k8s/helm
# из каталога kubernetes-vault, где лежит правленный файл со значениями:
helm install -f vault-values.yaml vault hashicorp/vault 
```

- Вывод статуса vault после установки

```
$ helm status vault
NAME: vault
LAST DEPLOYED: Wed Mar  3 22:17:17 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```

- При этом если посмотреть статус подов vault, то они running но не ready, до тех пор пока не пройдет unseal. Что такое seal и unseal - фактически в режиме seal -vault запечатан, даже для себя - в текущем состоянии достать из него хранимые секреты невозможно. Чтобы начать с ним общаться - надо его распечатать(unseal):

```
isie@isie-VirtualBox:~/otus/IsieIam_platform/kubernetes-vault(kubernetes-vault)$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
consul-5wj5s                            1/1     Running   0          3m1s
consul-d987b                            1/1     Running   0          3m1s
consul-server-0                         1/1     Running   0          3m
consul-server-1                         1/1     Running   0          3m
consul-server-2                         1/1     Running   0          3m
consul-z2685                            1/1     Running   0          3m1s
vault-0                                 0/1     Running   0          85s
vault-1                                 0/1     Running   0          85s
vault-2                                 0/1     Running   0          85s
vault-agent-injector-79f4bb5689-p7rft   1/1     Running   0          85s
```

- Есть интересный момент если пытаться развернуть consul в kind или minicube - по каким то причинам id нод consul один и тот же и происходит постоянный перевыбор активной ноды. При этом у consul есть спец параметр чтобы не зависеть от id ноды, но оно не помогает. Если отключить ha режим - то все ок.
- Проведем инициализаю vault, можно через любой под vault. На выходе получает root токен для обращения к апи и ключ для unseal нод:

```
$ kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: J3/CqFThg6mu4yePeLltBQI7Qdo/yUR1ODoPHqti244=
Initial Root Token: s.NW5XyfagsqL1ongygqq6NOuv
...
```
- с точки зрения key-shares и key-treshhold: key-shares- ск-ко ключей для unseal сгенерится(т.е. фактически это ск-ко хешей мастер ключа будет создано), key-treshhold - ск-ко ключей(хешей мастер ключа) нужно для получения самого мастер ключа или разблокировки vault. Подробности тут: https://www.vaultproject.io/docs/commands/operator/init
- распечатаем каждую ноду vault, при этом в момент unseal как раз вводятся unseal ключи полученные нами на предыдущем шаге 

```
kubectl exec -it vault-0 -- vault operator unseal
kubectl exec -it vault-1 -- vault operator unseal
kubectl exec -it vault-2 -- vault operator unseal
```

- Далее посмотрим на статус после unseal, при этом видно что мастером является 0 нода, остальные в standby:

<details>

```
$ kubectl exec -it vault-0 -- vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.6.2
Storage Type    consul
Cluster Name    vault-cluster-df4597b8
Cluster ID      16489def-375e-96ed-9260-0dab8f4d7771
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active

$ kubectl exec -it vault-1 -- vault status
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.6.2
Storage Type           consul
Cluster Name           vault-cluster-df4597b8
Cluster ID             16489def-375e-96ed-9260-0dab8f4d7771
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.12.2.5:8200

$ kubectl exec -it vault-2 -- vault status
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.6.2
Storage Type           consul
Cluster Name           vault-cluster-df4597b8
Cluster ID             16489def-375e-96ed-9260-0dab8f4d7771
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.12.2.5:8200
```
</details>

- для общения с api залогинимся в vault:

```
$ kubectl exec -it vault-0 -- vault login
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.NW5XyfagsqL1ongygqq6NOuv
token_accessor       63EbW02gkrRZLazcCzCF2IBN
token_duration       ?
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

- запросим список автоизаций:

```
$ kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_cd28eefb    token based credentials
```

#### Работа с секретами:

- Заведем и проверим заведение секретов в vault

```
# включаем kv(key/value) секреты
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
# проверяем список
kubectl exec -it vault-0 -- vault secrets list --detailed
# зводим секреты
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
# читаем данные по пути:
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
# получаем значения kv секрета
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
# Отличия в последних командах можно посмотреть здесь:
https://www.vaultproject.io/docs/commands/read
https://www.vaultproject.io/docs/commands/kv/get
```

- При чтении секрета получим следующий вывод:

```
$ kubectl exec -it vault-0 -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
```

####  Дружба с k8s:

- Включим авторизацию черерз k8s(более подробно схему см на 37 странице и в видеозаписи на  1:53:40), добавим авторизацию в vault:

```
# само включение
kubectl exec -it vault-0 -- vault auth enable kubernetes
# вывод возможных авторизаций:
$ kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_624f1a50    n/a
token/         token         auth_token_cd28eefb         token based credentials
```

- Создадим ClusterRoleBinding - см файл kubernetes-vault/vault-auth-service-account.yml
- Создадим сам serviceaccount и применим crb:

```
# Create a service account, 'vault-auth'
$ kubectl create serviceaccount vault-auth
# Update the 'vault-auth' service account
$ kubectl apply --filename vault-auth-service-account.yml
```
- Подготовим переменные для записи в конфиг кубер авторизации

```
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
# альтернативный вариант несколько другой, последний sed - это стандартная регулярка для Removing ANSI color codes from text stream
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes control plane' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g' )
```

- Запишем конфиг в vault

```
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"
```

- Создадим файл политики - см kubernetes-vault/otus-policy.hcl
- создадим политку и роль в vault(внимание - в текущих реалиях закопировать что-то в под в корень нельзя - просто не хватит прав, необходимо выбрать каталог, в который есть запись):

```
kubectl cp otus-policy.hcl vault-0:./tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
```

- Проверим работу авторизации, Создадим под с привязанным сервис аккаунтом и установим туда curl и jq:
```
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image
alpine:3.7
apk add curl jq
```

- запишем переменные окружения находят в запущенном поде:

```
VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

- дальше получим токен:
```
# можно просто курлом и в выводе подсмотреть токен
curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
# или записать токен в переменную окружения:
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
```

- и попробуем прочитать секреты:

```
$ curl --header "X-Vault-Token:s.W6WJg00DOh42m1EqSy9XV4Qa" $VAULT_ADDR/v1/otus/otus-ro/config
/ # curl --header "X-Vault-Token:s.W6WJg00DOh42m1EqSy9XV4Qa" $VAULT_ADDR/v1/otus/otus-ro/config
{"request_id":"18a58679-a11a-04b3-bb2a-077e95ac7fc5","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}

$curl --header "X-Vault-Token:s.W6WJg00DOh42m1EqSy9XV4Qa" $VAULT_ADDR/v1/otus/otus-rw/config
/ # curl --header "X-Vault-Token:s.W6WJg00DOh42m1EqSy9XV4Qa" $VAULT_ADDR/v1/otus/otus-rw/config
{"request_id":"3f260432-fcd5-5f84-be74-9f730f273886","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"password":"asajkjkahs","username":"otus"},"wrap_info":null,"warnings":null,"auth":null}
```

- проверим запись:

```
curl -H "X-Vault-Token: s.W6WJg00DOh42m1EqSy9XV4Qa" -H "Content-Type: application/json" -X POST -d '{"bar":"baz"}' $VAULT_ADDR/v1/otus/otus-ro/config
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}

curl -H "X-Vault-Token: s.W6WJg00DOh42m1EqSy9XV4Qa" -H "Content-Type: application/json" -X POST -d '{"bar":"baz"}' $VAULT_ADDR/v1/otus/otus-rw/config
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
curl -H "X-Vault-Token: s.W6WJg00DOh42m1EqSy9XV4Qa" -H "Content-Type: application/json" -X POST -d '{"bar":"baz"}' $VAULT_ADDR/v1/otus/otus-rw/config1
all ok
```

- записать в ro мы не смогли т.к. только чтение, а записать в rw в config мы не смогли потому что в политике в файле выше - мы не указали возможность обновления секрета, т.е. это изменение существующего. При этом в config1 записать смогли - т.к. фактически это добавление нового, а это политика разрешает.
- для того чтобы иметь возможность обновлять существующие ключи необходимо поменять политику на:
```
# доп инфо здесь:
https://learn.hashicorp.com/tutorials/vault/policies
# а поменять надо на:
path "otus/otus-rw/*" {
capabilities = ["read", "create", "list", "update"]
```

#### Практический пример с nginx:

- Разберем практический пример использования кредов в подах кубера на примере nginx:
```
Авторизуемся через vault-agent и получим клиентский токен
Через consul-template достанем секрет и положим его в nginx
Итог - nginx получил секрет из волта, не зная ничего про волт
```

- скачаем набор примеров с git clone https://github.com/hashicorp/vault-guides.git и перейдем к нашему:  vault-guides/identity/vault-agent-k8s-demo
- скорректированные конфиги приложены в kubernetes-vault/configs-k8s. По файлам: по факту нам нужны только два: configmap.yaml и example-k8s-spec.yaml, т.к. crb мы создали уже выше.
- configmap - используется политика для vault с шаблоном файла html для nginx, в котором указаны переменные для получения кредов из vault-а. А в example* фактически разворачивание nginx и подцепление конфигмепа как volume в страничку nginx. Больше подробностей можно найти в kubernetes-vault/configs-k8s/README.md самого примера
- если зайти в под с nginx то можно в html странице найти уд:

```
$ kubectl exec -it vault-agent-example -- sh
# cd /usr/share/nginx/html
# ls
index.html
# cat index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```

- Либо если пробросить порт nginx наружу: kubectl port-forward pod/vault-agent-example 8080:80, получим следующее:

![nginx html](./kubernetes-vault/configs-k8s/vault01.png)

#### создадим CA на базе vault

- Включим pki секретс в vault:

```
kubectl exec -it vault-0 -- vault secrets enable pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal \
common_name="example.ru" ttl=87600h > CA_cert.crt
```
- Если что, для удаления можно воспользоваться:

```
curl \
    --header "X-Vault-Token: s.NW5XyfagsqL1ongygqq6NOuv" \
    --request DELETE \
    $VAULT_ADDR/v1/pki/root
```

- пропишем урлы для ca и отозванных сертификатов:

```
kubectl exec -it vault-0 -- vault write pki/config/urls \
issuing_certificates="http://vault:8200/v1/pki/ca" \
crl_distribution_points="http://vault:8200/v1/pki/crl"
```

- создадим промежуточный сертификат

```
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal \
common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

- пропишем промежуточный сертификат в vault

```
kubectl cp pki_intermediate.csr vault-0:/home/vault/
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate \
csr=@/home/vault/pki_intermediate.csr \
format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
kubectl cp intermediate.cert.pem vault-0:/home/vault/
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/home/vault/intermediate.cert.pem
```

- Создадим и отзовем новые сертификаты, cоздадим роль для выдачи сертификатов:

```
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru \
allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
```

- Создадим сертификат: kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h", вывод сертификата:

<details>

```
$ kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUSStASL0avna3F8Zu35flNBW/OT4wDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMTAzMDMyMTEwNDlaFw0yNjAz
MDIyMTExMTlaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMPfCvJzAhhN
IGAj2qJowyaWN4KYAK7AOFoqlOgupk9r2Z+5ViDomhwPo49oglwB4MMBMem2eeyX
0Zd5vB1RLd2C56N/Z3trJfPLbzAVapTscd0O4nGoFaugzJUZJ7iax7bhWGUqAWHr
BKRZouXtDkaEdarkgopTq0riic5RBoxFJSnWT09vCv8SfDXCnQK9q6KoUKAmGTnn
YBdI8qIodUWMF0weegDbjnrUeP4WGJ75dGts26AQHR08MNz6r408RumRN2+U/wSJ
coX4jga4yzlr5YFkTRVnFIwDgrGQ4+a7Sc608YYx/AF92pfaVeITn9leV2LJMhga
3caNVNjQ7Q8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUNN9t7HpZV5lQguM6cKP7pnGg3a4wHwYDVR0jBBgwFoAU
/Yot3eNJT2YlgCiryvIcNP9gnkMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
023qah1fKzF8JKvnJ5c7/GvSaWA+AIKDEUoYtqfjDEada0rKmLyaBNDfeP7nIKiS
wPKbJw2wrDDRkg+qiXIkKeqZg1sL/4fIOrAG1ArxWAjOKcWLivyTxtKDdUcm1kwV
drZdRM5mNZVG1Rbj01GhyhEXlw8BnNw0wmsR+cidUF4iQTpPef2Gro7c5mUfxfoq
srQdR/jUiGxHXIvOGxxXAcBClOKqQR0wrg6a1EjMwYj52lkcG3noWhfpbdeSeOsE
48W76S9vVcpPR7nqxNDA5TO7YmVXPEUsjnsfdBKy9QnUSN+EB/yhbsc8Kv3bN5SW
u4xv5PaIcODoG7z05C8imw==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUXukx9lvMESRRql/vu2lKxdfoibwwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIxMDMwMzIxMTYzMVoXDTIxMDMwNDIxMTcwMVowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC2
sI1ctS0z2PixOzqmNEXf5BV/fA3CQNjkbnVAcEHJXPlt4rFVOicbUzh1rXnlQI8U
4aHqBX0W/eSWF8MF7Q02a7cJenKycypPMZuONMU3fhg6zzZb4kaUnNvPi+lEqeUj
yfrnv/k5yraxTPQY8u4ymkrzy+FjIzOTCo5xEa1fl9ejdlZWykS53FAG4nZxDSaZ
NmZgC6wI0RDQbBQfLWoIXzjsqKvLDY78L70RIqxX7KYOoVWNGVcPWDPH/WXZ+ZWf
wuhhqoFou3chHnVuyUbnNqu4j+STo0X0XG2HKjyqWaNItakEkA3wxHEaRGSPzqwA
Nagvtsri1efzgcWFD56XAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUTmfJEcEQ1qC243sO
yeGRzd8Kc2swHwYDVR0jBBgwFoAUNN9t7HpZV5lQguM6cKP7pnGg3a4wHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAGmbLqnY
IFoS3MAxVET6NKw5j3cytLBjCQ59UvEcFChmwxzeWQfdMz2PFl1SM0jHglSiIcsS
ACZszojBErbi5wX7wtKBAz36Wz2dRbpCwpfVmWSmBXnQi3jOoxYxR/QKghHARhjO
VNXES4Ej5iv8uCqSts5BXEhw5WJBVcfjDYYlJ+NBFVzlfxIZdAcBNGwUKKY3a/U1
0co7b1c4Fw1W0gi3iDC/ZQkDOdHMWKqVaxHiB2mbRXx5+VUl62uRMR9qM1CAR7Vs
bO+Fb1ws3i/EtmFOA44GdzK1nLNPZQ23RBu7NQEpyclAlDt/N888vxLLZlPZjiaq
vK/V94mBRJQLyTw=
-----END CERTIFICATE-----
expiration          1614892621
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUSStASL0avna3F8Zu35flNBW/OT4wDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMTAzMDMyMTEwNDlaFw0yNjAz
MDIyMTExMTlaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMPfCvJzAhhN
IGAj2qJowyaWN4KYAK7AOFoqlOgupk9r2Z+5ViDomhwPo49oglwB4MMBMem2eeyX
0Zd5vB1RLd2C56N/Z3trJfPLbzAVapTscd0O4nGoFaugzJUZJ7iax7bhWGUqAWHr
BKRZouXtDkaEdarkgopTq0riic5RBoxFJSnWT09vCv8SfDXCnQK9q6KoUKAmGTnn
YBdI8qIodUWMF0weegDbjnrUeP4WGJ75dGts26AQHR08MNz6r408RumRN2+U/wSJ
coX4jga4yzlr5YFkTRVnFIwDgrGQ4+a7Sc608YYx/AF92pfaVeITn9leV2LJMhga
3caNVNjQ7Q8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUNN9t7HpZV5lQguM6cKP7pnGg3a4wHwYDVR0jBBgwFoAU
/Yot3eNJT2YlgCiryvIcNP9gnkMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
023qah1fKzF8JKvnJ5c7/GvSaWA+AIKDEUoYtqfjDEada0rKmLyaBNDfeP7nIKiS
wPKbJw2wrDDRkg+qiXIkKeqZg1sL/4fIOrAG1ArxWAjOKcWLivyTxtKDdUcm1kwV
drZdRM5mNZVG1Rbj01GhyhEXlw8BnNw0wmsR+cidUF4iQTpPef2Gro7c5mUfxfoq
srQdR/jUiGxHXIvOGxxXAcBClOKqQR0wrg6a1EjMwYj52lkcG3noWhfpbdeSeOsE
48W76S9vVcpPR7nqxNDA5TO7YmVXPEUsjnsfdBKy9QnUSN+EB/yhbsc8Kv3bN5SW
u4xv5PaIcODoG7z05C8imw==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAtrCNXLUtM9j4sTs6pjRF3+QVf3wNwkDY5G51QHBByVz5beKx
VTonG1M4da155UCPFOGh6gV9Fv3klhfDBe0NNmu3CXpysnMqTzGbjjTFN34YOs82
W+JGlJzbz4vpRKnlI8n657/5Ocq2sUz0GPLuMppK88vhYyMzkwqOcRGtX5fXo3ZW
VspEudxQBuJ2cQ0mmTZmYAusCNEQ0GwUHy1qCF847Kiryw2O/C+9ESKsV+ymDqFV
jRlXD1gzx/1l2fmVn8LoYaqBaLt3IR51bslG5zaruI/kk6NF9Fxthyo8qlmjSLWp
BJAN8MRxGkRkj86sADWoL7bK4tXn84HFhQ+elwIDAQABAoIBAQClEcGpEstVHacX
/LxxkKnSMvR5zE1iR9WyEVxAbS4EE84MS9iPeYv8VKWfLrAFROADrhvuqCbur1nr
hGzi3d4iXhF0rv8T3ptMEzbKt0O7cGPUP4aOX1YG0fSLA5AySpCQVeAvpnY6kb+h
VDb6lAZGEsPGpWFxgk0Hf3JVF/PfenrwZUGrktszFF3l9r0wXaiiqHL6FGnjnit8
n5BKqKbHd3B+gOcbtyAcZD6ZwyuTGEyKKGfQR7mKYjXF5VbmJ1SlyTmKjhT30jHy
LoiLexk9Cly9OZdms7wGKPY3YSmUYVvUaXeqoCtH/ZGPKfFhN3XR7ndQcn9WH3Z6
be7+n1sBAoGBAMR2C9d6m0m0Pn+HbdAIl/svi0o/78TwKTQ13KeuF/7MpgyOiKLF
emTSiz+3eLGztXdseWwdDL52Ui+y2/sLpUTjQVA1/QPm/EHcrLecr61gGET+cw3G
OdJzyQ3Z/4dHVzXwqPzIfkFjMa3POO8roM8X8sjnkiHvi5sRiFXhumIJAoGBAO4O
FLcXlNbjp9cGP7iRtKESBlJGZcJ4bAh6+IHFbtmg/yOyF5J6aVWn3B/XIbCrzrx9
0eymsiXVtFMttQp4kMr5G9j3jzIV4Q80ZQlzLq0jFSjJXzkF8fthJpWPC7dMsHWM
33PGGZb60wzV467kly3dhXGDT4vuPviXHOE7GaOfAoGAOyjtAfM6xeQQGekXSVj9
Ize68x3zvtMvJTi+/INxWFoZ+pgFTza2V5wLMKG4J5LdJ1wz6DmLN+N7dj+e/KcS
Gn9wkI3hZgZtmguwuw3k3Qmd5VDWJqS1jsktFw25Y+w4t9aDnLNnSZtsP1GybFsv
7ozgoF0TZUK0QHr0GiCCNrkCgYEA3Z1oNYcTffXT436ixZ2Hjcds8R0uUJuw3zgz
rwPxDVMvErkR7sBc3Wv2pgGuEH3xaVKsomYRRN2tER5lAwl4qiy8ewEEYvkxWulJ
AkIjevVFFoJZTom1W3N26xaPLqaLQ/PQdkQ+wGpjHfjlDIUsJHusZh97Z2Z1YxGy
xg8x8DsCgYEAjHeMKuIPXj2yCYYumvBMrhu5SrgJfvXeJ1UwWjb2VYMed9joKba9
PdCXG4c9bvxhA1S0CbCUVOhVVlFI+m1aOkm6k2sOTpUFre+SsW8EOTkiDkgI9fbm
3NSe6MJYiv136crWlyDAOakK12IDe1JlKUtavTVCaMncuI4vTl9/AFQ=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       5e:e9:31:f6:5b:cc:11:24:51:aa:5f:ef:bb:69:4a:c5:d7:e8:89:bc
```

</details>

- отзовем сертификат: 

```
$ kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="5e:e9:31:f6:5b:cc:11:24:51:aa:5f:ef:bb:69:4a:c5:d7:e8:89:bc"
Key                        Value
---                        -----
revocation_time            1614806282
revocation_time_rfc3339    2021-03-03T21:18:02.559895629Z
isie@isie-VirtualBox:~/otus/IsieIam_platform/kubernetes-vault(kubernetes-vault)$
```

- Все сертификаты добавлены в каталог kubernetes-vault 

### Задания с *:
- не делал

</details>

<details>
<summary>Домашнее задание к лекции №22 (CSI. Обзор подсистем хранения данных в Kubernetes)
</summary>

### Задание: установить CSI-драйвер и протестировать функционал снапшотов

 - Выбираем host path csi driver: https://github.com/kubernetes-csi/csi-driver-host-path, в частности пойдем по  инструкции по ссылке https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/docs/deploy-1.17-and-later.md
 - Проверять будем на minikube

```
# стандартная шпаргалка по m inikube
minikube start --vm-driver=docker
minikube addons enable ingress
minikube stop
minikube delete
```

 - Проверяем что у нас нет в кластере сущностей которые будет создавать драйвер:

```
kubectl get volumesnapshotclasses.snapshot.storage.k8s.io
kubectl get volumesnapshots.snapshot.storage.k8s.io
kubectl get volumesnapshotcontents.snapshot.storage.k8s.io
```

 - Далее прописываем переменную окружения и ставим crd:

```
# Change to the latest supported snapshotter version
SNAPSHOTTER_VERSION=v2.0.1
# Apply VolumeSnapshot CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create snapshot controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

 - Проводим установку самого csi driver (последняя рабочая для snapshot версия 1.4, остальные под snapshot контроллера фейлится при запуске :():

```
# Clone the repo
git clone https://github.com/kubernetes-csi/csi-driver-host-path
cd csi-driver-host-path
git checkout release-1.4
# Deploy
deploy/kubernetes-latest/deploy.sh
kubectl get pods
```

 - далее из каталога kubernetes-storage/hw применяем 01, 02, 03 yaml - storageclass, pvc и сам pod: на выходе получаем созданные sc, pvc, pod и в том числе и pv, причем видим что имя pv сгенерилось:

```
kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
storage-pvc   Bound    pvc-bc3e9f73-c813-4e72-a95d-430a98566a3d   1Gi        RWO            csi-hostpath-sc   6s
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
pvc-bc3e9f73-c813-4e72-a95d-430a98566a3d   1Gi        RWO            Delete           Bound    default/storage-pvc   csi-hostpath-sc            6s
```

 - заходим в подик и создаем какой-либо файлик в каталог /data - куда мы примонтировали volume

```
kubectl exec -it storage-pod -- sh
/ # echo "Hello world" > /data/hw.txt
/ # cat /data/hw.txt 
Hello world
/ # exit
```

 - проверим работоспособность snapshot: применим 04 yaml - он создает snapshot по имени pvc, на выходе получаем snapshot:

```
kubectl get volumesnapshot
NAME               AGE
storage-snapshot   10s
```

 - а далее удаляем наш pod и pvc(сначала pod), убежадаемся что все удалилось и применяем 05 yaml с восстановлением с нашего snapshot

```
kubectl apply -f 05-restore.yaml
persistentvolumeclaim/storage-pvc created
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
pvc-83115efc-4554-487d-bd8b-eefe4c1d7037   1Gi        RWO            Delete           Bound    default/storage-pvc   csi-hostpath-sc            4s
```

 - возвращаем наш pod, заходим в него и проверяем наличие нашего файлика:

```
kubectl exec -it storage-pod -- sh
/ # cd /data
/data # ls -la
total 12
drwxr-xr-x    2 root     root          4096 Mar 12 17:31 .
drwxr-xr-x    1 root     root          4096 Mar 12 17:32 ..
-rw-r--r--    1 root     root            12 Mar 12 17:26 hw.txt
/data # cat hw.txt 
Hello world
/data # 
```

 - из интересного, как хранится volume и snapshot на диске, смотрим в каталоге докера, при этом snap по факту равно tar с файликами и каталогами, которые мы насоздавали:

```
root@VirtualBox:/home/docker/volumes/minikube/_data/lib/csi-hostpath-data# ls
2480a555-8358-11eb-8954-0242ac110004.snap  d12236be-8358-11eb-8954-0242ac110004
```

</details>
